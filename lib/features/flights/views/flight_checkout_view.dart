import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:cheapest_go_mobile/features/flights/api/flights_api.dart';
import 'package:cheapest_go_mobile/features/flights/components/flight_chrome.dart';
import 'package:cheapest_go_mobile/features/flights/lib/countries.dart';
import 'package:cheapest_go_mobile/features/flights/lib/flight_search_query.dart';
import 'package:cheapest_go_mobile/features/flights/lib/flight_utils.dart';
import 'package:cheapest_go_mobile/features/flights/lib/passengers.dart';
import 'package:cheapest_go_mobile/features/flights/models/flight_fare.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/tips/tip_anchor.dart';
import 'package:cheapest_go_mobile/shared/tips/tip_overlay.dart';
import 'package:cheapest_go_mobile/shared/errors/api_error.dart';
import 'package:cheapest_go_mobile/shared/lib/env.dart';
import 'package:cheapest_go_mobile/shared/payments/payment_gateway.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_palette.dart';

enum _Step { details, payment, confirmed }

/// Booking a flight, as V2's checkout does it for one: Details → Payment → Verification. (#47)
///
/// **Details** asks for every traveller the fare was priced for, with V2's own checks — names
/// as on the passport, a birthday inside the passenger's age band on the day they fly, a gender,
/// and the passport's number, expiry and issuing country; the lead traveller's email and phone.
/// Continuing needs a signed-in traveller, then calls api-v2's `/flights/book` against the real
/// Duffel offer: it re-reads the fare, refuses one that has risen, and opens a Stripe
/// PaymentIntent for what the card will be held for.
///
/// **Payment** hands that intent to Stripe's own sheet. The card number is typed into Stripe's
/// form, never into this app, and on a `pk_test_` key Stripe accepts only its test cards. Once
/// the card is authorised, `/flights/confirm` places the airline order.
///
/// **Verification** is the airline's answer: the PNR, or — when the airline is still deciding —
/// a page that says so and never invites a second payment.
class FlightCheckoutView extends StatefulWidget {
  const FlightCheckoutView({
    required this.params,
    required this.isSignedIn,
    required this.onSignIn,
    this.api,
    this.gateway,
    this.now,
    super.key,
  });

  /// The link the results page opened: `offerId`, `totalAmount`, `currency`, `fareCurrency`,
  /// `origin`, `destination`, `departureDate`, `cabin`, `adults`, `children`, `infants`, `search`.
  final Map<String, String> params;

  /// Booking needs an account, as on the web. The app layer answers this; features may not
  /// read the auth store themselves.
  final bool Function() isSignedIn;

  /// Sends the traveller to sign in, to come back here afterwards.
  final VoidCallback onSignIn;
  final FlightsApi? api;

  /// Takes the card. Stripe's sheet unless a test replaces it.
  final PaymentGateway? gateway;
  final DateTime? now;

  @override
  State<FlightCheckoutView> createState() => _FlightCheckoutViewState();
}

class _FlightCheckoutViewState extends State<FlightCheckoutView> {
  _Step _step = _Step.details;
  FlightFare? _offer;
  bool _offerLoading = true;
  BookingHold? _held;
  bool _submitting = false;
  bool _tripOpen = false;
  final _scroll = ScrollController();
  late final List<PassengerInfo> _passengers = passengersFor(adults: _adults, children: _children, infants: _infants);
  String _phoneCode = '+63';
  Map<String, String> _errors = const {};

  /// The airline's yes, once the card is paid.
  FlightConfirmation? _confirmed;

  /// Paid, and the airline has not answered yet.
  ConfirmProcessing? _settling;

  FlightsApi get _api => widget.api ?? flightsApi;
  PaymentGateway get _gateway => widget.gateway ?? paymentGateway;
  Map<String, String> get _p => widget.params;

  String get _offerId => _p['offerId'] ?? '';
  int get _adults => int.tryParse(_p['adults'] ?? '') ?? 1;
  int get _children => int.tryParse(_p['children'] ?? '') ?? 0;
  int get _infants => int.tryParse(_p['infants'] ?? '') ?? 0;
  String get _currency => (_p['currency'] ?? 'USD').toUpperCase();

  /// What `totalAmount` is written in: the airline's currency.
  String get _linkCurrency => (_p['fareCurrency'] ?? _currency).toUpperCase();
  double get _totalAmount => double.tryParse(_p['totalAmount'] ?? '') ?? 0;
  String get _origin => _p['origin'] ?? '';
  String get _destination => _p['destination'] ?? '';
  String get _departureDate => _p['departureDate'] ?? '';
  String get _today => isoDate(widget.now ?? DateTime.now());

  /// The search this flight was picked from, run again — where a fare that has gone sends them.
  String get _fareGoneHref {
    final carried = _p['search'];
    Map<String, String> q;
    if (carried != null && carried.isNotEmpty) {
      q = Map.of(Uri.splitQueryString(carried));
    } else {
      if (_origin.isEmpty || _destination.isEmpty) return '/';
      q = {'origin': _origin, 'destination': _destination};
      if (_departureDate.isNotEmpty) q['depart'] = _departureDate;
      for (final key in ['adults', 'children', 'infants', 'cabin']) {
        final v = _p[key];
        if (v != null && v.isNotEmpty) q[key] = v;
      }
    }
    q[fareGoneParam] = '1';
    return Uri(path: '/flights/search', queryParameters: q).toString();
  }

  @override
  void initState() {
    super.initState();
    _loadOffer();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// The offer, read once and quoted in the currency on show. Never blocks anything: a slow or
  /// failed read leaves the page on the fare in its link. Except one answer — the airline no
  /// longer has it — and then nothing here can book it.
  Future<void> _loadOffer() async {
    if (_offerId.isEmpty) {
      setState(() => _offerLoading = false);
      return;
    }
    try {
      final offer = await _api.offer(_offerId, currency: _currency);
      if (!mounted) return;
      setState(() {
        _offer = offer;
        _offerLoading = false;
      });
    } on FareGone {
      if (mounted && _step == _Step.details) context.go(_fareGoneHref);
    } on ApiError {
      if (mounted) setState(() => _offerLoading = false);
    }
  }

  /// What a flight costs, from the server: the card's hold once there is one, the quote until.
  ({String currency, double fare, double serviceFee, double total})? get _price {
    final held = _held;
    if (held?.amount != null && held?.currency != null) {
      return (
        currency: held!.currency!,
        fare: held.fare ?? held.amount!,
        serviceFee: held.serviceFee,
        total: held.amount!,
      );
    }
    final q = _offer?.quote;
    return q == null ? null : (currency: q.currency, fare: q.fare, serviceFee: q.serviceFee, total: q.total);
  }

  bool get _quoting => _offerLoading && _held == null && (_price == null || _price!.currency != _currency);

  Future<void> _submitDetails() async {
    final errors = validatePassengers(_passengers);
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }
    if (!widget.isSignedIn()) {
      widget.onSignIn();
      return;
    }
    final t = AppLocalizations.of(context)!;
    setState(() {
      _errors = const {};
      _submitting = true;
    });
    try {
      // The fare the traveller was shown, in the airline's currency — what the server
      // compares it with before holding anything.
      final shownFare = _offer?.price.total ?? _totalAmount;
      final lead = _passengers.first;
      final hold = await _api.book(
        offerId: _offerId,
        displayCurrency: _currency,
        confirmedPrice: shownFare > 0 ? shownFare : null,
        email: lead.email.trim(),
        phone: lead.phone.trim(),
        phoneCode: _phoneCode,
        passengers: [for (final p in _passengers) p.toBooking(lead)],
      );
      if (!mounted) return;
      setState(() {
        _held = hold;
        _submitting = false;
      });
      _goTo(_Step.payment);
    } on ApiError catch (e) {
      if (!mounted) return;
      // Not busy while a dialog is up: the button behind it would still be spinning.
      setState(() => _submitting = false);
      if (e.code == 'DUPLICATE_BOOKING') {
        final body = e.body ?? const {};
        await _showDuplicate(
          route: body['route']?.toString() ?? _origin,
          date: body['departureDate']?.toString() ?? _departureDate,
        );
      } else if (e.code == 'OFFER_EXPIRED' || e.code == 'FARE_UNAVAILABLE') {
        context.go(_fareGoneHref);
      } else if (e.category == ErrorCategory.auth) {
        widget.onSignIn();
      } else {
        await _alert(t.checkout_failed_title, e.message.isNotEmpty ? e.message : 'Booking failed. Please try again.');
      }
    } finally {
      if (mounted && _submitting) setState(() => _submitting = false);
    }
  }

  /// A new step starts from its top, as V2 slides each step in — kept where it was, payment
  /// opened scrolled past its own heading.
  void _goTo(_Step step) {
    setState(() => _step = step);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  /// Stripe's sheet takes the card for the intent `/flights/book` opened; then the airline is
  /// asked. The card is authorised, not charged: api-v2 captures it only on the airline's yes.
  Future<void> _pay() async {
    final held = _held;
    if (held == null || _submitting) return;
    final t = AppLocalizations.of(context)!;
    final lead = _passengers.first;
    setState(() => _submitting = true);

    try {
      await _gateway.payFor(
        clientSecret: held.clientSecret,
        email: lead.email.trim(),
        name: '${lead.firstName.trim()} ${lead.lastName.trim()}'.trim(),
        phone: lead.phone.trim().isEmpty ? null : '$_phoneCode${lead.phone.trim()}',
      );
    } on PaymentCancelled {
      // Their own decision: nothing charged, nothing said, the page stays where it was.
      if (mounted) setState(() => _submitting = false);
      return;
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      await _alert(t.checkout_alert_paymentTitle, error.toString().replaceFirst('Exception: ', ''));
      return;
    }

    try {
      final done = await _api.confirm(paymentIntentId: held.paymentIntentId, sessionId: held.sessionId);
      if (!mounted) return;
      setState(() {
        _confirmed = done;
        _submitting = false;
      });
      _goTo(_Step.confirmed);
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      // The hold is gone after any of these: the payment step has nothing left to pay with.
      void backToDetails() {
        setState(() => _held = null);
        _goTo(_Step.details);
      }

      switch (readConfirmFailure(error)) {
        case ConfirmProcessing settling:
          // Paid and possibly ordered: shown as an outcome, never as "try again".
          setState(() => _settling = settling);
          _goTo(_Step.confirmed);
        case ConfirmPriceChanged(:final was, :final now, :final currency):
          backToDetails();
          await _alert(
            t.checkout_alert_fareChangedTitle,
            t.checkout_flight_priceChanged(checkoutMoney(was, currency), checkoutMoney(now, currency)),
          );
        case ConfirmOfferExpired():
          backToDetails();
          context.go(_fareGoneHref);
        case ConfirmRefused(:final message):
          backToDetails();
          await _alert(t.checkout_failed_title, message.isNotEmpty ? message : t.checkout_failed_released);
        case ConfirmError(:final message):
          await _alert(t.checkout_failed_title, message.isNotEmpty ? message : t.checkout_failed_unknown);
      }
    }
  }

  Future<void> _alert(String title, String message) => showDialog<void>(
    context: context,
    builder: (ctx) {
      final t = AppLocalizations.of(ctx)!;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(t.checkout_alert_close))],
      );
    },
  );

  Future<void> _showDuplicate({required String route, required String date}) => showDialog<void>(
    context: context,
    builder: (ctx) {
      final t = AppLocalizations.of(ctx)!;
      return AlertDialog(
        title: Text(t.checkout_flight_duplicateTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.checkout_flight_duplicateBody(route, date)),
            const SizedBox(height: 8),
            Text(t.checkout_flight_duplicateHint),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(t.checkout_flight_duplicateClose))],
      );
    },
  );

  void _back() {
    if (_step == _Step.confirmed) {
      // Paid: nothing behind this page can be done again.
      context.go('/trips');
    } else if (_step == _Step.payment) {
      _goTo(_Step.details);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final c = _Colors.of(context);
    final payment = _step == _Step.payment;
    if (_step == _Step.confirmed) return _verification(t, c);

    // Only on the payment step: a Tip about authorising a card has nothing to say while
    // somebody is still typing passenger names. See #62 and ADR-0006.
    return TipScope(
      tip: payment ? tipFor(t, TipAnchors.flightCheckout) : null,
      child: PopScope(
      canPop: !payment,
      onPopInvokedWithResult: (didPop, _) {
        // The Android back gesture does what the page's own back does: from payment, to details.
        if (!didPop && payment) _goTo(_Step.details);
      },
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  children: [
                    // ── Toolbar ──
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _back,
                        style: TextButton.styleFrom(foregroundColor: c.title, padding: EdgeInsets.zero),
                        icon: const Icon(LucideIcons.arrowLeft, size: 18),
                        label: Text(
                          payment ? t.checkout_backToBookingDetails : t.property_v2_goBack,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ── Steps: they say where you are before the heading says what to do ──
                    Center(child: _Steps(active: payment ? 1 : 0)),
                    const SizedBox(height: 32),
                    Text(
                      payment ? t.checkout_paymentDetailsTitle : t.checkout_completeYourBooking,
                      style: TextStyle(
                        fontSize: 28,
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: c.title,
                      ),
                    ),
                    if (!payment) ...[
                      const SizedBox(height: 10),
                      Text(t.checkout_flight_whosFlying, style: TextStyle(fontSize: 19, height: 1.25, color: c.text)),
                    ],
                    const SizedBox(height: 24),
                    // ── The trip, folded into a bar on a phone ──
                    _tripBar(t, c),
                    if (_tripOpen) ...[const SizedBox(height: 8), _summary(t, c)],
                    SizedBox(height: payment ? 26 : 30),
                    if (!payment) ..._details(t, c) else ..._payment(t, c),
                  ],
                ),
              ),
              // ── The button rides at the foot of the screen while the form scrolls ──
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [c.bg, c.bg, c.bg.withValues(alpha: 0)],
                    stops: const [0, 0.72, 1],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // What the Tip points at: the charge, and what authorising it means.
                    TipAnchor(
                      id: TipAnchors.flightCheckout,
                      child: GradientPill(
                      label: payment ? t.checkout_payNow(_payLabel) : t.checkout_continueToPayment,
                      busy: _submitting,
                      onTap: payment ? _pay : _submitDetails,
                      expand: true,
                      height: 52,
                      radius: 999,
                      fontSize: 16,
                    ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      // The pieces carry their own edges ("Terms ", " and "); trimmed, so the
                      // sentence has one space between words, as V2's JSX does.
                      '${[t.checkout_agreePrefix, t.footer_terms, t.legal_termsGate_checkboxConnector, t.footer_privacyMinimal].map((s) => s.trim()).join(' ')}.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: c.faint),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  // ── Step 3: the airline's answer ──

  Widget _verification(AppLocalizations t, _Colors c) {
    final done = _confirmed;
    final settling = _settling;
    final lead = _passengers.first;
    final price = _price;
    final title = done != null
        ? t.checkout_flight_receipt_allSet
        : (settling?.needsReview ?? false)
        ? t.checkout_flight_needsReview_title
        : t.checkout_settling_title;
    final body = done != null
        ? t.checkout_flight_receipt_confirmedToDestination(_destination)
        : (settling?.needsReview ?? false)
        ? t.checkout_flight_needsReview_description
        : t.checkout_flight_settling_description;
    final row = TextStyle(fontSize: 14, color: c.text);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/trips');
      },
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              const SizedBox(height: 12),
              const Center(child: _Steps(active: 2)),
              const SizedBox(height: 32),
              Icon(
                done != null ? LucideIcons.circleCheck : LucideIcons.clock,
                size: 44,
                color: done != null ? const Color(0xFF16A34A) : c.muted,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: c.title),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.45, color: c.soft),
              ),
              if (done == null) ...[
                const SizedBox(height: 8),
                Text(
                  t.checkout_settling_doNotPayAgain,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.title),
                ),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (done?.pnr != null) ...[
                      Text(
                        t.checkout_flight_receipt_airlinePnr.toUpperCase(),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.9, color: c.faint),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        done!.pnr!,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 2, color: c.title),
                      ),
                      Text(t.checkout_flight_receipt_pnrHint, style: TextStyle(fontSize: 12, color: c.muted)),
                      const SizedBox(height: 14),
                    ],
                    Text(
                      '$_origin → $_destination',
                      style: row.copyWith(fontWeight: FontWeight.w700, color: c.title),
                    ),
                    if (done != null && done.bookingId.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${t.checkout_success_bookingId}: ${done.bookingId}',
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                    ],
                    if (price != null) ...[
                      Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 12), color: c.cardLine),
                      Row(
                        children: [
                          Expanded(
                            child: Text(t.checkout_success_total, style: row.copyWith(fontWeight: FontWeight.w700)),
                          ),
                          Text(
                            checkoutMoney(price.total, price.currency),
                            style: row.copyWith(fontWeight: FontWeight.w700, color: c.title),
                          ),
                        ],
                      ),
                    ],
                    if (done != null && lead.email.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        t.checkout_flight_receipt_receiptSentTo(lead.email.trim()),
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GradientPill(
                label: t.checkout_success_viewMyTrips,
                onTap: () => context.go('/trips'),
                expand: true,
                height: 52,
                radius: 999,
                fontSize: 16,
              ),
              const SizedBox(height: 10),
              Text(
                t.checkout_flight_receipt_paymentProcessedSecurely,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: c.faint),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _payLabel {
    final held = _held;
    if (held?.amount != null && held?.currency != null) return checkoutMoney(held!.amount!, held.currency!);
    return '$_currency ${NumberFormat('#,##0', 'en_US').format(_totalAmount)}';
  }

  // ── Trip bar and summary ──

  Widget _tripBar(AppLocalizations t, _Colors c) {
    final price = _price;
    final total = price != null
        ? checkoutMoney(price.total, price.currency)
        : '$_linkCurrency ${NumberFormat('#,##0.##', 'en_US').format(_totalAmount)}';
    final day = parseIsoDate(_departureDate);
    final details = [
      if (day != null) DateFormat('MMM d', 'en_US').format(day),
      withCount(t.checkout_flight_receipt_passengersCount(_passengers.length), _passengers.length),
    ].join(' · ');
    return Semantics(
      button: true,
      expanded: _tripOpen,
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _tripOpen = !_tripOpen),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_origin → $_destination',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.title),
                      ),
                      const SizedBox(height: 2),
                      Text(details, style: TextStyle(fontSize: 13, color: c.muted)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _quoting
                    ? _Skeleton(width: 84, height: 16, color: c.cardLine)
                    : Text(
                        total,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.title),
                      ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _tripOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(LucideIcons.chevronDown, size: 18, color: c.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The trip summary: each direction's ends by airport and time, then the fare breakdown.
  Widget _summary(AppLocalizations t, _Colors c) {
    final offer = _offer;
    final slices = offer == null
        ? const <({int index, List<FlightSegment> segments})>[]
        : groupSegmentsBySlice(offer.segments);
    final price = _price;
    final row = TextStyle(fontSize: 13, color: c.text);
    Widget rule() => Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 12), color: c.cardLine);

    Widget end(String caption, SegmentEnd? e, String code) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(caption, style: TextStyle(fontSize: 12, color: c.muted)),
        const SizedBox(height: 2),
        Text(
          airportLabel(e, code),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.title),
        ),
        const SizedBox(height: 1),
        Text(formatDateTime(e?.time), style: row),
      ],
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$_origin → $_destination',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.title),
          ),
          if (slices.isEmpty && _departureDate.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              parseIsoDate(_departureDate) == null
                  ? _departureDate
                  : DateFormat('MMM d', 'en_US').format(parseIsoDate(_departureDate)!),
              style: row,
            ),
          ],
          if ((_p['cabin'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(_p['cabin']!, style: TextStyle(fontSize: 13, color: c.soft)),
          ],
          for (var i = 0; i < slices.length; i++) ...[
            const SizedBox(height: 14),
            if (slices.length > 1) ...[
              Text(
                (i == 0 ? t.checkout_flight_receipt_outbound : t.checkout_flight_receipt_return).toUpperCase(),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.9, color: c.faint),
              ),
              const SizedBox(height: 10),
            ],
            end(
              t.checkout_flight_receipt_departFrom,
              slices[i].segments.first.departure,
              slices[i].segments.first.origin,
            ),
            const SizedBox(height: 10),
            end(
              t.checkout_flight_receipt_arriveAt,
              slices[i].segments.last.arrival,
              slices[i].segments.last.destination,
            ),
          ],
          if (_offerLoading && slices.isEmpty) ...[
            const SizedBox(height: 14),
            for (var i = 0; i < 2; i++) ...[
              _Skeleton(width: 64, height: 10, color: c.cardLine),
              const SizedBox(height: 7),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.72,
                child: _Skeleton(height: 14, color: c.cardLine),
              ),
              const SizedBox(height: 7),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.54,
                child: _Skeleton(height: 12, color: c.cardLine),
              ),
              const SizedBox(height: 10),
            ],
          ],
          rule(),
          if (_quoting) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    withCount(t.checkout_flight_receipt_fareLine(_passengers.length), _passengers.length),
                    style: row,
                  ),
                ),
                _Skeleton(width: 84, height: 14, color: c.cardLine),
              ],
            ),
            rule(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.checkout_success_total,
                    style: row.copyWith(fontWeight: FontWeight.w700, color: c.title),
                  ),
                ),
                _Skeleton(width: 96, height: 16, color: c.cardLine),
              ],
            ),
          ] else if (price != null) ...[
            // One fare line: the fee is part of what the ticket costs, not an extra
            // the traveller is shown being added.
            Row(
              children: [
                Expanded(
                  child: Text(
                    withCount(t.checkout_flight_receipt_fareLine(_passengers.length), _passengers.length),
                    style: row,
                  ),
                ),
                Text(checkoutMoney(((price.fare + price.serviceFee) * 100).round() / 100, price.currency), style: row),
              ],
            ),
            rule(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.checkout_success_total,
                    style: row.copyWith(fontWeight: FontWeight.w700, color: c.title),
                  ),
                ),
                Text(
                  checkoutMoney(price.total, price.currency),
                  style: row.copyWith(fontWeight: FontWeight.w700, color: c.title),
                ),
              ],
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.checkout_success_total,
                    style: row.copyWith(fontWeight: FontWeight.w700, color: c.title),
                  ),
                ),
                Text(
                  '$_linkCurrency ${NumberFormat('#,##0.##', 'en_US').format(_totalAmount)}',
                  style: row.copyWith(fontWeight: FontWeight.w700, color: c.title),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── Step 1: who's flying ──

  List<Widget> _details(AppLocalizations t, _Colors c) {
    String? err(int i, String field) => _errors['$i.$field'];
    void edit(int i, String field) {
      if (_errors.containsKey('$i.$field')) setState(() => _errors = Map.of(_errors)..remove('$i.$field'));
    }

    final section = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.68, color: c.title);
    Widget group(String title) => Container(
      margin: const EdgeInsets.only(top: 28, bottom: 16),
      padding: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.hairline)),
      ),
      child: Text(
        title,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.title),
      ),
    );

    return [
      if (!widget.isSignedIn()) ...[_authBanner(t, c), const SizedBox(height: 24)],
      for (var i = 0; i < _passengers.length; i++)
        Builder(
          builder: (context) {
            final p = _passengers[i];
            final nth = _passengers.take(i + 1).where((q) => q.type == p.type).length;
            final heading = switch (p.type) {
              'CHD' => t.checkout_userDetails_childN(nth),
              'INF' => t.checkout_flight_infantN(nth),
              _ => t.checkout_flight_adultN(nth),
            };
            final birth = birthDateBounds(p.type, _departureDate, _today);
            final expiry = passportExpiryBounds(_departureDate, _today);
            return Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(heading.toUpperCase(), style: section),
                  const SizedBox(height: 6),
                  Text(t.checkout_flight_nameHint, style: TextStyle(fontSize: 13, color: c.muted)),
                  const SizedBox(height: 18),
                  _pair(
                    _TextField(
                      label: t.checkout_userDetails_firstName,
                      hint: t.checkout_example('John'),
                      value: p.firstName,
                      error: err(i, 'firstName'),
                      autofill: i == 0 ? AutofillHints.givenName : null,
                      onChanged: (v) {
                        p.firstName = v;
                        edit(i, 'firstName');
                      },
                    ),
                    _TextField(
                      label: t.checkout_userDetails_lastName,
                      hint: t.checkout_example('Doe'),
                      value: p.lastName,
                      error: err(i, 'lastName'),
                      autofill: i == 0 ? AutofillHints.familyName : null,
                      onChanged: (v) {
                        p.lastName = v;
                        edit(i, 'lastName');
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Only the birthdays the airline accepts for this passenger's type, on the day they fly.
                  _pair(
                    _DateField(
                      label: t.checkout_userDetails_dateOfBirth,
                      value: p.dateOfBirth,
                      bounds: birth,
                      startInYears: true,
                      error: err(i, 'dateOfBirth'),
                      onChanged: (v) => setState(() {
                        p.dateOfBirth = v;
                        edit(i, 'dateOfBirth');
                      }),
                    ),
                    _SelectField(
                      label: t.checkout_userDetails_gender,
                      placeholder: t.checkout_flight_genderPlaceholder,
                      value: p.gender,
                      error: err(i, 'gender'),
                      options: [('M', t.checkout_userDetails_genderMale), ('F', t.checkout_userDetails_genderFemale)],
                      onChanged: (v) => setState(() {
                        p.gender = v;
                        edit(i, 'gender');
                      }),
                    ),
                  ),

                  // Contact details once, on the lead traveller: where the e-ticket goes.
                  if (i == 0) ...[
                    group(t.checkout_flight_contactTitle),
                    _TextField(
                      label: t.checkout_userDetails_email,
                      hint: t.checkout_example('johndoe@gmail.com'),
                      value: p.email,
                      error: err(i, 'email'),
                      keyboard: TextInputType.emailAddress,
                      autofill: AutofillHints.email,
                      onChanged: (v) {
                        p.email = v;
                        edit(i, 'email');
                      },
                    ),
                    const SizedBox(height: 16),
                    _PhoneField(
                      label: t.checkout_userDetails_phoneNumber,
                      hint: t.checkout_example('912 345 6789'),
                      code: _phoneCode,
                      number: p.phone,
                      error: err(i, 'phone'),
                      onCode: (v) => setState(() => _phoneCode = v),
                      onNumber: (v) {
                        p.phone = v;
                        edit(i, 'phone');
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(t.checkout_flight_contactHint, style: TextStyle(fontSize: 13, height: 1.45, color: c.muted)),
                  ],

                  group(t.checkout_flight_passportTitle),
                  _pair(
                    _TextField(
                      label: t.checkout_userDetails_passportNumber,
                      hint: t.checkout_flight_passportPlaceholder,
                      value: p.passportNumber,
                      error: err(i, 'passportNumber'),
                      onChanged: (v) {
                        p.passportNumber = v;
                        edit(i, 'passportNumber');
                      },
                    ),
                    _DateField(
                      label: t.checkout_userDetails_passportExpiry,
                      value: p.passportExpiry,
                      bounds: expiry,
                      error: err(i, 'passportExpiry'),
                      onChanged: (v) => setState(() {
                        p.passportExpiry = v;
                        edit(i, 'passportExpiry');
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _CountryField(
                    label: t.checkout_userDetails_country,
                    placeholder: t.checkout_flight_countryPlaceholder,
                    noResults: t.checkout_flight_countryNoResults,
                    value: p.country,
                    error: err(i, 'country'),
                    onChanged: (v) => setState(() {
                      p.country = v;
                      edit(i, 'country');
                    }),
                  ),
                ],
              ),
            );
          },
        ),
    ];
  }

  /// Two short answers that belong together share a row from 360px; below that each takes its own.
  Widget _pair(Widget a, Widget b) => LayoutBuilder(
    builder: (context, box) => box.maxWidth >= 328
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: a),
              const SizedBox(width: 12),
              Expanded(child: b),
            ],
          )
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [a, const SizedBox(height: 16), b]),
  );

  Widget _authBanner(AppLocalizations t, _Colors c) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: c.summaryBg,
      border: Border.all(color: c.summaryBorder),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            t.checkout_signInToComplete,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.title),
          ),
        ),
        TextButton(
          onPressed: widget.onSignIn,
          child: Text(
            t.checkout_signInArrow,
            style: TextStyle(fontWeight: FontWeight.w600, color: c.link),
          ),
        ),
      ],
    ),
  );

  // ── Step 2: the card ──

  List<Widget> _payment(AppLocalizations t, _Colors c) => [
    Text(t.checkout_flight_cardHeld, style: TextStyle(fontSize: 13, height: 1.5, color: c.soft)),
    const SizedBox(height: 18),
    Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.creditCard, size: 18, color: c.title),
              const SizedBox(width: 8),
              Text(
                t.checkout_payment_card,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.title),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // The number is typed into Stripe's own form when Pay is tapped; this app never sees it.
          Text(t.checkout_securedByStripe, style: TextStyle(fontSize: 13, height: 1.45, color: c.soft)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(LucideIcons.lock, size: 12, color: c.muted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(t.checkout_payment_securedMessage, style: TextStyle(fontSize: 12, color: c.muted)),
              ),
            ],
          ),
        ],
      ),
    ),
    // A test key takes only Stripe's test cards — a real card is declined — so the build says
    // which card to use. Never shown on a live key.
    if (env.stripePublishableKey.startsWith('pk_test_')) ...[
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.dark ? TwPalette.amber950.withValues(alpha: 0.3) : TwPalette.amber50,
          border: Border.all(color: c.dark ? TwPalette.amber800 : TwPalette.amber200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Stripe test mode: no real money moves. Pay with the test card 4242 4242 4242 4242, '
          'any future expiry and any CVC. Real cards are declined.',
          style: TextStyle(fontSize: 12, height: 1.45, color: c.dark ? TwPalette.amber300 : TwPalette.amber800),
        ),
      ),
    ],
  ];
}

/// V2's `checkoutPalette`.
class _Colors {
  const _Colors({
    required this.dark,
    required this.bg,
    required this.title,
    required this.text,
    required this.soft,
    required this.muted,
    required this.faint,
    required this.hairline,
    required this.fieldBg,
    required this.fieldLine,
    required this.link,
    required this.summaryBg,
    required this.summaryBorder,
    required this.menuBg,
    required this.surface,
    required this.cardLine,
    required this.stepIdle,
    required this.stepLine,
  });

  final bool dark;
  final Color bg, title, text, soft, muted, faint, hairline, fieldBg, fieldLine, link;
  final Color summaryBg, summaryBorder, menuBg, surface, cardLine, stepIdle, stepLine;

  static _Colors of(BuildContext context) => Theme.of(context).brightness == Brightness.dark
      ? const _Colors(
          dark: true,
          bg: TwPalette.obsidian,
          title: Color(0xFFF8FAFC),
          text: Color(0xFFF1F5F9),
          soft: Color(0xFFCBD5E1),
          muted: Color(0xFF94A3B8),
          faint: Color(0xFF64748B),
          hairline: Color(0x1AFFFFFF),
          fieldBg: Color(0xFF1E293B),
          fieldLine: Color(0xFF334155),
          link: TwPalette.blue400,
          summaryBg: Color(0x0AFFFFFF),
          summaryBorder: Color(0x14FFFFFF),
          menuBg: Color(0xFF0F172A),
          surface: Color(0xFF0F172A),
          cardLine: Color(0x24FFFFFF),
          stepIdle: Color(0xFF1E293B),
          stepLine: Color(0xFF334155),
        )
      : const _Colors(
          dark: false,
          bg: TwPalette.alabaster,
          title: Color(0xFF0F172A),
          text: Color(0xFF1E293B),
          soft: Color(0xFF475569),
          muted: Color(0xFF64748B),
          faint: Color(0xFF94A3B8),
          hairline: Color(0xFFE2E8F0),
          fieldBg: Color(0xFFFFFFFF),
          fieldLine: Color(0xFFCBD5E1),
          link: Color(0xFF2563EB),
          summaryBg: Color(0x080F172A),
          summaryBorder: Color(0xFFE2E8F0),
          menuBg: Color(0xFFFFFFFF),
          surface: Color(0xFFF1F5F9),
          cardLine: Color(0xFFCBD5E1),
          stepIdle: Color(0xFFE2E8F0),
          stepLine: Color(0xFFCBD5E1),
        );

  static const danger = Color(0xFFE4685A);
}

/// 1 Details — 2 Payment — 3 Verification; the step in hand filled with the brand gradient.
class _Steps extends StatelessWidget {
  const _Steps({required this.active});

  final int active;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final c = _Colors.of(context);
    final labels = [t.checkout_steps_details, t.checkout_steps_payment, t.checkout_steps_verification];
    // The steps share the row rather than assume it: a longer translation or a larger text
    // size gives up connector first, then ellipsises a label, and never runs off the screen.
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0)
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 44, minWidth: 12),
                height: 1,
                margin: const EdgeInsets.only(top: 16),
                color: c.stepLine,
              ),
            ),
          Flexible(
            flex: 2,
            child: Semantics(
              label: labels[i],
              selected: i == active,
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: i == active ? FlightSkin.gradient : null,
                      color: i == active ? null : c.stepIdle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: i == active ? Colors.white : c.title,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: c.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

InputDecoration _decoration(_Colors c, {String? hint, String? error, Widget? suffix}) {
  OutlineInputBorder edge(Color color, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: color, width: w),
  );
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: c.fieldBg,
    hintText: hint,
    hintStyle: TextStyle(color: c.muted),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    suffixIcon: suffix,
    border: edge(error != null ? _Colors.danger : c.fieldLine),
    enabledBorder: edge(error != null ? _Colors.danger : c.fieldLine),
    focusedBorder: edge(error != null ? _Colors.danger : TwPalette.blue600, 1.5),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = _Colors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: text,
          children: const [
            TextSpan(
              text: ' *',
              style: TextStyle(color: _Colors.danger),
            ),
          ],
        ),
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.title),
      ),
    );
  }
}

class _ErrText extends StatelessWidget {
  const _ErrText(this.message);

  final String? message;

  @override
  Widget build(BuildContext context) => message == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(message!, style: const TextStyle(fontSize: 12, color: _Colors.danger)),
        );
}

class _TextField extends StatefulWidget {
  const _TextField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.error,
    this.keyboard,
    this.autofill,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? hint;
  final String? error;
  final TextInputType? keyboard;
  final String? autofill;

  @override
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _Colors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Label(widget.label),
        TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          keyboardType: widget.keyboard,
          autofillHints: widget.autofill == null ? null : [widget.autofill!],
          style: TextStyle(fontSize: 15, color: c.title),
          decoration: _decoration(c, hint: widget.hint, error: widget.error),
        ),
        _ErrText(widget.error),
      ],
    );
  }
}

/// A date, picked rather than typed, inside the airline's bounds. Shown "14 Oct 2026", as V2's
/// date field shows it in English.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.bounds,
    required this.onChanged,
    this.error,
    this.startInYears = false,
  });

  final String label;
  final String value;
  final DateBounds bounds;
  final ValueChanged<String> onChanged;
  final String? error;

  /// A birthday opens on the years, as V2's `openTo="year"`.
  final bool startInYears;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final c = _Colors.of(context);
    final picked = parseIsoDate(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Label(label),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            final min = parseIsoDate(bounds.min)!;
            final max = parseIsoDate(bounds.max)!;
            final initial = picked ?? parseIsoDate(bounds.anchor)!;
            final d = await showDatePicker(
              context: context,
              firstDate: min,
              lastDate: max,
              initialDate: initial.isBefore(min) ? min : (initial.isAfter(max) ? max : initial),
              initialDatePickerMode: startInYears ? DatePickerMode.year : DatePickerMode.day,
              helpText: label,
            );
            if (d != null) onChanged(isoDate(d));
          },
          child: InputDecorator(
            decoration: _decoration(
              c,
              error: error,
              suffix: Icon(LucideIcons.calendar, size: 16, color: c.muted),
            ),
            child: Text(
              picked == null ? t.landing_search_selectDate : DateFormat('d MMM y', 'en_GB').format(picked),
              style: TextStyle(fontSize: 15, color: picked == null ? c.muted : c.title),
            ),
          ),
        ),
        _ErrText(error),
      ],
    );
  }
}

class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.label,
    required this.placeholder,
    required this.value,
    required this.options,
    required this.onChanged,
    this.error,
  });

  final String label;
  final String placeholder;
  final String value;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final c = _Colors.of(context);
    final shown = options.where((o) => o.$1 == value).map((o) => o.$2).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Label(label),
        PopupMenuButton<String>(
          tooltip: label,
          onSelected: onChanged,
          position: PopupMenuPosition.under,
          itemBuilder: (_) => [for (final o in options) PopupMenuItem(value: o.$1, child: Text(o.$2))],
          child: InputDecorator(
            decoration: _decoration(
              c,
              error: error,
              suffix: Icon(LucideIcons.chevronDown, size: 16, color: c.muted),
            ),
            child: Text(shown ?? placeholder, style: TextStyle(fontSize: 15, color: shown == null ? c.muted : c.title)),
          ),
        ),
        _ErrText(error),
      ],
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.label,
    required this.hint,
    required this.code,
    required this.number,
    required this.onCode,
    required this.onNumber,
    this.error,
  });

  final String label;
  final String hint;
  final String code;
  final String number;
  final ValueChanged<String> onCode;
  final ValueChanged<String> onNumber;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final c = _Colors.of(context);
    final current = dialCodes.firstWhere((d) => d.dial == code, orElse: () => dialCodes.first);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Label(label),
        Row(
          children: [
            PopupMenuButton<String>(
              tooltip: label,
              onSelected: onCode,
              position: PopupMenuPosition.under,
              constraints: const BoxConstraints(maxHeight: 360),
              itemBuilder: (_) => [
                for (final d in dialCodes) PopupMenuItem(value: d.dial, child: Text('${d.flag}  ${d.name}  ${d.dial}')),
              ],
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: c.fieldBg,
                  border: Border.all(color: error != null ? _Colors.danger : c.fieldLine),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text('${current.flag} ${current.dial}', style: TextStyle(fontSize: 15, color: c.title)),
                    const SizedBox(width: 4),
                    Icon(LucideIcons.chevronDown, size: 14, color: c.muted),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BareField(value: number, hint: hint, error: error, onChanged: onNumber),
            ),
          ],
        ),
        _ErrText(error),
      ],
    );
  }
}

class _BareField extends StatefulWidget {
  const _BareField({required this.value, required this.hint, required this.onChanged, this.error});

  final String value;
  final String hint;
  final ValueChanged<String> onChanged;
  final String? error;

  @override
  State<_BareField> createState() => _BareFieldState();
}

class _BareFieldState extends State<_BareField> {
  late final _text = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _Colors.of(context);
    return TextField(
      controller: _text,
      onChanged: widget.onChanged,
      keyboardType: TextInputType.phone,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      style: TextStyle(fontSize: 15, color: c.title),
      decoration: _decoration(c, hint: widget.hint, error: widget.error),
    );
  }
}

/// The issuing country: typed to narrow, picked from V2's list, stored as its two-letter code.
class _CountryField extends StatelessWidget {
  const _CountryField({
    required this.label,
    required this.placeholder,
    required this.noResults,
    required this.value,
    required this.onChanged,
    this.error,
  });

  final String label;
  final String placeholder;
  final String noResults;
  final String value;
  final ValueChanged<String> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final c = _Colors.of(context);
    final shown = countryOptions.where((o) => o.code == value).map((o) => o.label).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Label(label),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            final picked = await showModalBottomSheet<String>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => _CountrySheet(title: label, placeholder: placeholder, noResults: noResults),
            );
            if (picked != null) onChanged(picked);
          },
          child: InputDecorator(
            decoration: _decoration(
              c,
              error: error,
              suffix: Icon(LucideIcons.chevronDown, size: 16, color: c.muted),
            ),
            child: Text(
              shown ?? placeholder,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 15, color: shown == null ? c.muted : c.title),
            ),
          ),
        ),
        _ErrText(error),
      ],
    );
  }
}

class _CountrySheet extends StatefulWidget {
  const _CountrySheet({required this.title, required this.placeholder, required this.noResults});

  final String title;
  final String placeholder;
  final String noResults;

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final c = _Colors.of(context);
    final q = _q.trim().toLowerCase();
    final options = q.isEmpty
        ? countryOptions
        : countryOptions.where((o) => o.label.toLowerCase().contains(q)).toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _q = v),
              decoration: _decoration(
                c,
                hint: widget.placeholder,
              ).copyWith(prefixIcon: Icon(LucideIcons.search, size: 16, color: c.muted)),
            ),
          ),
          Expanded(
            child: options.isEmpty
                ? Center(
                    child: Text(widget.noResults, style: TextStyle(color: c.muted)),
                  )
                : ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (_, i) => ListTile(
                      dense: true,
                      title: Text(options[i].label),
                      onTap: () => Navigator.of(context).pop(options[i].code),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({this.width, required this.height, required this.color});

  final double? width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
  );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cheapest_go_mobile/features/hotels/api/checkout_api.dart';
import 'package:cheapest_go_mobile/features/hotels/api/payment_gateway.dart';
import 'package:cheapest_go_mobile/features/hotels/components/stay_chrome.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/lib/env.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_palette.dart';
import 'package:cheapest_go_mobile/shared/stores/ui_store.dart';
import 'package:cheapest_go_mobile/shared/stores/trip_search_store.dart';
import 'package:cheapest_go_mobile/shared/utils/format.dart';
import 'package:cheapest_go_mobile/shared/utils/money.dart';

/// Paying for a stay, as V2's `/checkout` does it. See #41.
///
/// Three steps — details, payment, verification — and the bottom bar is absent throughout: a
/// form someone is paying through keeps the screen to itself, with its own way back and its
/// own action at the foot.
///
/// **The charged amount is the prebook price.** api-v2 locks a rate and answers with what the
/// supplier will honour, in the supplier's currency, and that figure goes to Stripe untouched.
/// The display currency converts prices everywhere else in this app; it stops here, because a
/// converted number is an estimate and a charge is not.
///
/// What this replaced: a form that waited 600 milliseconds, wrote a booking into a local
/// store and congratulated the guest. Nothing was reserved and no money moved.
class HotelCheckoutView extends StatefulWidget {
    const HotelCheckoutView({
        required this.hotelId,
        required this.roomId,
        this.catalog = travelCatalog,
        this.guest = _noGuest,
        this.onSignIn,
        super.key,
    });

    final String hotelId;

    /// The **Offer** chosen on the property page — what a prebook is made against.
    final String roomId;
    final TravelCatalog catalog;

    /// Who is booking. Supplied by the app layer; see [CheckoutGuest].
    final GuestLookup guest;

    /// Where "sign in" goes. Null leaves the prompt as a statement, which is what a screen
    /// mounted outside the router gets.
    final VoidCallback? onSignIn;

    @override
    State<HotelCheckoutView> createState() => _HotelCheckoutViewState();
}

/// Who is booking, as far as this screen needs to know.
///
/// Not read from the auth store: a feature may not reach into another feature, so the app
/// layer composes the two and hands the answer down. The checkout's interest in an account is
/// narrow — a name to prefill and whether api-v2 will accept a booking — and this is the whole
/// of it.
class CheckoutGuest {
    const CheckoutGuest({
        this.signedIn = false,
        this.email = '',
        this.firstName = '',
        this.lastName = '',
    });

    final bool signedIn;
    final String email;
    final String firstName;
    final String lastName;
}

/// Asked again whenever it matters, rather than captured once: someone can sign in partway
/// through this screen and come back to it.
typedef GuestLookup = CheckoutGuest Function();

CheckoutGuest _noGuest() => const CheckoutGuest();

enum _Step { details, payment, confirmed }

/// V2's checkout accent: `BRAND.primary`, which is Tailwind's blue-500 — so it comes from
/// the generated ramp rather than being typed out here again (ADR-0002).
const _accent = TwPalette.blue500;

/// V2's `GREEN`: the one colour on the confirmation that means "this happened". Not a
/// Tailwind stop and not a semantic role, so the generator has nothing to say about it — it
/// is V2's own constant, written out as the other four places in this app already write it.
const _green = Color(0xFF2FB67F);

class _HotelCheckoutViewState extends State<HotelCheckoutView> {
    final _form = GlobalKey<FormState>();
    final _firstName = TextEditingController();
    final _lastName = TextEditingController();
    final _email = TextEditingController();
    final _phone = TextEditingController();
    final _requests = TextEditingController();

    _Step _step = _Step.details;
    PrebookQuote? _quote;
    ConfirmOutcome? _outcome;

    /// What Stripe actually took, from the intent rather than from the quote.
    num? _charged;

    /// The booking row's id, once api-v2 has one. Null means no receipt to offer yet.
    String? _receiptId;
    bool _busy = false;
    String? _failure;

    @override
    void initState() {
        super.initState();
        final guest = widget.guest();
        if (guest.signedIn) {
            // Prefilled from the account, as V2 does: a guest who has signed in has already
            // told us this once.
            _email.text = guest.email;
            _firstName.text = guest.firstName;
            _lastName.text = guest.lastName;
        }
    }

    @override
    void dispose() {
        for (final controller in [_firstName, _lastName, _email, _phone, _requests]) {
            controller.dispose();
        }
        super.dispose();
    }

    Hotel? get _hotel => widget.catalog.hotel(widget.hotelId);

    /// The Offer being bought, found by the id the property page handed over.
    Offer? get _offer {
        for (final room in _hotel?.rooms ?? const <Room>[]) {
            for (final offer in room.buyableOffers) {
                if (offer.offerId == widget.roomId) return offer;
            }
        }
        return null;
    }

    Room? get _room {
        for (final room in _hotel?.rooms ?? const <Room>[]) {
            if (room.buyableOffers.any((o) => o.offerId == widget.roomId)) return room;
        }
        return null;
    }

    /// Locks the rate and moves to payment. The quote's own figure is what is shown from here
    /// on, including when the supplier has moved it.
    Future<void> _toPayment() async {
        if (!(_form.currentState?.validate() ?? false)) return;

        // api-v2 ties a booking to an account, so create-payment and confirm both require one.
        // Stopped here rather than at the moment someone taps Pay: a 401 after filling in a
        // form and reaching for a card is the worst place to learn you need to sign in.
        if (!widget.guest().signedIn) {
            widget.onSignIn?.call();
            return;
        }

        setState(() {
            _busy = true;
            _failure = null;
        });

        try {
            final offer = _offer;
            if (offer == null) throw StateError('That rate is no longer on sale.');

            // The currency the traveller is shopping in, not the supplier's: api-v2 converts
            // and prices in it, and the figure it answers with is the one that gets charged.
            final quote = await checkoutApi.prebook(
                offerId: offer.offerId,
                currency: uiSettingsStore.displayCurrency,
                roomName: _room?.name,
                adults: tripSearchStore.adults,
                expectedTotal: offer.stayTotal,
            );

            if (!mounted) return;
            setState(() {
                _quote = quote;
                _step = _Step.payment;
                _busy = false;
            });
        } catch (error) {
            if (!mounted) return;
            setState(() {
                _busy = false;
                _failure = _readable(error);
            });
        }
    }

    /// Takes the card, then books.
    ///
    /// The sheet is Stripe's own: it carries 3-D Secure, which is where a hand-rolled card
    /// form fails, and it never hands the number to this app.
    Future<void> _pay() async {
        final quote = _quote;
        final hotel = _hotel;
        if (quote == null || hotel == null) return;

        // Whether payments are configured is the gateway's own business, so it says so and
        // this reports what it said. The view asking about a Stripe key would also mean no
        // test could ever reach the half of this screen that matters.
        setState(() {
            _busy = true;
            _failure = null;
        });

        try {
            // Who is staying goes with this call as well as with confirm, so api-v2 can
            // finish the booking from Stripe's own event if this app dies in between.
            final intent = await checkoutApi.createPayment(
                quote: quote,
                firstName: _firstName.text.trim(),
                lastName: _lastName.text.trim(),
                email: _email.text.trim(),
                checkIn: tripSearchStore.checkIn,
                checkOut: tripSearchStore.checkOut,
                holderPhone: _phone.text.trim(),
                propertyName: hotel.name,
                propertyImage: hotel.photos.isEmpty ? null : hotel.photos.first,
                roomName: _room?.name,
                adults: tripSearchStore.adults,
                specialRequests: _requests.text.trim(),
            );

            await paymentGateway.payFor(
                clientSecret: intent.clientSecret,
                email: _email.text.trim(),
                name: '${_firstName.text.trim()} ${_lastName.text.trim()}'.trim(),
                phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            );

            // Paid. The booking is made from here — api-v2 reserves with the supplier and
            // sends the confirmation email with the receipt, so nothing on this side has to.
            final outcome = await checkoutApi.confirm(
                paymentIntentId: intent.paymentIntentId,
                quote: quote,
                firstName: _firstName.text.trim(),
                lastName: _lastName.text.trim(),
                email: _email.text.trim(),
                checkIn: tripSearchStore.checkIn,
                checkOut: tripSearchStore.checkOut,
                holderPhone: _phone.text.trim(),
                propertyName: hotel.name,
                propertyImage: hotel.photos.isEmpty ? null : hotel.photos.first,
                roomName: _room?.name,
                adults: tripSearchStore.adults,
                specialRequests: _requests.text.trim(),
            );

            if (outcome.isConfirmed) {
                // #41 wrote a local row here so Trips would show the stay. #42 made Trips read
                // the server, which now has this booking, so that row would only be a
                // duplicate nobody could tell apart from the real one. See ADR-0003.

                // The receipt is addressed by the row's own id, not by the reference, so it
                // has to be looked up. After the screen has already been given its answer:
                // a booking is confirmed whether or not a PDF can be fetched for it.
                checkoutApi.findBookingId(outcome.reference).then((id) {
                    if (mounted && id != null) setState(() => _receiptId = id);
                });
            }

            if (!mounted) return;
            setState(() {
                _charged = intent.chargedTotal;
                _outcome = outcome;
                // Pending and needs-review are shown on the same screen as a confirmation,
                // not as an error: the card has been charged and a room may be held, so the
                // one thing this must never do is invite a second attempt.
                _step = outcome.state == ConfirmState.failed ? _Step.payment : _Step.confirmed;
                _failure = outcome.state == ConfirmState.failed ? outcome.message : null;
                _busy = false;
            });
        } on PaymentCancelled {
            // Not a failure: the traveller shut the sheet, and the checkout stays where it
            // was with nothing charged and nothing said.
            if (mounted) setState(() => _busy = false);
        } catch (error) {
            if (!mounted) return;
            setState(() {
                _busy = false;
                _failure = _readable(error);
            });
        }
    }

    /// Opens the receipt api-v2 generates — the same PDF the confirmation email carries.
    ///
    /// Handed to the browser rather than fetched: possession of the booking's id is the
    /// authorisation (ADR-0027), so no session travels with it, and the download, the share
    /// sheet and the print dialog are all the phone's own and better than anything here.
    Future<void> _openReceipt() async {
        final id = _receiptId;
        if (id == null) return;
        final url = Uri.parse('${env.webApiUrl}${CheckoutApi.receiptUrl(id)}');
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
            if (mounted) setState(() => _failure = 'Could not open the receipt.');
        }
    }

    static String _readable(Object error) {
        final text = error.toString();
        return text.startsWith('Exception: ') ? text.substring(11) : text;
    }

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;
        final skin = StaySkin.of(context);
        final hotel = _hotel;

        return Scaffold(
            backgroundColor: skin.surface,
            appBar: AppBar(
                backgroundColor: skin.surface,
                surfaceTintColor: Colors.transparent,
                leading: _step == _Step.confirmed
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: _step == _Step.payment
                            ? t.checkout_backToBookingDetails
                            : t.common_goBack,
                        onPressed: () {
                            if (_step == _Step.payment) {
                                setState(() => _step = _Step.details);
                            } else if (context.canPop()) {
                                context.pop();
                            } else {
                                context.go('/');
                            }
                        },
                    ),
            ),
            body: hotel == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                        _Progress(step: _step, skin: skin, t: t),
                        const SizedBox(height: 24),
                        if (_failure != null) ...[
                            _Failure(message: _failure!, skin: skin),
                            const SizedBox(height: 16),
                        ],
                        switch (_step) {
                            _Step.details => _details(t, skin),
                            _Step.payment => _payment(t, skin, hotel),
                            _Step.confirmed => _confirmed(t, skin),
                        },
                    ],
                ),
            bottomNavigationBar: hotel == null || _step == _Step.confirmed
                ? null
                : _Action(
                    // api-v2's figure, fee included — nothing is billed above it. Without one
                    // there is no price to name and nothing to press: the notice above says
                    // why, and the bar does not offer to charge a number nobody has.
                    label: _step == _Step.details
                        ? t.checkout_continueToPayment
                        : _quote?.display == null
                            ? t.checkout_confirmingFinalPrice
                            : t.checkout_payNow(formatMoney(
                                _quote!.display!.chargedTotal,
                                _quote!.display!.currency,
                            )),
                    busy: _busy,
                    onPressed: _step == _Step.details
                        ? _toPayment
                        : _quote?.display == null
                            ? null
                            : _pay,
                ),
        );
    }

    Widget _details(AppLocalizations t, StaySkin skin) {
        return Form(
            key: _form,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(
                        t.checkout_completeYourBooking,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: skin.title),
                    ),
                    const SizedBox(height: 6),
                    Text(
                        t.checkout_whosCheckingInYou,
                        style: TextStyle(fontSize: 16, color: skin.muted),
                    ),
                    const SizedBox(height: 20),

                    // Signed out, the booking cannot be made: api-v2 ties it to an account.
                    // Said here rather than at the moment someone taps Pay.
                    if (!widget.guest().signedIn) ...[
                        _SignInBanner(t: t, skin: skin, onSignIn: widget.onSignIn),
                        const SizedBox(height: 20),
                    ],

                    Text(
                        t.checkout_userDetails_guest1,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: skin.muted,
                        ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                        children: [
                            Expanded(
                                child: _Field(
                                    controller: _firstName,
                                    label: t.checkout_userDetails_firstName,
                                    hint: 'e.g. John',
                                    required: true,
                                ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _Field(
                                    controller: _lastName,
                                    label: t.checkout_userDetails_lastName,
                                    hint: 'e.g. Doe',
                                    required: true,
                                ),
                            ),
                        ],
                    ),
                    const SizedBox(height: 14),
                    _Field(
                        controller: _email,
                        label: t.checkout_userDetails_email,
                        hint: 'e.g. johndoe@gmail.com',
                        required: true,
                        keyboard: TextInputType.emailAddress,
                        validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) return '${t.checkout_userDetails_email} *';
                            // The confirmation and the receipt both go here, so a typo costs
                            // the guest the only record they have of the booking.
                            return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)
                                ? null
                                : t.checkout_validation_emailInvalid;
                        },
                    ),
                    const SizedBox(height: 14),
                    _Field(
                        controller: _phone,
                        label: t.checkout_userDetails_phoneNumber,
                        hint: 'e.g. 912 345 6789',
                        keyboard: TextInputType.phone,
                    ),
                    const SizedBox(height: 22),
                    Text(
                        t.checkout_specialRequests_title.toUpperCase(),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: skin.muted,
                        ),
                    ),
                    const SizedBox(height: 10),
                    _Field(
                        controller: _requests,
                        label: '',
                        hint: 'The property will do its best to arrange it.',
                        maxLines: 3,
                    ),
                ],
            ),
        );
    }

    Widget _payment(AppLocalizations t, StaySkin skin, Hotel hotel) {
        final quote = _quote!;
        final price = quote.display;
        final change = quote.priceChange;

        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(
                    t.checkout_paymentDetailsTitle,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: skin.title),
                ),
                const SizedBox(height: 20),

                Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: skin.imageBg,
                        borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Row(
                                children: [
                                    Expanded(
                                        child: Text(
                                            hotel.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: skin.title,
                                            ),
                                        ),
                                    ),
                                    Text(
                                        // api-v2's figure in the traveller's currency. The
                                        // conversion is the server's; this screen never does
                                        // arithmetic on a price it is about to charge.
                                        price == null
                                            ? '—'
                                            : formatMoney(price.chargedTotal, price.currency),
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: skin.title,
                                        ),
                                    ),
                                ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                                '${formatDateRange(tripSearchStore.checkIn, tripSearchStore.checkOut)}'
                                ' · ${plural(tripSearchStore.nights, 'night')}'
                                '${_room == null ? '' : ' · ${_room!.name}'}',
                                style: TextStyle(fontSize: 12.5, color: skin.muted),
                            ),
                        ],
                    ),
                ),

                if (price == null) ...[
                    const SizedBox(height: 14),
                    _Notice(
                        icon: Icons.info_outline_rounded,
                        message: t.checkout_confirmingFinalPrice,
                        skin: skin,
                    ),
                ],

                if (change != null) ...[
                    const SizedBox(height: 14),
                    // Said out loud, never charged quietly: the supplier answered with a
                    // different figure from the one on the property page.
                    _Notice(
                        icon: change.up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        message: 'The price ${change.up ? 'went up' : 'came down'} from '
                            '${formatMoney(change.previous, change.currency)} to '
                            '${formatMoney(change.current, change.currency)}.',
                        skin: skin,
                    ),
                ],

                if (quote.substitutedRoomName != null) ...[
                    const SizedBox(height: 14),
                    // A different room from the one that was picked. Before paying, not after.
                    _Notice(
                        icon: Icons.swap_horiz_rounded,
                        message: 'The hotel offered ${quote.substitutedRoomName} instead of the '
                            'room you chose.',
                        skin: skin,
                    ),
                ],

                if (price != null && price.serviceFee > 0) ...[
                    const SizedBox(height: 14),
                    _Notice(
                        icon: Icons.receipt_long_rounded,
                        message: '${formatMoney(price.total, price.currency)} for the stay, plus '
                            '${formatMoney(price.serviceFee, price.currency)} service fee.',
                        skin: skin,
                    ),
                ],

                const SizedBox(height: 18),
                Text(
                    t.checkout_paymentInfo,
                    style: TextStyle(fontSize: 13, color: skin.muted),
                ),
            ],
        );
    }

    /// Booked, or paid for and not settled yet. Never an invitation to pay again.
    ///
    /// V2's confirmation page, element for element: the stamped badge, the reference in the
    /// accent, the receipt card with the stay in it, and the three actions. The one departure
    /// is the receipt — V2 prints the page, which a phone cannot do, so this opens the PDF
    /// api-v2 generates, the same document that was emailed.
    Widget _confirmed(AppLocalizations t, StaySkin skin) {
        final outcome = _outcome!;
        final booked = outcome.isConfirmed;
        final hotel = _hotel;
        final price = _quote?.display;
        final nights = tripSearchStore.nights;
        final paid = _charged ?? price?.chargedTotal;

        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                // ── The stamp ──
                Center(
                    child: Column(
                        children: [
                            Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                    // Not the brand blue: green is the one colour on this
                                    // screen that means "this happened", and V2 stamps it.
                                    color: booked ? _green : const Color(0xFFF59E0B),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 3),
                                ),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                        Icon(
                                            booked ? Icons.check_rounded : Icons.schedule_rounded,
                                            size: 24,
                                            color: Colors.white,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                            booked ? t.checkout_booked : 'PAID',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.72,
                                                color: Colors.white,
                                            ),
                                        ),
                                    ],
                                ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                                booked ? t.checkout_allSet : 'Your payment went through',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    color: skin.title,
                                ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                                booked
                                    // api-v2 sends it, receipt attached; this only says where.
                                    ? t.checkout_receiptSent(_email.text.trim())
                                    : '${outcome.message} Do not pay again — we will email '
                                        '${_email.text.trim()} as soon as the hotel confirms.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, height: 1.5, color: skin.muted),
                            ),
                        ],
                    ),
                ),
                const SizedBox(height: 28),

                // ── The reference ──
                if (outcome.reference.isNotEmpty) ...[
                    Text(
                        t.checkout_bookingReference,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: skin.muted,
                        ),
                    ),
                    const SizedBox(height: 4),
                    // Selectable: it is the one thing on this screen somebody needs to copy.
                    SelectableText(
                        outcome.reference,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.76,
                            color: _accent,
                        ),
                    ),
                    const SizedBox(height: 28),
                ],

                // ── The receipt card ──
                if (hotel != null)
                    Container(
                        decoration: BoxDecoration(
                            color: skin.imageBg,
                            border: Border.all(color: skin.hairline),
                            borderRadius: BorderRadius.circular(24),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                if (hotel.photos.isNotEmpty)
                                    SizedBox(
                                        height: 180,
                                        width: double.infinity,
                                        child: Image.network(
                                            hotel.photos.first,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => ColoredBox(
                                                color: skin.imageBg,
                                                child: Icon(
                                                    Icons.apartment_rounded,
                                                    size: 40,
                                                    color: skin.muted,
                                                ),
                                            ),
                                        ),
                                    ),
                                Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            Text(
                                                hotel.name,
                                                style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w800,
                                                    color: skin.title,
                                                ),
                                            ),
                                            if ((hotel.address ?? '').isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                        Icon(Icons.place_outlined, size: 12, color: skin.muted),
                                                        const SizedBox(width: 5),
                                                        Expanded(
                                                            child: Text(
                                                                hotel.address!,
                                                                style: TextStyle(fontSize: 12, color: skin.muted),
                                                            ),
                                                        ),
                                                    ],
                                                ),
                                            ],
                                            const SizedBox(height: 20),
                                            Divider(height: 1, color: skin.hairline),
                                            const SizedBox(height: 20),

                                            // The stay, two by two, as V2 lays it out.
                                            Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                    Expanded(
                                                        child: _Fact(
                                                            label: t.checkout_checkIn,
                                                            value: formatShortDate(tripSearchStore.checkIn),
                                                            note: formatDayDate(tripSearchStore.checkIn),
                                                            icon: Icons.calendar_today_rounded,
                                                            skin: skin,
                                                        ),
                                                    ),
                                                    const SizedBox(width: 24),
                                                    Expanded(
                                                        child: _Fact(
                                                            label: t.checkout_checkOut,
                                                            value: formatShortDate(tripSearchStore.checkOut),
                                                            note: formatDayDate(tripSearchStore.checkOut),
                                                            icon: Icons.calendar_today_rounded,
                                                            skin: skin,
                                                        ),
                                                    ),
                                                ],
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                    Expanded(
                                                        child: _Fact(
                                                            label: t.checkout_guestLabel,
                                                            value: '${_firstName.text.trim()} '
                                                                '${_lastName.text.trim()}'.trim(),
                                                            note: t.checkout_guestsCount(tripSearchStore.adults),
                                                            icon: Icons.person_outline_rounded,
                                                            skin: skin,
                                                        ),
                                                    ),
                                                    const SizedBox(width: 24),
                                                    Expanded(
                                                        child: _Fact(
                                                            label: t.checkout_success_room,
                                                            value: _room?.name ?? t.checkout_roomFallback,
                                                            note: t.checkout_nightsCount(nights),
                                                            skin: skin,
                                                        ),
                                                    ),
                                                ],
                                            ),
                                            const SizedBox(height: 20),
                                            Divider(height: 1, color: skin.hairline),
                                            const SizedBox(height: 20),

                                            // ── What was paid ──
                                            Text(
                                                t.checkout_priceBreakdown,
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.88,
                                                    color: skin.muted,
                                                ),
                                            ),
                                            const SizedBox(height: 12),
                                            if (price != null && nights > 0 && price.total > 0)
                                                _Line(
                                                    label: '${formatMoney(price.total / nights, price.currency)}'
                                                        ' × ${t.checkout_nightsCount(nights)}',
                                                    value: formatMoney(price.total, price.currency),
                                                    skin: skin,
                                                ),
                                            if (price != null && price.serviceFee > 0)
                                                _Line(
                                                    label: t.checkout_serviceFee,
                                                    value: formatMoney(price.serviceFee, price.currency),
                                                    skin: skin,
                                                ),
                                            const SizedBox(height: 12),
                                            Divider(height: 1, color: skin.hairline),
                                            const SizedBox(height: 12),
                                            Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                    Flexible(
                                                        child: Text(
                                                            t.checkout_totalPaid,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: TextStyle(
                                                                fontSize: 18,
                                                                fontWeight: FontWeight.w800,
                                                                color: skin.title,
                                                            ),
                                                        ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                        paid == null
                                                            ? '—'
                                                            : formatMoney(paid, price?.currency ?? 'USD'),
                                                        style: const TextStyle(
                                                            fontSize: 18,
                                                            fontWeight: FontWeight.w800,
                                                            color: _green,
                                                        ),
                                                    ),
                                                ],
                                            ),
                                        ],
                                    ),
                                ),
                            ],
                        ),
                    ),
                const SizedBox(height: 28),

                // ── The three actions ──
                // The receipt is offered only once api-v2 has a row to address it to; until
                // then the emailed copy is the one that exists, and a button that 404s is
                // worse than no button.
                if (_receiptId != null)
                    Center(
                        child: OutlinedButton.icon(
                            onPressed: _openReceipt,
                            icon: const Icon(Icons.download_rounded, size: 15),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: skin.title,
                                side: BorderSide(color: skin.hairline, width: 1.5),
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                shape: const StadiumBorder(),
                            ),
                            label: Text(
                                t.checkout_success_downloadReceipt,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                        ),
                    ),
                const SizedBox(height: 12),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Flexible(
                            child: _Pill(
                                label: t.checkout_planAnotherTrip,
                                filled: true,
                                skin: skin,
                                onPressed: () => context.go('/'),
                            ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                            child: _Pill(
                                label: t.checkout_success_viewMyTrips,
                                filled: false,
                                skin: skin,
                                onPressed: () => context.go('/trips'),
                            ),
                        ),
                    ],
                ),
            ],
        );
    }
}

/// One labelled fact in the receipt card: a small caps label, the fact, and a quieter note.
class _Fact extends StatelessWidget {
    const _Fact({
        required this.label,
        required this.value,
        required this.note,
        required this.skin,
        this.icon,
    });

    final String label;
    final String value;
    final String note;
    final StaySkin skin;
    final IconData? icon;

    @override
    Widget build(BuildContext context) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(
                    label,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: skin.muted,
                    ),
                ),
                const SizedBox(height: 4),
                Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        if (icon != null) ...[
                            Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(icon, size: 13, color: _accent),
                            ),
                            const SizedBox(width: 6),
                        ],
                        Expanded(
                            child: Text(
                                value,
                                style: TextStyle(
                                    fontSize: 14,
                                    height: 1.3,
                                    fontWeight: FontWeight.w700,
                                    color: skin.title,
                                ),
                            ),
                        ),
                    ],
                ),
                const SizedBox(height: 2),
                Text(note, style: TextStyle(fontSize: 11, color: skin.muted)),
            ],
        );
    }
}

/// A line of the price breakdown.
class _Line extends StatelessWidget {
    const _Line({required this.label, required this.value, required this.skin});

    final String label;
    final String value;
    final StaySkin skin;

    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    Flexible(child: Text(label, style: TextStyle(fontSize: 13, color: skin.muted))),
                    Text(
                        value,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: skin.muted),
                    ),
                ],
            ),
        );
    }
}

/// One of the two rounded actions under the receipt: the brand gradient, or an outline.
class _Pill extends StatelessWidget {
    const _Pill({
        required this.label,
        required this.filled,
        required this.skin,
        required this.onPressed,
    });

    final String label;
    final bool filled;
    final StaySkin skin;
    final VoidCallback onPressed;

    @override
    Widget build(BuildContext context) {
        final text = Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: filled ? skin.chipText : skin.title,
            ),
        );

        if (!filled) {
            return OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                    side: BorderSide(color: skin.hairline, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: const StadiumBorder(),
                ),
                child: text,
            );
        }

        return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(999),
                child: Ink(
                    decoration: BoxDecoration(
                        gradient: StaySkin.chipGradient,
                        borderRadius: BorderRadius.circular(999),
                    ),
                    child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                        alignment: Alignment.center,
                        child: text,
                    ),
                ),
            ),
        );
    }
}

/// Details, Payment, Verification — numbered, with the one in hand filled.
class _Progress extends StatelessWidget {
    const _Progress({required this.step, required this.skin, required this.t});

    final _Step step;
    final StaySkin skin;
    final AppLocalizations t;

    @override
    Widget build(BuildContext context) {
        final labels = [t.checkout_steps_details, t.checkout_steps_payment, t.checkout_steps_verification];

        return Row(
            children: [
                for (var i = 0; i < labels.length; i++) ...[
                    if (i > 0)
                        Expanded(
                            child: Container(
                                height: 1,
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                color: skin.hairline,
                            ),
                        ),
                    Column(
                        children: [
                            Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: i <= step.index ? const Color(0xFF2563EB) : null,
                                    shape: BoxShape.circle,
                                    border: i <= step.index ? null : Border.all(color: skin.hairline),
                                ),
                                child: Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: i <= step.index ? Colors.white : skin.muted,
                                    ),
                                ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                                labels[i],
                                style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: i == step.index ? FontWeight.w700 : FontWeight.w500,
                                    color: i == step.index ? skin.title : skin.muted,
                                ),
                            ),
                        ],
                    ),
                ],
            ],
        );
    }
}

class _Field extends StatelessWidget {
    const _Field({
        required this.controller,
        required this.label,
        required this.hint,
        this.required = false,
        this.keyboard,
        this.maxLines = 1,
        this.validator,
    });

    final TextEditingController controller;
    final String label;
    final String hint;
    final bool required;
    final TextInputType? keyboard;
    final int maxLines;
    final String? Function(String?)? validator;

    @override
    Widget build(BuildContext context) {
        final skin = StaySkin.of(context);

        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                if (label.isNotEmpty) ...[
                    Text.rich(
                        TextSpan(
                            text: label,
                            children: required
                                ? [const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFDC2626)))]
                                : null,
                        ),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: skin.title),
                    ),
                    const SizedBox(height: 6),
                ],
                TextFormField(
                    controller: controller,
                    keyboardType: keyboard,
                    maxLines: maxLines,
                    decoration: InputDecoration(hintText: hint),
                    validator: validator ??
                        (required
                            ? (value) => (value?.trim().isEmpty ?? true) ? '$label *' : null
                            : null),
                ),
            ],
        );
    }
}

class _SignInBanner extends StatelessWidget {
    const _SignInBanner({required this.t, required this.skin, required this.onSignIn});

    final AppLocalizations t;
    final StaySkin skin;

    /// Null outside the router: the prompt still explains why, with nowhere to go.
    final VoidCallback? onSignIn;

    @override
    Widget build(BuildContext context) {
        return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: skin.imageBg,
                borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
                children: [
                    Expanded(
                        child: Text(
                            t.checkout_signInToComplete,
                            style: TextStyle(fontSize: 13.5, color: skin.title),
                        ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(onPressed: onSignIn, child: Text(t.checkout_signInArrow)),
                ],
            ),
        );
    }
}

class _Notice extends StatelessWidget {
    const _Notice({required this.icon, required this.message, required this.skin});

    final IconData icon;
    final String message;
    final StaySkin skin;

    @override
    Widget build(BuildContext context) {
        return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Icon(icon, size: 16, color: skin.muted),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(message, style: TextStyle(fontSize: 12.5, height: 1.45, color: skin.muted)),
                ),
            ],
        );
    }
}

class _Failure extends StatelessWidget {
    const _Failure({required this.message, required this.skin});

    final String message;
    final StaySkin skin;

    @override
    Widget build(BuildContext context) {
        return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0x14DC2626),
                borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    const Icon(Icons.error_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(
                            message,
                            style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFFDC2626)),
                        ),
                    ),
                ],
            ),
        );
    }
}

/// The one action, pinned to the foot — and the only thing down there, since the bottom bar
/// is absent on this screen.
class _Action extends StatelessWidget {
    const _Action({required this.label, required this.busy, required this.onPressed});

    final String label;
    final bool busy;

    /// Null when there is nothing to press: a quote api-v2 could not price has no figure to
    /// charge, and offering to charge it anyway is the one thing this screen must not do.
    final VoidCallback? onPressed;

    @override
    Widget build(BuildContext context) {
        final skin = StaySkin.of(context);

        return Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 12 + MediaQuery.viewPaddingOf(context).bottom),
            child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                    onTap: busy ? null : onPressed,
                    borderRadius: BorderRadius.circular(999),
                    child: Ink(
                        decoration: BoxDecoration(
                            gradient: StaySkin.chipGradient,
                            borderRadius: BorderRadius.circular(999),
                        ),
                        child: Container(
                            height: 54,
                            alignment: Alignment.center,
                            child: busy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                                : Text(
                                    label,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: skin.chipText,
                                    ),
                                ),
                        ),
                    ),
                ),
            ),
        );
    }
}

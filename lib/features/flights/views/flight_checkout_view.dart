import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/components/app_buttons.dart';
import 'package:cheapest_go_mobile/shared/components/ui_kit.dart';
import 'package:cheapest_go_mobile/shared/flights/offline_route_maps.dart';
import 'package:cheapest_go_mobile/shared/stores/bookings_store.dart';
import 'package:cheapest_go_mobile/shared/stores/trip_search_store.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';
import 'package:cheapest_go_mobile/shared/utils/format.dart';

/// Taxes and fees on a flight, as a share of the fares (mock rate).
const double kFlightTaxRate = 0.08;

int flightTaxes(int fares) => (fares * kFlightTaxRate).round();

/// Review and pay for one flight. Payment is mocked: nothing is charged.
class FlightCheckoutView extends StatefulWidget {
  const FlightCheckoutView({
    required this.offerId,
    this.leadName,
    this.leadEmail,
    this.catalog = travelCatalog,
    this.initialHoldSeconds = 900,
    this.autoStartTimer,
    this.simulatedPriceShift,
    super.key,
  });

  /// Pre-fills the lead passenger from the signed-in traveler.
  final String? leadName;
  final String? leadEmail;

  final String offerId;
  final TravelCatalog catalog;

  /// Initial duration for fare hold countdown (default 15 minutes = 900s).
  final int initialHoldSeconds;

  /// Controls whether the periodic timer ticks automatically.
  /// Defaults to false in FLUTTER_TEST to avoid pumpAndSettle timeouts.
  final bool? autoStartTimer;

  /// Optional price shift to simulate supplier fare updates.
  final int? simulatedPriceShift;

  @override
  State<FlightCheckoutView> createState() => _FlightCheckoutViewState();
}

class _FlightCheckoutViewState extends State<FlightCheckoutView> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.leadName);
  late final _email = TextEditingController(text: widget.leadEmail);
  bool _paying = false;

  late int _secondsRemaining = widget.initialHoldSeconds;
  Timer? _countdownTimer;
  int? _activePriceShift;
  bool _priceShiftAccepted = false;

  bool get _isExpired => _secondsRemaining <= 0;

  @override
  void initState() {
    super.initState();
    _activePriceShift = widget.simulatedPriceShift;
    final isTest = Platform.environment.containsKey('FLUTTER_TEST');
    final shouldStart = widget.autoStartTimer ?? !isTest;
    if (shouldStart && _secondsRemaining > 0) {
      _startTimer();
    }
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    if (_secondsRemaining <= 0) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      }
    });
  }

  void _refreshLock() {
    setState(() {
      _secondsRemaining = widget.initialHoldSeconds > 0 ? widget.initialHoldSeconds : 900;
      _activePriceShift = null;
      _priceShiftAccepted = false;
    });
    _startTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fare lock refreshed for 15 minutes')),
    );
  }

  String _formatTimer(int seconds) {
    if (seconds <= 0) return '00:00';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _fillDemoTraveler() {
    setState(() {
      _name.text = 'Juan Dela Cruz';
      _email.text = 'juan.delacruz@cheapestgo.dev';
    });
  }

  Future<void> _promptPriceShift(int originalTotal, int shiftedTotal, int shift, FlightOffer f) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fare updated by carrier'),
        content: Text(
          'The airline updated the total fare for this flight from '
          '${formatPeso(originalTotal)} to ${formatPeso(shiftedTotal)} '
          '(${shift > 0 ? '+' : ''}${formatPeso(shift)}).\n\n'
          'Would you like to accept the new fare and proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Review details'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Accept new fare'),
          ),
        ],
      ),
    );

    if (accepted == true && mounted) {
      setState(() => _priceShiftAccepted = true);
      await _pay(f, shiftedTotal);
    }
  }

  Future<void> _pay(FlightOffer f, int total) async {
    if (_isExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Fare hold expired. Refreshing fare lock...'),
          action: SnackBarAction(label: 'Refresh', onPressed: _refreshLock),
        ),
      );
      _refreshLock();
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    setState(() => _paying = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final s = tripSearchStore;
    final booking = bookingsStore.addFlight(
      origin: f.origin,
      destination: f.destination,
      airline: f.airline,
      flightNo: f.flightNo,
      day: s.checkIn,
      departs: f.departs,
      arrives: f.arrives,
      stops: f.stopsLabel,
      passengers: s.adults,
      total: total,
      flight: BookedFlight(
        offerId: f.id,
        airline: f.airline,
        flightNo: f.flightNo,
        origin: f.origin,
        destination: f.destination,
        departureUtc: f.departureUtcOn(s.checkIn),
        durationMinutes: f.durationMinutes,
      ),
    );
    // Save the route's map for the flight now, while there's a connection.
    offlineRouteMaps.download(booking);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Flight booked · ref ${booking.reference}')),
    );
    context.go('/trips');
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final f = widget.catalog.flight(widget.offerId);
    if (f == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.flight_outlined,
          title: 'Nothing to check out',
          message: 'Pick a flight first.',
        ),
      );
    }
    final s = tripSearchStore;
    final fares = f.price * s.adults;
    final taxes = flightTaxes(fares);
    final baseTotal = fares + taxes;
    final shift = _activePriceShift ?? 0;
    final shiftedTotal = baseTotal + shift;
    final effectiveTotal = _priceShiftAccepted ? shiftedTotal : baseTotal;
    final stays = widget.catalog.hotelsNear(f.destination);

    return Scaffold(
      appBar: AppBar(title: const Text('Review and pay')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            // Fare hold timer banner
            AppCard(
              color: _isExpired ? c.surfaceMuted : c.surface,
              borderColor: _isExpired ? c.border : c.accent.withValues(alpha: 0.3),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _isExpired ? c.border : c.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _isExpired ? Icons.timer_off_outlined : Icons.timer_outlined,
                      color: _isExpired ? c.textMuted : c.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isExpired ? 'Fare hold expired' : 'Fare locked for ${_formatTimer(_secondsRemaining)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _isExpired ? c.textSecondary : c.accent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isExpired
                              ? 'Tap refresh to re-lock current fares'
                              : 'Flight seats and price guaranteed while you book',
                          style: TextStyle(fontSize: 11, color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (_isExpired)
                    TextButton(
                      onPressed: _refreshLock,
                      child: const Text('Refresh'),
                    ),
                ],
              ),
            ),
            if (_activePriceShift != null && _activePriceShift != 0 && !_priceShiftAccepted) ...[
              const SizedBox(height: 12),
              AppCard(
                color: c.surface,
                borderColor: Colors.amber.shade700,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Fare updated by carrier',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.amber.shade900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'The airline adjusted this fare. Original: ${formatPeso(baseTotal)} → New: ${formatPeso(shiftedTotal)} (${shift > 0 ? '+' : ''}${formatPeso(shift)}).',
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => context.pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            setState(() => _priceShiftAccepted = true);
                          },
                          child: const Text('Accept new fare'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            // Revalidation status card
            AppCard(
              color: c.surface,
              borderColor: c.success.withValues(alpha: 0.3),
              child: Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: c.success, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fare verified · Price guaranteed',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary),
                        ),
                        Text(
                          'Carrier schedule confirmed · Direct ticketing',
                          style: TextStyle(fontSize: 11, color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UiLabel('${formatDayDate(s.checkIn)} · one way'),
                  const SizedBox(height: 8),
                  Text('${f.origin} → ${f.destination}', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    '${formatClock(f.departs)} → ${formatClock(f.arrives)} · ${f.durationLabel} · ${f.stopsLabel}',
                    style: TextStyle(fontSize: 13, color: c.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text('${f.airline} ${f.flightNo}', style: TextStyle(fontSize: 12, color: c.textMuted)),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.luggage_outlined, size: 16, color: c.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(child: Text('Baggage: 7 kg carry-on + ${f.baggage}', style: TextStyle(fontSize: 12, color: c.textSecondary))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: c.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(child: Text('Policy: Non-refundable · Date changes with fee', style: TextStyle(fontSize: 12, color: c.textSecondary))),
                    ],
                  ),
                ],
              ),
            ),
            if (stays.isNotEmpty) ...[
              const SizedBox(height: 14),
              AppCard(
                color: c.secondary,
                borderColor: c.secondaryBorder,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.hotel_outlined, color: c.accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need a stay near ${f.destination}?',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.onSecondary),
                          ),
                          Text(
                            '${stays.first.name} · ${stays.first.distanceLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: c.onSecondary),
                          ),
                        ],
                      ),
                    ),
                    TextButton(onPressed: () => context.push('/airport/${f.destination}'), child: const Text('View')),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const UiLabel('Lead passenger'),
                TextButton.icon(
                  onPressed: _fillDemoTraveler,
                  icon: const Icon(Icons.person_outline, size: 14),
                  label: const Text('Fill demo', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Full name (as on passport)'),
              validator: (v) => (v ?? '').trim().length < 2 ? 'Enter the lead passenger’s name' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email for e-ticket'),
              validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim()) ? null : 'Enter a valid email',
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                children: [
                  _Line('${formatPeso(f.price)} × ${plural(s.adults, 'passenger')}', formatPeso(fares)),
                  const SizedBox(height: 8),
                  _Line('Taxes and fees', formatPeso(taxes)),
                  if (_priceShiftAccepted && shift != 0) ...[
                    const SizedBox(height: 8),
                    _Line('Supplier adjustment', '${shift > 0 ? '+' : ''}${formatPeso(shift)}'),
                  ],
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  _Line('Total', formatPeso(effectiveTotal), bold: true),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isExpired)
              AppGradientButton(
                onPressed: _refreshLock,
                icon: Icons.refresh_rounded,
                label: 'Fare hold expired · Tap to refresh',
              )
            else if (_activePriceShift != null && _activePriceShift != 0 && !_priceShiftAccepted)
              AppGradientButton(
                onPressed: () => _promptPriceShift(baseTotal, shiftedTotal, shift, f),
                icon: Icons.warning_amber_rounded,
                label: 'Review updated fare · ${formatPeso(shiftedTotal)}',
              )
            else
              AppGradientButton(
                onPressed: () => _pay(f, effectiveTotal),
                isLoading: _paying,
                icon: Icons.lock_outline_rounded,
                label: 'Pay ${formatPeso(effectiveTotal)}',
              ),
            const SizedBox(height: 6),
            Text(
              'Test mode: no card is charged in this build.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: c.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: bold ? 15 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: bold ? c.textPrimary : c.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: bold ? c.accent : c.textPrimary,
          ),
        ),
      ],
    );
  }
}

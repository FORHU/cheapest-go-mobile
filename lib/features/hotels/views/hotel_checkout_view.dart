import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/components/app_buttons.dart';
import 'package:cheapest_go_mobile/shared/components/ui_kit.dart';
import 'package:cheapest_go_mobile/shared/stores/bookings_store.dart';
import 'package:cheapest_go_mobile/shared/stores/trip_search_store.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';
import 'package:cheapest_go_mobile/shared/utils/format.dart';

/// Taxes and fees on a stay, as a share of the room total (mock rate).
const double kStayTaxRate = 0.12;

int stayTaxes(int subtotal) => (subtotal * kStayTaxRate).round();

/// Review and pay for a stay. Payment is mocked: nothing is charged.
class HotelCheckoutView extends StatefulWidget {
  const HotelCheckoutView({
    required this.hotelId,
    required this.roomId,
    this.leadName,
    this.leadEmail,
    this.catalog = travelCatalog,
    this.initialHoldSeconds = 900,
    this.autoStartTimer,
    this.simulatedPriceShift,
    super.key,
  });

  final String hotelId;
  final String roomId;

  /// Pre-fills the lead guest from the signed-in traveler.
  final String? leadName;
  final String? leadEmail;
  final TravelCatalog catalog;

  /// Initial duration for rate hold countdown (default 15 minutes = 900s).
  final int initialHoldSeconds;

  /// Controls whether the periodic timer ticks automatically.
  /// Defaults to false in FLUTTER_TEST to avoid pumpAndSettle timeouts,
  /// and true in regular execution.
  final bool? autoStartTimer;

  /// Optional price shift to simulate supplier rate updates (ADR-0020).
  final int? simulatedPriceShift;

  @override
  State<HotelCheckoutView> createState() => _HotelCheckoutViewState();
}

class _HotelCheckoutViewState extends State<HotelCheckoutView> {
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
      const SnackBar(content: Text('Rate lock refreshed for 15 minutes')),
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

  Future<void> _promptPriceShift(int originalTotal, int shiftedTotal, int shift, Hotel hotel, Room room) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rate changed by supplier'),
        content: Text(
          'The hotel updated the total price for your stay from '
          '${formatPeso(originalTotal)} to ${formatPeso(shiftedTotal)} '
          '(${shift > 0 ? '+' : ''}${formatPeso(shift)}).\n\n'
          'Would you like to accept the new price and proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Review details'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Accept new rate'),
          ),
        ],
      ),
    );

    if (accepted == true && mounted) {
      setState(() => _priceShiftAccepted = true);
      await _pay(hotel, room, shiftedTotal);
    }
  }

  Future<void> _pay(Hotel hotel, Room room, int total) async {
    if (_isExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Rate hold expired. Refreshing rate lock...'),
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
    final booking = bookingsStore.addStay(
      airportCode: hotel.airportCode,
      hotelName: hotel.name,
      roomName: room.name,
      checkIn: s.checkIn,
      checkOut: s.checkOut,
      adults: s.adults,
      total: total,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Booked ${hotel.name} · ref ${booking.reference}')),
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
    final hotel = widget.catalog.hotel(widget.hotelId);
    final room = hotel?.rooms.where((r) => r.id == widget.roomId).firstOrNull;
    if (hotel == null || room == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.hotel_outlined,
          title: 'Nothing to check out',
          message: 'Pick a hotel and room first.',
        ),
      );
    }
    final s = tripSearchStore;
    final subtotal = room.nightlyRate * s.nights;
    final taxes = stayTaxes(subtotal);
    final baseTotal = subtotal + taxes;
    final shift = _activePriceShift ?? 0;
    final shiftedTotal = baseTotal + shift;
    final effectiveTotal = _priceShiftAccepted ? shiftedTotal : baseTotal;
    final course = widget.catalog.coursesNear(hotel.airportCode).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Review and pay')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            // Rate hold timer banner
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
                          _isExpired ? 'Rate hold expired' : 'Rate locked for ${_formatTimer(_secondsRemaining)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _isExpired ? c.textSecondary : c.accent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isExpired
                              ? 'Tap refresh to re-lock current rates'
                              : 'Price and room guaranteed while you finish checkout',
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
                            'Rate updated by supplier',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.amber.shade900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'The hotel adjusted this rate. Original: ${formatPeso(baseTotal)} → New: ${formatPeso(shiftedTotal)} (${shift > 0 ? '+' : ''}${formatPeso(shift)}).',
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
                          child: const Text('Accept new rate'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            AppCard(
              child: Row(
                children: [
                  PhotoPlaceholder(image: hotel.cover, label: hotel.name, width: 64, height: 64, radius: 10),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hotel.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text('${room.name} · ${plural(s.adults, 'adult')}', style: TextStyle(fontSize: 12, color: c.textMuted)),
                        Text(
                          '${formatDayDate(s.checkIn)} → ${formatDayDate(s.checkOut)} · ${plural(s.nights, 'night')}',
                          style: TextStyle(fontSize: 12, color: c.textMuted),
                        ),
                        if (room.cancellation != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.check_circle_outline, size: 13, color: c.success),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  room.cancellation!,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.success),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (course != null) ...[
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
                      child: Icon(Icons.golf_course_rounded, color: c.accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Add a tee time near ${hotel.airportCode}',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.onSecondary)),
                          Text('${course.name} · from ${formatPeso(course.pricePerPlayer)}',
                              style: TextStyle(fontSize: 12, color: c.onSecondary)),
                        ],
                      ),
                    ),
                    TextButton(onPressed: () => context.push('/golf'), child: const Text('Add')),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const UiLabel('Lead guest'),
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
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) => (v ?? '').trim().length < 2 ? 'Enter the lead guest’s name' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email for confirmation'),
              validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim()) ? null : 'Enter a valid email',
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                children: [
                  _Line('${formatPeso(room.nightlyRate)} × ${plural(s.nights, 'night')}', formatPeso(subtotal)),
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
                label: 'Rate hold expired · Tap to refresh',
              )
            else if (_activePriceShift != null && _activePriceShift != 0 && !_priceShiftAccepted)
              AppGradientButton(
                onPressed: () => _promptPriceShift(baseTotal, shiftedTotal, shift, hotel, room),
                icon: Icons.warning_amber_rounded,
                label: 'Review updated rate · ${formatPeso(shiftedTotal)}',
              )
            else
              AppGradientButton(
                onPressed: () => _pay(hotel, room, effectiveTotal),
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

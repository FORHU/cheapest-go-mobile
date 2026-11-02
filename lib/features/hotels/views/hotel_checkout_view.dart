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
    this.catalog = travelCatalog,
    super.key,
  });

  final String hotelId;
  final String roomId;
  final TravelCatalog catalog;

  @override
  State<HotelCheckoutView> createState() => _HotelCheckoutViewState();
}

class _HotelCheckoutViewState extends State<HotelCheckoutView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  bool _paying = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _pay(Hotel hotel, Room room, int total) async {
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
  Widget build(BuildContext context) {
    final c = context.colors;
    final hotel = widget.catalog.hotel(widget.hotelId);
    final room = hotel?.rooms.where((r) => r.id == widget.roomId).firstOrNull;
    if (hotel == null || room == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(icon: Icons.hotel_outlined, title: 'Nothing to check out', message: 'Pick a hotel and room first.'),
      );
    }
    final s = tripSearchStore;
    final subtotal = room.nightlyRate * s.nights;
    final taxes = stayTaxes(subtotal);
    final total = subtotal + taxes;
    final course = widget.catalog.coursesNear(hotel.airportCode).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Review and pay')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            AppCard(
              child: Row(
                children: [
                  const PhotoPlaceholder(width: 64, height: 64, radius: 10),
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
                        if (room.cancellation != null)
                          Text(room.cancellation!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.success)),
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
            const UiLabel('Lead guest'),
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
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  _Line('Total', formatPeso(total), bold: true),
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
            AppGradientButton(
              onPressed: () => _pay(hotel, room, total),
              isLoading: _paying,
              icon: Icons.lock_outline_rounded,
              label: 'Pay ${formatPeso(total)}',
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
          child: Text(label, style: TextStyle(fontSize: bold ? 15 : 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w400, color: bold ? c.textPrimary : c.textSecondary)),
        ),
        Text(value, style: TextStyle(fontSize: bold ? 15 : 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: bold ? c.accent : c.textPrimary)),
      ],
    );
  }
}

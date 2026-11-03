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
  const FlightCheckoutView({required this.offerId, this.leadName, this.leadEmail, this.catalog = travelCatalog, super.key});

  /// Pre-fills the lead passenger from the signed-in traveler.
  final String? leadName;
  final String? leadEmail;

  final String offerId;
  final TravelCatalog catalog;

  @override
  State<FlightCheckoutView> createState() => _FlightCheckoutViewState();
}

class _FlightCheckoutViewState extends State<FlightCheckoutView> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.leadName);
  late final _email = TextEditingController(text: widget.leadEmail);
  bool _paying = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _pay(FlightOffer f, int total) async {
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
  Widget build(BuildContext context) {
    final c = context.colors;
    final f = widget.catalog.flight(widget.offerId);
    if (f == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(icon: Icons.flight_outlined, title: 'Nothing to check out', message: 'Pick a flight first.'),
      );
    }
    final s = tripSearchStore;
    final fares = f.price * s.adults;
    final taxes = flightTaxes(fares);
    final total = fares + taxes;
    final stays = widget.catalog.hotelsNear(f.destination);

    return Scaffold(
      appBar: AppBar(title: const Text('Review and pay')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
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
                  Text('${f.airline} ${f.flightNo} · ${f.baggage}', style: TextStyle(fontSize: 12, color: c.textMuted)),
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
                          Text('Need a stay near ${f.destination}?',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.onSecondary)),
                          Text('${stays.first.name} · ${stays.first.distanceLabel}',
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.onSecondary)),
                        ],
                      ),
                    ),
                    TextButton(onPressed: () => context.push('/airport/${f.destination}'), child: const Text('View')),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            const UiLabel('Lead passenger'),
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
              onPressed: () => _pay(f, total),
              isLoading: _paying,
              icon: Icons.lock_outline_rounded,
              label: 'Pay ${formatPeso(total)}',
            ),
            const SizedBox(height: 6),
            Text('Test mode: no card is charged in this build.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: c.textMuted)),
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
          child: Text(label,
              style: TextStyle(fontSize: bold ? 15 : 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w400, color: bold ? c.textPrimary : c.textSecondary)),
        ),
        Text(value,
            style: TextStyle(fontSize: bold ? 15 : 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: bold ? c.accent : c.textPrimary)),
      ],
    );
  }
}

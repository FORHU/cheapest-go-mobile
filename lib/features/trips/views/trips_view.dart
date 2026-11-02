import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/components/ui_kit.dart';
import 'package:cheapest_go_mobile/shared/stores/bookings_store.dart';
import 'package:cheapest_go_mobile/shared/stores/saved_store.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';
import 'package:cheapest_go_mobile/shared/utils/format.dart';

/// Booked stays and tee times, plus saved hotels.
class TripsView extends StatefulWidget {
  const TripsView({this.catalog = travelCatalog, this.initialTab = 0, super.key});

  final TravelCatalog catalog;

  /// 0 upcoming, 1 past, 2 saved.
  final int initialTab;

  @override
  State<TripsView> createState() => _TripsViewState();
}

class _TripsViewState extends State<TripsView> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([bookingsStore, savedStaysStore]),
      builder: (context, _) => SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text('Trips', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 26)),
            const SizedBox(height: 14),
            SegmentedTabs(
              labels: const ['Upcoming', 'Past', 'Saved'],
              selected: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 16),
            ...switch (_tab) {
              0 => _bookings(context, bookingsStore.upcoming, upcoming: true),
              1 => _bookings(context, bookingsStore.past, upcoming: false),
              _ => _saved(context),
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _bookings(BuildContext context, List<Booking> bookings, {required bool upcoming}) {
    if (bookings.isEmpty) {
      return [
        EmptyState(
          icon: Icons.luggage_outlined,
          title: upcoming ? 'No trips booked yet' : 'No past trips',
          message: upcoming
              ? 'Book a stay or a tee time near your arrival airport and it shows up here.'
              : 'Trips you have taken will be listed here.',
          action: upcoming ? FilledButton(onPressed: () => context.go('/'), child: const Text('Find a stay')) : null,
        ),
      ];
    }
    final c = context.colors;
    final byAirport = <String, List<Booking>>{};
    for (final b in bookings) {
      byAirport.putIfAbsent(b.airportCode, () => []).add(b);
    }
    return [
      for (final entry in byAirport.entries) ...[
        Row(
          children: [
            Text(entry.key, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: c.accent)),
            const SizedBox(width: 8),
            Text(widget.catalog.airport(entry.key)?.city ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 10),
        for (final b in entry.value) ...[
          _BookingCard(booking: b),
          const SizedBox(height: 10),
        ],
        if (upcoming && entry.value.every((b) => b.kind != BookingKind.teeTime)) ...[
          OutlinedButton(onPressed: () => context.push('/golf'), child: const Text('Add a tee time to this trip')),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
      ],
    ];
  }

  List<Widget> _saved(BuildContext context) {
    final hotels = [
      for (final id in savedStaysStore.ids) ?widget.catalog.hotel(id),
    ];
    if (hotels.isEmpty) {
      return [
        EmptyState(
          icon: Icons.favorite_border_rounded,
          title: 'No saved stays',
          message: 'Tap the heart on a hotel to keep it here.',
          action: FilledButton(onPressed: () => context.push('/hotels'), child: const Text('Browse hotels')),
        ),
      ];
    }
    final c = context.colors;
    return [
      for (final h in hotels) ...[
        AppCard(
          padding: const EdgeInsets.all(10),
          onTap: () => context.push('/hotel/${h.id}'),
          child: Row(
            children: [
              const PhotoPlaceholder(width: 64, height: 64, radius: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    PinLine('${h.airportCode} · ${h.distanceLabel}'),
                    const SizedBox(height: 4),
                    PriceText(h.fromRate, suffix: '/night', size: 14),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove from saved',
                onPressed: () => savedStaysStore.toggle(h.id),
                icon: Icon(Icons.favorite_rounded, color: c.error),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    ];
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                switch (booking.kind) {
                  BookingKind.flight => Icons.flight_rounded,
                  BookingKind.stay => Icons.hotel_outlined,
                  BookingKind.teeTime => Icons.golf_course_rounded,
                },
                size: 14,
                color: c.label,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: UiLabel(switch (booking.kind) {
                  BookingKind.flight => 'Flight',
                  BookingKind.stay => 'Hotel stay',
                  BookingKind.teeTime => 'Tee time',
                }),
              ),
              const StatusPill('Confirmed'),
            ],
          ),
          const SizedBox(height: 10),
          Text(booking.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(booking.when, style: TextStyle(fontSize: 13, color: c.textSecondary)),
          const SizedBox(height: 2),
          Text(booking.detail, style: TextStyle(fontSize: 12, color: c.textMuted)),
          const SizedBox(height: 10),
          Divider(color: c.hairline),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Ref ', style: TextStyle(fontSize: 12, color: c.textMuted)),
              Text(booking.reference, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
              const Spacer(),
              Text(formatPeso(booking.total), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

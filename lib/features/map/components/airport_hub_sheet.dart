import 'package:flutter/material.dart';
import 'package:cheapest_go_mobile/features/map/models/map_models.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/components/app_buttons.dart';
import 'package:cheapest_go_mobile/shared/components/ui_kit.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_radius.dart';
import 'package:cheapest_go_mobile/shared/utils/format.dart';

/// Bottom sheet over the map for the selected arrival airport: its stays, golf
/// courses and flights in, or one pinned place with a way to book it.
class AirportHubSheet extends StatelessWidget {
  const AirportHubSheet({
    required this.airport,
    required this.places,
    required this.filter,
    required this.onFilterChanged,
    required this.onPlaceSelected,
    required this.onOpenPlace,
    required this.onOpenHub,
    required this.onBookFlight,
    required this.onNextAirport,
    required this.onPreviousAirport,
    required this.onClose,
    this.selectedPlace,
    this.onClearPlace,
    this.catalog = travelCatalog,
    super.key,
  });

  final Airport airport;

  /// Every stay and course near [airport], whatever the [filter].
  final List<MapPlace> places;
  final MapFilter filter;
  final ValueChanged<MapFilter> onFilterChanged;
  final ValueChanged<MapPlace> onPlaceSelected;

  /// Opens the place's own page to book it.
  final ValueChanged<MapPlace> onOpenPlace;
  final VoidCallback onOpenHub;
  final ValueChanged<FlightOffer> onBookFlight;
  final VoidCallback onNextAirport;
  final VoidCallback onPreviousAirport;
  final VoidCallback onClose;
  final MapPlace? selectedPlace;
  final VoidCallback? onClearPlace;
  final TravelCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final stays = places.where((p) => !p.isGolf).toList();
    final courses = places.where((p) => p.isGolf).toList();
    final place = selectedPlace;

    return Material(
      color: c.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.brSheet, side: BorderSide(color: c.border)),
      elevation: 8,
      shadowColor: const Color(0x33000000),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: c.secondary, borderRadius: AppRadius.brMd),
                  child: Text(airport.code, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.onSecondary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${airport.city}, ${airport.country}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      Text(airport.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.textMuted)),
                    ],
                  ),
                ),
                IconButton(tooltip: 'Previous airport', onPressed: onPreviousAirport, icon: const Icon(Icons.chevron_left_rounded)),
                IconButton(tooltip: 'Next airport', onPressed: onNextAirport, icon: const Icon(Icons.chevron_right_rounded)),
                IconButton(tooltip: 'Close', onPressed: onClose, icon: const Icon(Icons.close_rounded)),
              ],
            ),
          ),
          if (place == null) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                children: [
                  for (final (f, label, icon) in [
                    (MapFilter.overview, 'Overview', Icons.flight_land_rounded),
                    (MapFilter.stays, 'Stays · ${stays.length}', Icons.hotel_rounded),
                    (MapFilter.golf, 'Golf · ${courses.length}', Icons.golf_course_rounded),
                    (MapFilter.flights, 'Flights in', Icons.flight_rounded),
                  ]) ...[
                    FilterPill(label: label, icon: icon, selected: filter == f, onTap: () => onFilterChanged(f)),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            Flexible(
              child: switch (filter) {
                MapFilter.overview => _Overview(airport: airport, stays: stays, courses: courses, onFilterChanged: onFilterChanged, onOpenHub: onOpenHub),
                MapFilter.stays => _PlaceList(places: stays, empty: 'No stays near ${airport.code} yet.', onTap: onPlaceSelected),
                MapFilter.golf => _PlaceList(places: courses, empty: 'No courses near ${airport.code} yet.', onTap: onPlaceSelected),
                MapFilter.flights => _FlightList(offers: flightsInto(catalog, airport), catalog: catalog, onTap: onBookFlight),
              },
            ),
          ] else
            Flexible(child: _PlacePreview(place: place, onBack: onClearPlace, onOpen: () => onOpenPlace(place))),
        ],
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.airport, required this.stays, required this.courses, required this.onFilterChanged, required this.onOpenHub});

  final Airport airport;
  final List<MapPlace> stays;
  final List<MapPlace> courses;
  final ValueChanged<MapFilter> onFilterChanged;
  final VoidCallback onOpenHub;

  int? _from(List<MapPlace> items) => items.isEmpty ? null : items.map((p) => p.price).reduce((a, b) => a < b ? a : b);

  @override
  Widget build(BuildContext context) {
    final stayFrom = _from(stays);
    final golfFrom = _from(courses);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: plural(stays.length, 'stay'),
                  amount: stayFrom,
                  suffix: '/night',
                  onTap: () => onFilterChanged(MapFilter.stays),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: plural(courses.length, 'golf course'),
                  amount: golfFrom,
                  suffix: '/player',
                  golf: true,
                  onTap: () => onFilterChanged(MapFilter.golf),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppGradientButton(label: 'Open the ${airport.code} airport hub', icon: Icons.arrow_forward_rounded, height: 48, onPressed: onOpenHub),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.amount, required this.suffix, required this.onTap, this.golf = false});

  final String label;
  final int? amount;
  final String suffix;
  final VoidCallback onTap;
  final bool golf;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final amount = this.amount;
    return AppCard(
      onTap: onTap,
      color: golf ? c.golfSoft : c.secondary,
      borderColor: Colors.transparent,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UiLabel(label),
          const SizedBox(height: 4),
          if (amount == null)
            Text('None yet', style: TextStyle(fontSize: 14, color: c.textMuted))
          else
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'from ', style: TextStyle(fontSize: 12, color: c.textSecondary)),
                  TextSpan(
                    text: formatPeso(amount),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: golf ? c.onGolfSoft : c.onSecondary),
                  ),
                  TextSpan(text: ' $suffix', style: TextStyle(fontSize: 11, color: c.textMuted)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PlaceList extends StatelessWidget {
  const _PlaceList({required this.places, required this.empty, required this.onTap});

  final List<MapPlace> places;
  final String empty;
  final ValueChanged<MapPlace> onTap;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(empty, style: TextStyle(color: context.colors.textMuted)),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: places.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _PlaceRow(place: places[i], onTap: () => onTap(places[i])),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({required this.place, required this.onTap});

  final MapPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hotel = place.hotel;
    final course = place.course;
    return AppCard(
      padding: const EdgeInsets.all(8),
      onTap: onTap,
      child: Row(
        children: [
          PhotoPlaceholder(image: hotel?.cover ?? course!.photo, label: place.name, width: 56, height: 56, golf: place.isGolf),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                if (hotel != null)
                  PinLine(hotel.distanceLabel)
                else
                  PinLine('${course!.driveMinutes} min from ${course.airportCode}', icon: Icons.schedule_rounded),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PriceText(place.price, suffix: place.isGolf ? '/player' : '/night', size: 14),
        ],
      ),
    );
  }
}

class _FlightList extends StatelessWidget {
  const _FlightList({required this.offers, required this.catalog, required this.onTap});

  final List<FlightOffer> offers;
  final TravelCatalog catalog;
  final ValueChanged<FlightOffer> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: offers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final f = offers[i];
        return AppCard(
          padding: const EdgeInsets.all(12),
          onTap: () => onTap(f),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${f.origin} → ${f.destination} · ${catalog.origin(f.origin)?.city ?? f.origin}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('${f.airline} · ${f.durationLabel} · ${f.stopsLabel}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PriceText(f.price, suffix: '/person', size: 14),
            ],
          ),
        );
      },
    );
  }
}

class _PlacePreview extends StatelessWidget {
  const _PlacePreview({required this.place, required this.onBack, required this.onOpen});

  final MapPlace place;
  final VoidCallback? onBack;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hotel = place.hotel;
    final course = place.course;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(place.isGolf ? 'All golf' : 'All stays'),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PhotoPlaceholder(image: hotel?.cover ?? course!.photo, label: place.name, width: 96, height: 96, golf: place.isGolf),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    if (hotel != null) ...[
                      PinLine(hotel.hasShuttle ? '${hotel.distanceLabel} · free shuttle' : hotel.distanceLabel),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          RatingBadge(hotel.score),
                          const SizedBox(width: 6),
                          Flexible(child: Text('${hotel.scoreLabel} · ${hotel.reviews} reviews', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.textSecondary))),
                        ],
                      ),
                    ] else ...[
                      PinLine('${course!.driveMinutes} min from ${course.airportCode}', icon: Icons.schedule_rounded),
                      const SizedBox(height: 4),
                      Text(course.meta, style: TextStyle(fontSize: 12, color: c.textSecondary)),
                    ],
                    const SizedBox(height: 6),
                    PriceText(place.price, suffix: place.isGolf ? '/player' : '/night'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppGradientButton(
            label: place.isGolf ? 'Book a tee time' : 'See rooms & book',
            icon: place.isGolf ? Icons.golf_course_rounded : Icons.hotel_rounded,
            height: 48,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/components/ui_kit.dart';
import 'package:cheapest_go_mobile/shared/stores/trip_search_store.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_radius.dart';
import 'package:cheapest_go_mobile/shared/utils/format.dart';

/// Airport hub: the stays and golf courses nearest one arrival airport.
class AirportHubView extends StatefulWidget {
  const AirportHubView({required this.code, this.catalog = travelCatalog, super.key});

  final String code;
  final TravelCatalog catalog;

  @override
  State<AirportHubView> createState() => _AirportHubViewState();
}

class _AirportHubViewState extends State<AirportHubView> {
  static const _previewCount = 3;
  late int _tab = tripSearchStore.mode == SearchMode.golf ? 1 : 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final airport = widget.catalog.airport(widget.code);
    if (airport == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.flight_land_rounded,
          title: 'Airport not found',
          message: 'We have no stays or courses for ${widget.code} yet.',
        ),
      );
    }
    final hotels = widget.catalog.hotelsNear(airport.code);
    final courses = widget.catalog.coursesNear(airport.code);
    final s = tripSearchStore;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              Semantics(
                button: true,
                label: 'Open the map',
                child: GestureDetector(
                  onTap: () {
                    tripSearchStore.setAirport(airport.code);
                    context.go('/map');
                  },
                  child: SizedBox(
                    height: 220 + MediaQuery.paddingOf(context).top,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        PhotoPlaceholder(image: airport.photo, label: airport.city, radius: 0, fade: true),
                        Positioned(
                          right: 16,
                          bottom: 36,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(color: const Color(0x99020617), borderRadius: BorderRadius.circular(999)),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.public_rounded, size: 16, color: Colors.white),
                                SizedBox(width: 6),
                                Text('Open the map', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 12,
                left: 16,
                child: CircleIconButton(
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'Back',
                  onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                ),
              ),
            ],
          ),
          Transform.translate(
            offset: const Offset(0, -24),
            child: Container(
              decoration: BoxDecoration(
                color: c.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(airport.code, style: text.displaySmall?.copyWith(color: c.accent)),
                      const SizedBox(width: 10),
                      Text(airport.city, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${airport.name} · ${airport.terminals} · ${formatDateRange(s.checkIn, s.checkOut)}',
                    style: TextStyle(fontSize: 13, color: c.textMuted),
                  ),
                  const SizedBox(height: 16),
                  SegmentedTabs(
                    labels: ['Stays nearby · ${hotels.length}', 'Golf nearby · ${courses.length}'],
                    selected: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                  const SizedBox(height: 16),
                  if (_tab == 0) ...[
                    for (final h in hotels.take(_previewCount)) ...[
                      _StayRow(hotel: h, onTap: () => context.push('/hotel/${h.id}')),
                      const SizedBox(height: 10),
                    ],
                    if (hotels.isEmpty)
                      const EmptyState(icon: Icons.hotel_outlined, title: 'No stays yet', message: 'Try another airport.')
                    else
                      OutlinedButton(
                        onPressed: () {
                          s.setAirport(airport.code);
                          context.push('/hotels');
                        },
                        child: Text('See all ${plural(hotels.length, 'stay')} near ${airport.code}'),
                      ),
                  ] else ...[
                    for (final course in courses) ...[
                      _CourseRow(
                        course: course,
                        onTap: () {
                          s.setAirport(airport.code);
                          context.push('/golf');
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (courses.isEmpty)
                      const EmptyState(icon: Icons.golf_course_rounded, title: 'No courses yet', message: 'Try another airport.')
                    else
                      OutlinedButton(
                        onPressed: () {
                          s.setAirport(airport.code);
                          context.push('/golf');
                        },
                        child: Text('See tee times near ${airport.code}'),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StayRow extends StatelessWidget {
  const _StayRow({required this.hotel, required this.onTap});

  final Hotel hotel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: Row(
        children: [
          PhotoPlaceholder(image: hotel.cover, label: hotel.name, width: 88, height: 88),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 88,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hotel.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  PinLine(hotel.hasShuttle ? '${hotel.distanceLabel} · free shuttle' : hotel.distanceLabel),
                  const Spacer(),
                  Row(
                    children: [
                      RatingBadge(hotel.score),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(hotel.scoreLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.textSecondary)),
                      ),
                      PriceText(hotel.fromRate, suffix: '/night', size: 15),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseRow extends StatelessWidget {
  const _CourseRow({required this.course, required this.onTap});

  final GolfCourse course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: Row(
        children: [
          PhotoPlaceholder(image: course.photo, label: course.name, width: 72, height: 72, golf: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                PinLine('${course.driveMinutes} min from ${course.airportCode}', icon: Icons.schedule_rounded),
                const SizedBox(height: 6),
                PriceText(course.pricePerPlayer, suffix: '/player', size: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

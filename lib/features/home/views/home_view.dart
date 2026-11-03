import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/components/airport_picker.dart';
import 'package:cheapest_go_mobile/shared/components/ui_kit.dart';
import 'package:cheapest_go_mobile/shared/stores/trip_search_store.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_radius.dart';
import 'package:cheapest_go_mobile/shared/utils/format.dart';

/// Stay & Play (Home): pick the arrival airport, dates and guests, then find
/// stays and tee times nearby. Flights have their own tab.
class HomeView extends StatelessWidget {
  const HomeView({this.catalog = travelCatalog, super.key});

  final TravelCatalog catalog;

  static const _modes = [SearchMode.stays, SearchMode.golf, SearchMode.both];

  void _search(BuildContext context) {
    tripSearchStore.remember();
    final code = tripSearchStore.airportCode;
    if (tripSearchStore.mode == SearchMode.golf) {
      context.push('/golf');
    } else {
      context.push('/airport/$code');
    }
  }

  Future<void> _pickDates(BuildContext context) async {
    final today = dateOnly(DateTime.now());
    final range = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: tripSearchStore.checkIn, end: tripSearchStore.checkOut),
    );
    if (range != null) tripSearchStore.setDates(range.start, range.end);
  }

  Future<void> _pickGuests(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => ListenableBuilder(
        listenable: tripSearchStore,
        builder: (context, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(child: Text('Adults', style: Theme.of(context).textTheme.titleMedium)),
                IconButton.outlined(
                  tooltip: 'Fewer adults',
                  onPressed: () => tripSearchStore.setAdults(tripSearchStore.adults - 1),
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 44,
                  child: Text('${tripSearchStore.adults}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                ),
                IconButton.outlined(
                  tooltip: 'More adults',
                  onPressed: () => tripSearchStore.setAdults(tripSearchStore.adults + 1),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: tripSearchStore,
      builder: (context, _) {
        final s = tripSearchStore;
        final airport = catalog.airport(s.airportCode);
        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        const TextSpan(text: 'Cheapest'),
                        TextSpan(text: 'Go', style: TextStyle(color: c.accent)),
                      ]),
                      style: text.headlineSmall?.copyWith(fontSize: 22),
                    ),
                  ),
                  CircleIconButton(
                    icon: Icons.person_outline_rounded,
                    tooltip: 'Profile and account',
                    onPressed: () => context.push('/profile'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Where are you\nflying into?', style: text.headlineLarge),
              const SizedBox(height: 6),
              Text('Stays and tee times near your arrival airport.', style: TextStyle(fontSize: 14, color: c.textMuted)),
              const SizedBox(height: 20),
              AppCard(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedTabs(
                      labels: const ['Stays', 'Golf', 'Stay + Golf'],
                      selected: _modes.indexOf(s.mode).clamp(0, _modes.length - 1),
                      onChanged: (i) => s.setMode(_modes[i]),
                    ),
                    _SearchField(
                      label: 'Arrival airport',
                      value: airport == null ? s.airportCode : '${airport.code} · ${airport.name}, ${airport.city}',
                      icon: Icons.flight_land_rounded,
                      onTap: () async {
                        final code = await showAirportPicker(context, selected: s.airportCode, catalog: catalog);
                        if (code != null) s.setAirport(code);
                      },
                    ),
                    Divider(color: c.hairline),
                    Row(
                      children: [
                        Expanded(
                          child: _SearchField(
                            label: 'Dates',
                            value: formatDateRange(s.checkIn, s.checkOut),
                            onTap: () => _pickDates(context),
                          ),
                        ),
                        SizedBox(height: 48, child: VerticalDivider(color: c.hairline, width: 1)),
                        Expanded(
                          child: _SearchField(
                            label: s.mode == SearchMode.golf ? 'Players' : 'Guests',
                            value: s.mode == SearchMode.golf
                                ? plural(s.players, 'player')
                                : '${plural(s.adults, 'adult')} · 1 room',
                            onTap: () => _pickGuests(context),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: FilledButton.icon(
                        onPressed: () => _search(context),
                        icon: const Icon(Icons.search_rounded, size: 18),
                        label: Text('Search near ${s.airportCode}'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: _Shortcut(
                      icon: Icons.hotel_outlined,
                      title: 'Hotels',
                      subtitle: 'near ${s.airportCode}',
                      onTap: () => context.go('/stay'),
                    ),
                  ),
                  Expanded(
                    child: _Shortcut(
                      icon: Icons.golf_course_rounded,
                      title: 'Tee times',
                      subtitle: 'near ${s.airportCode}',
                      golf: true,
                      onTap: () => context.go('/stay?tab=golf'),
                    ),
                  ),
                ],
              ),
              if (s.recentAirports.isNotEmpty) ...[
                const SizedBox(height: 24),
                const UiLabel('Your recent searches'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final code in s.recentAirports)
                      FilterPill(
                        icon: Icons.schedule_rounded,
                        label: '$code · ${formatShortDate(s.checkIn)}',
                        onTap: () {
                          s.setAirport(code);
                          _search(context);
                        },
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Text('Popular arrival airports', style: text.titleLarge),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    for (final a in catalog.airports()) _airportCard(context, a),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _airportCard(BuildContext context, Airport a) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final stays = catalog.hotelsNear(a.code).length;
    final courses = catalog.coursesNear(a.code).length;
    return SizedBox(
      width: 156,
      child: AppCard(
        padding: EdgeInsets.zero,
        clip: true,
        onTap: () {
          tripSearchStore.setAirport(a.code);
          _search(context);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 96,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PhotoPlaceholder(image: a.photo, label: a.city, radius: 0, fade: true),
                  Positioned(
                    left: 12,
                    bottom: 8,
                    child: Text(
                      a.code,
                      style: text.headlineMedium?.copyWith(fontSize: 24, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.city, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  // One fact per line keeps every card the same height.
                  Text(plural(stays, 'stay'), maxLines: 1, style: TextStyle(fontSize: 12, color: c.textMuted)),
                  Text(plural(courses, 'course'), maxLines: 1, style: TextStyle(fontSize: 12, color: c.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick way into hotels or golf near the chosen airport.
class _Shortcut extends StatelessWidget {
  const _Shortcut({required this.icon, required this.title, required this.subtitle, required this.onTap, this.golf = false});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool golf;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: golf ? c.golfSoft : c.secondary,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 20, color: golf ? c.onGolfSoft : c.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: c.textMuted)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: c.textSubtle),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.label, required this.value, required this.onTap, this.icon});

  final String label;
  final String value;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: c.secondary, borderRadius: BorderRadius.circular(AppRadius.base)),
                child: Icon(icon, size: 18, color: c.accent),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UiLabel(label),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: c.textPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

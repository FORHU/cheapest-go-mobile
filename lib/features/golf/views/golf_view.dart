import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/components/app_buttons.dart';
import 'package:cheapest_go_mobile/shared/components/airport_picker.dart';
import 'package:cheapest_go_mobile/shared/components/ui_kit.dart';
import 'package:cheapest_go_mobile/shared/stores/bookings_store.dart';
import 'package:cheapest_go_mobile/shared/stores/trip_search_store.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_radius.dart';
import 'package:cheapest_go_mobile/shared/utils/format.dart';

/// Golf courses near the arrival airport, with bookable tee times.
class GolfView extends StatefulWidget {
  const GolfView({this.catalog = travelCatalog, this.showBack = true, super.key});

  final TravelCatalog catalog;

  /// False when shown inside a tab rather than opened as a page.
  final bool showBack;

  @override
  State<GolfView> createState() => _GolfViewState();
}

class _GolfViewState extends State<GolfView> {
  int _dayIndex = 0;

  Future<void> _book(GolfCourse course, DateTime day, String time) async {
    final players = await showModalBottomSheet<int>(
      context: context,
      // Over the whole app, so the bottom bar never covers the sheet.
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => _TeeTimeSheet(course: course, day: day, time: time, initialPlayers: tripSearchStore.players),
    );
    if (players == null || !mounted) return;
    bookingsStore.addTeeTime(
      airportCode: course.airportCode,
      courseName: course.name,
      courseMeta: course.meta,
      day: day,
      teeTime: time,
      players: players,
      total: course.pricePerPlayer * players,
    );
    // Not '/trips', and no reference quoted — see the same change in flight checkout and
    // ADR-0003. Nothing here reaches a course, and Trips now shows only confirmed bookings.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demo booking — tee times are not bookable yet')),
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
        final days = s.playDays;
        final dayIndex = _dayIndex.clamp(0, days.length - 1);
        final day = days[dayIndex];
        final courses = widget.catalog.coursesNear(s.airportCode);
        final maxDrive = courses.isEmpty ? 0 : courses.map((c) => c.driveMinutes).reduce((a, b) => a > b ? a : b);

        return SafeArea(
          bottom: false,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Row(
                children: [
                  if (widget.showBack) ...[
                    CircleIconButton(
                      icon: Icons.chevron_left_rounded,
                      tooltip: 'Back',
                      onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        const TextSpan(text: 'Golf near '),
                        TextSpan(text: s.airportCode, style: TextStyle(color: c.accent)),
                      ]),
                      style: text.headlineLarge?.copyWith(fontSize: 26),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final code = await showAirportPicker(context, selected: s.airportCode, catalog: widget.catalog);
                      if (code != null) s.setAirport(code);
                    },
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text('Airport'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                courses.isEmpty
                    ? 'No courses near ${s.airportCode} yet'
                    : '${plural(courses.length, 'course')} within $maxDrive min of the airport · ${plural(s.players, 'player')}',
                style: TextStyle(fontSize: 13, color: c.textMuted),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: days.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final on = i == dayIndex;
                    return Semantics(
                      selected: on,
                      button: true,
                      label: formatDayDate(days[i]),
                      child: Material(
                        color: on ? c.accent : c.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.brMd,
                          side: BorderSide(color: on ? c.accent : c.border),
                        ),
                        child: InkWell(
                          borderRadius: AppRadius.brMd,
                          onTap: () => setState(() => _dayIndex = i),
                          child: SizedBox(
                            width: 56,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(weekdayShort(days[i]),
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: on ? c.accentOn : c.textSecondary)),
                                Text('${days[i].day}',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: on ? c.accentOn : c.textPrimary)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (courses.isEmpty)
                const EmptyState(
                  icon: Icons.golf_course_rounded,
                  title: 'No courses here yet',
                  message: 'Switch to another arrival airport to see tee times.',
                ),
              for (final course in courses) ...[
                _CourseCard(course: course, onTime: (t) => _book(course, day, t)),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, required this.onTime});

  final GolfCourse course;
  final ValueChanged<String> onTime;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PhotoPlaceholder(image: course.photo, label: course.name, width: 72, height: 72, golf: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(course.meta, style: TextStyle(fontSize: 12, color: c.textMuted)),
                    const SizedBox(height: 3),
                    PinLine('${course.driveMinutes} min from ${course.airportCode}', icon: Icons.schedule_rounded),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('from', style: TextStyle(fontSize: 11, color: c.textMuted)),
                  PriceText(course.pricePerPlayer),
                  Text('/player', style: TextStyle(fontSize: 11, color: c.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in course.teeTimes)
                Material(
                  color: c.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.base),
                    side: BorderSide(color: c.secondaryBorder),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.base),
                    onTap: () => onTime(t),
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 72, minHeight: 40),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(formatTeeTime(t),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.onSecondary)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Confirms a tee time; pops with the number of players, or `null`.
class _TeeTimeSheet extends StatefulWidget {
  const _TeeTimeSheet({required this.course, required this.day, required this.time, required this.initialPlayers});

  final GolfCourse course;
  final DateTime day;
  final String time;
  final int initialPlayers;

  @override
  State<_TeeTimeSheet> createState() => _TeeTimeSheetState();
}

class _TeeTimeSheetState extends State<_TeeTimeSheet> {
  late int _players = widget.initialPlayers;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final total = widget.course.pricePerPlayer * _players;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.course.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('${formatDayDate(widget.day)} · ${formatTeeTime(widget.time)} · ${widget.course.meta}',
                style: TextStyle(fontSize: 13, color: c.textMuted)),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(child: Text('Players', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                IconButton.outlined(
                  tooltip: 'Fewer players',
                  onPressed: _players > 1 ? () => setState(() => _players--) : null,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 44,
                  child: Text('$_players', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                ),
                IconButton.outlined(
                  tooltip: 'More players',
                  onPressed: _players < 4 ? () => setState(() => _players++) : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text('${formatPeso(widget.course.pricePerPlayer)} × ${plural(_players, 'player')}', style: TextStyle(color: c.textSecondary))),
                PriceText(total, size: 18),
              ],
            ),
            const SizedBox(height: 16),
            AppGradientButton(
              onPressed: () => Navigator.pop(context, _players),
              label: 'Book tee time · ${formatPeso(total)}',
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

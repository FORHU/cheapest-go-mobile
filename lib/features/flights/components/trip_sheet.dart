import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:cheapest_go_mobile/features/flights/components/flight_chrome.dart';
import 'package:cheapest_go_mobile/features/flights/lib/flight_search_query.dart';
import 'package:cheapest_go_mobile/features/flights/lib/flight_utils.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';

/// Dates, travellers and cabin — V2's `Trip`.
class Trip {
  const Trip({
    required this.departure,
    this.returnDate,
    required this.adults,
    required this.children,
    required this.infants,
    required this.cabin,
  });

  final String departure;
  final String? returnDate;
  final int adults;
  final int children;
  final int infants;
  final String cabin;

  Trip copyWith({
    String? departure,
    String? Function()? returnDate,
    int? adults,
    int? children,
    int? infants,
    String? cabin,
  }) => Trip(
    departure: departure ?? this.departure,
    returnDate: returnDate != null ? returnDate() : this.returnDate,
    adults: adults ?? this.adults,
    children: children ?? this.children,
    infants: infants ?? this.infants,
    cabin: cabin ?? this.cabin,
  );
}

const cabins = ['economy', 'premium_economy', 'business', 'first'];

/// "Dec 3 – Dec 10 · 1 adult · Economy" — the trip button's label.
String tripLabel(AppLocalizations t, Trip trip) {
  String short(String iso) {
    final d = parseIsoDate(iso);
    return d == null ? iso : DateFormat('MMM d', 'en_US').format(d);
  }

  final travellers = [
    withCount(t.flights_passengers_adults(trip.adults), trip.adults),
    if (trip.children > 0)
      withCount(t.flights_passengers_children(trip.children), trip.children),
    if (trip.infants > 0)
      withCount(t.flights_passengers_infants(trip.infants), trip.infants),
  ].join(', ');
  final dates = trip.returnDate != null
      ? '${short(trip.departure)} – ${short(trip.returnDate!)}'
      : short(trip.departure);
  return '$dates · $travellers · ${cabinName(t, trip.cabin)}';
}

/// V2's `TripEditor` as a phone opens it: a sheet along the bottom (`BarSheet`), its controls
/// sized for a thumb — 44px days, steppers and chips, a 48px Done pinned to the foot.
///
/// Edits are a draft until Done, so stepping through the calendar does not search per tap, and
/// a round trip without its return date cannot be applied.
Future<Trip?> showTripSheet(BuildContext context, Trip trip) {
  return showModalBottomSheet<Trip>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    barrierColor: const Color(0x73000000),
    backgroundColor: Colors.transparent,
    builder: (_) => TripSheet(trip: trip),
  );
}

class TripSheet extends StatefulWidget {
  const TripSheet({required this.trip, super.key});

  final Trip trip;

  @override
  State<TripSheet> createState() => _TripSheetState();
}

class _TripSheetState extends State<TripSheet> {
  late Trip _draft = widget.trip;
  late bool _roundTrip = widget.trip.returnDate != null;
  late DateTime _month = () {
    final d = parseIsoDate(widget.trip.departure) ?? DateTime.now();
    return DateTime(d.year, d.month);
  }();

  bool get _ready =>
      _draft.departure.isNotEmpty &&
      (!_roundTrip || (_draft.returnDate?.isNotEmpty ?? false));

  /// One way: any tap is the departure. Round trip: a first tap, or one on or before the
  /// departure, starts over; a later one is the return.
  void _pick(String day) => setState(() {
    final d = _draft;
    if (_roundTrip &&
        d.departure.isNotEmpty &&
        (d.returnDate?.isEmpty ?? true) &&
        day.compareTo(d.departure) > 0) {
      _draft = d.copyWith(returnDate: () => day);
    } else {
      _draft = d.copyWith(
        departure: day,
        returnDate: () => _roundTrip ? '' : null,
      );
    }
  });

  void _setRound(bool round) => setState(() {
    _roundTrip = round;
    _draft = _draft.copyWith(
      returnDate: () => round ? (_draft.returnDate ?? '') : null,
    );
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final skin = FlightSkin.of(context);

    Widget chip(String label, bool on, VoidCallback onTap) => Material(
      color: Colors.transparent,
      child: Ink(
        height: 44,
        decoration: BoxDecoration(
          gradient: on ? FlightSkin.gradient : null,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? Colors.transparent : skin.hairline),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: on ? Colors.white : skin.title,
              ),
            ),
          ),
        ),
      ),
    );

    // An infant flies on an adult's lap, so there can be no more of them than adults.
    final counters = [
      (
        key: 'adults',
        label: t.landing_search_adults,
        value: _draft.adults,
        min: 1,
        max: 9 - _draft.children,
      ),
      (
        key: 'children',
        label: t.landing_search_children,
        value: _draft.children,
        min: 0,
        max: 9 - _draft.adults,
      ),
      (
        key: 'infants',
        label: t.landing_search_infants,
        value: _draft.infants,
        min: 0,
        max: _draft.adults,
      ),
    ];

    void step(String key, int delta) => setState(() {
      final next = switch (key) {
        'adults' => _draft.copyWith(adults: _draft.adults + delta),
        'children' => _draft.copyWith(children: _draft.children + delta),
        _ => _draft.copyWith(infants: _draft.infants + delta),
      };
      // Fewer adults can leave more infants than laps.
      _draft = next.copyWith(
        infants: next.infants > next.adults ? next.adults : next.infants,
      );
    });

    Widget stepper(
      IconData icon,
      String label,
      bool enabled,
      VoidCallback onTap,
    ) => Opacity(
      opacity: enabled ? 1 : 0.3,
      child: Semantics(
        button: true,
        label: label,
        child: InkResponse(
          onTap: enabled ? onTap : null,
          radius: 24,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: skin.hairline),
            ),
            child: Icon(icon, size: 16, color: skin.title),
          ),
        ),
      ),
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: BoxDecoration(
        color: skin.menu,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: skin.hairline),
          left: BorderSide(color: skin.hairline),
          right: BorderSide(color: skin.hairline),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: skin.hairline,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    t.flights_topBar_changeTrip,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: skin.title,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(LucideIcons.x, size: 20, color: skin.title),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: chip(
                          t.landing_search_tripType_oneWay,
                          !_roundTrip,
                          () => _setRound(false),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: chip(
                          t.landing_search_tripType_roundTrip,
                          _roundTrip,
                          () => _setRound(true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  RangeCalendar(
                    month: _month,
                    onMonth: (m) => setState(() => _month = m),
                    start: _draft.departure,
                    end: _draft.returnDate ?? '',
                    onPick: _pick,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: skin.hairline)),
                    ),
                    child: Column(
                      children: [
                        for (final c in counters)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    c.label,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: skin.title,
                                    ),
                                  ),
                                ),
                                stepper(
                                  LucideIcons.minus,
                                  AppLocalizations.of(context)!.mobile_a11y_removeOne(c.label),
                                  c.value > c.min,
                                  () => step(c.key, -1),
                                ),
                                SizedBox(
                                  width: 32,
                                  child: Text(
                                    '${c.value}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: skin.title,
                                    ),
                                  ),
                                ),
                                stepper(
                                  LucideIcons.plus,
                                  AppLocalizations.of(context)!.mobile_a11y_addOne(c.label),
                                  c.value < c.max,
                                  () => step(c.key, 1),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: skin.hairline)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          t.flights_topBar_cabin,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: skin.title,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (var row = 0; row < cabins.length; row += 2) ...[
                          if (row > 0) const SizedBox(height: 6),
                          Row(
                            children: [
                              for (
                                var i = row;
                                i < row + 2 && i < cabins.length;
                                i++
                              ) ...[
                                if (i > row) const SizedBox(width: 6),
                                Expanded(
                                  child: chip(
                                    cabinName(t, cabins[i]),
                                    _draft.cabin == cabins[i],
                                    () => setState(
                                      () => _draft = _draft.copyWith(
                                        cabin: cabins[i],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Done, pinned to the foot so it is never under the keyboard or the fold.
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: skin.hairline)),
            ),
            child: GradientPill(
              label: t.landing_search_done,
              height: 48,
              radius: 999,
              fontSize: 15,
              expand: true,
              onTap: _ready
                  ? () => Navigator.of(context).pop(
                      _draft.copyWith(
                        returnDate: () => _roundTrip ? _draft.returnDate : null,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// V2's `RangeCalendar`, roomy — a month at a time, Sunday first, past days unpickable.
class RangeCalendar extends StatelessWidget {
  const RangeCalendar({
    required this.month,
    required this.onMonth,
    required this.start,
    required this.end,
    required this.onPick,
    super.key,
  });

  final DateTime month;
  final ValueChanged<DateTime> onMonth;
  final String start;
  final String end;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final skin = FlightSkin.of(context);
    final now = DateTime.now();
    final today = isoDate(now);
    final thisMonth = DateTime(now.year, now.month);
    final lead = DateTime(month.year, month.month).weekday % 7;
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    Widget arrow(IconData icon, String label, bool enabled, DateTime to) =>
        Opacity(
          opacity: enabled ? 1 : 0.3,
          child: Material(
            color: skin.hover,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: enabled ? () => onMonth(to) : null,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  icon,
                  size: 15,
                  color: skin.title,
                  semanticLabel: label,
                ),
              ),
            ),
          ),
        );

    return Column(
      children: [
        Row(
          children: [
            arrow(
              LucideIcons.chevronLeft,
              'previous month',
              month.isAfter(thisMonth),
              DateTime(month.year, month.month - 1),
            ),
            Expanded(
              child: Text(
                DateFormat('MMMM y', 'en_US').format(month),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: skin.title,
                ),
              ),
            ),
            arrow(
              LucideIcons.chevronRight,
              'next month',
              true,
              DateTime(month.year, month.month + 1),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          children: [
            for (final w in weekdays)
              Center(
                child: Text(
                  w,
                  style: TextStyle(
                    fontSize: 12,
                    color: skin.title.withValues(alpha: 0.5),
                  ),
                ),
              ),
            for (var i = 0; i < lead; i++) const SizedBox.shrink(),
            for (var d = 1; d <= days; d++)
              Builder(
                builder: (context) {
                  final day = isoDate(DateTime(month.year, month.month, d));
                  final past = day.compareTo(today) < 0;
                  final edge = day == start || day == end;
                  final inside =
                      end.isNotEmpty &&
                      day.compareTo(start) > 0 &&
                      day.compareTo(end) < 0;
                  return Opacity(
                    opacity: past ? 0.3 : 1,
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: Ink(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: edge ? FlightSkin.gradient : null,
                            color: edge ? null : (inside ? skin.hover : null),
                          ),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: past ? null : () => onPick(day),
                            child: Center(
                              child: Text(
                                '$d',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: edge
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: edge ? Colors.white : skin.title,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}

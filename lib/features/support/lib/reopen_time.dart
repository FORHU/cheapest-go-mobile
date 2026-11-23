/// "Monday 9:00 AM (Asia/Manila)" — when the desk next opens. V2's `formatReopen`.
///
/// Rendered live rather than read from a stored notice, because the schedule can be edited and a
/// time written into a message becomes confidently wrong. The timezone is named because the
/// customer is very often not in it.
library;

import 'package:intl/intl.dart';

import 'package:cheapest_go_mobile/features/support/models/support_models.dart';

class ReopenText {
  const ReopenText({required this.today, required this.when});

  /// Later the same day, so the panel says "today" in its own words.
  final bool today;
  final String when;
}

const _dayIndex = {'sun': 0, 'mon': 1, 'tue': 2, 'wed': 3, 'thu': 4, 'fri': 5, 'sat': 6};

ReopenText? formatReopen(SupportOpening? opening, String locale) {
  if (opening == null) return null;
  final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(opening.open);
  if (match == null) return null;
  final hours = int.parse(match.group(1)!);
  final minutes = int.parse(match.group(2)!);
  if (hours > 24 || minutes > 59) return null;

  try {
    // A fixed date: only the clock face matters here.
    final time = DateFormat.jm(locale).format(DateTime.utc(2026, 1, 4, hours, minutes));
    if (opening.today) return ReopenText(today: true, when: '$time (${opening.timezone})');

    final day = _dayIndex[opening.day];
    if (day == null) return null;
    // 2026-01-04 is a Sunday.
    final weekday = DateFormat.EEEE(locale).format(DateTime.utc(2026, 1, 4 + day));
    return ReopenText(today: false, when: '$weekday $time (${opening.timezone})');
  } catch (_) {
    // Saying nothing beats "back on Invalid Date" to someone already waiting.
    return null;
  }
}

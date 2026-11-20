/// Display formatting for prices, dates, and tee times.
library;

import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

// Dates read in the language the app is set to, not in English.
//
// These were two const English arrays, so an app rendering Korean still wrote "Nov 28 – 29"
// beside Korean copy. DateFormat takes its language from `Intl.defaultLocale`, which
// app.dart sets whenever the language changes; unset, intl falls back to English, which is
// what the tests run in.
//
// Built per call rather than cached: the language can change while the app is running, and a
// formatter built once would keep writing the old language until the next launch.
String _month(DateTime d) => DateFormat.MMM(Intl.defaultLocale).format(d);
String _weekday(DateTime d) => DateFormat.E(Intl.defaultLocale).format(d);

/// `4850` → `₱4,850`.
String formatPeso(int amount) {
  final digits = amount.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return '${amount < 0 ? '-' : ''}₱$buf';
}

/// `Nov 14`.
String formatShortDate(DateTime d) => '${_month(d)} ${d.day}';

/// `Thu, Nov 14`.
String formatDayDate(DateTime d) => '${weekdayShort(d)}, ${formatShortDate(d)}';

/// `Thu`.
String weekdayShort(DateTime d) => _weekday(d);

/// `Nov 14 – 17`, or `Nov 30 – Dec 2` across months.
String formatDateRange(DateTime start, DateTime end) {
  if (start.month == end.month && start.year == end.year) {
    return '${formatShortDate(start)} – ${end.day}';
  }
  return '${formatShortDate(start)} – ${formatShortDate(end)}';
}

/// `06:40` → `6:40 AM`, `13:10` → `1:10 PM`.
String formatTeeTime(String hhmm) {
  final parts = hhmm.split(':');
  final h = int.parse(parts[0]);
  final suffix = h < 12 ? 'AM' : 'PM';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${parts[1]} $suffix';
}

/// Like [formatTeeTime], keeping a day marker: `01:10+1` → `1:10 AM +1`,
/// `23:00-1` → `11:00 PM -1`.
String formatClock(String hhmm) {
  if (!hhmm.endsWith('+1') && !hhmm.endsWith('-1')) return formatTeeTime(hhmm);
  return '${formatTeeTime(hhmm.substring(0, hhmm.length - 2))} ${hhmm.substring(hhmm.length - 2)}';
}

/// `1` → `1 night`, `3` → `3 nights`.
String plural(int n, String one, [String? many]) => '$n ${n == 1 ? one : (many ?? '${one}s')}';

/// Date with the time of day dropped.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// "직항" or "1회 경유", in the language the app is rendering.
///
/// Shared rather than kept with the flights feature: the flight card and the trips booking
/// card both show it, and each had its own English literal, so a Korean screen said "Nonstop"
/// in two different widgets. A helper two features read belongs to neither of them — the
/// architecture validator refuses the alternative, and is right to.
///
/// V2's own `flights_card_direct` carries the nonstop word. The count needs a mobile key
/// because V2 holds the noun alone (`"stop"` / `"stops"`) and a number cannot be joined to it
/// the same way in every language: "1 stop" takes a space where "1회 경유" does not.
String stopsLabel(AppLocalizations t, int stops) =>
    stops == 0 ? t.flights_card_direct : t.mobile_flights_stopsCount(stops);

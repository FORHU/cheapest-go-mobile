import 'package:intl/intl.dart';

import 'package:cheapest_go_mobile/features/flights/models/flight_fare.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';

/// V2's `flight-utils.ts`, line for line where it matters.

/// An OFFER's clock, in **Local Airport Time**.
///
/// The digits in the string are the answer: a provider quotes a flight the way a boarding pass
/// does, 08:15 at the gate it leaves from, with no offset attached. Parsing it into a DateTime
/// would make the handset guess a zone and print a departure hours off.
String formatTime(String? iso) {
  if (iso == null) return '--:--';
  final m = RegExp(r'T(\d{2}):(\d{2})').firstMatch(iso);
  if (m == null) return '--:--';
  final hour = int.tryParse(m.group(1)!);
  if (hour == null || hour > 23) return '--:--';
  return '${hour.toString().padLeft(2, '0')}:${m.group(2)}';
}

/// The calendar day of an offer's time, its digits kept as written. Null when unreadable.
DateTime? offerDay(String? iso) {
  if (iso == null || iso.length < 10) return null;
  final p = iso.substring(0, 10).split('-').map(int.tryParse).toList();
  if (p.length != 3 || p.contains(null)) return null;
  return DateTime.utc(p[0]!, p[1]!, p[2]!);
}

/// "Wed, Oct 14, 2026" — `formatFlightDate`.
String formatFlightDate(String? iso, {String? locale}) {
  final d = offerDay(iso);
  return d == null ? '' : DateFormat.yMMMEd(locale ?? 'en_US').format(d);
}

/// "Wed, Oct 14, 2026, 18:40" — `formatDateTime`.
String formatDateTime(String? iso, {String? locale}) {
  final date = formatFlightDate(iso, locale: locale);
  return date.isEmpty ? '' : '$date, ${formatTime(iso)}';
}

/// Whole calendar days between two Local Airport Times — the "+1".
int dayOffset(String? from, String? to) {
  final a = offerDay(from);
  final b = offerDay(to);
  if (a == null || b == null) return 0;
  final days = b.difference(a).inDays;
  return days < 0 ? 0 : days;
}

String formatDuration(int? minutes, {AppLocalizations? t}) {
  if (minutes == null || minutes <= 0) return '';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (t != null) {
    return h > 0
        ? t.flights_durationParts_hoursMinutes(h, m)
        : t.flights_durationParts_minutesOnly(m);
  }
  return h > 0 ? '${h}h ${m}m' : '${m}m';
}

// `cabinLabel` was here: it title-cased the raw cabin code into English, beside this function
// which says the same thing in the app's own language. Two ways to name one thing is how the
// flight card came to print "Economy" on a Korean screen. There is one now.

String cabinName(AppLocalizations t, String cabin) => switch (cabin) {
  'premium_economy' => t.landing_search_cabinClass_premiumEconomy,
  'business' => t.landing_search_cabinClass_business,
  'first' => t.landing_search_cabinClass_first,
  _ => t.landing_search_cabinClass_economy,
};

/// "Hamad International Airport (DOH)", or the bare code when the provider named none.
String airportLabel(SegmentEnd? end, String fallbackCode) {
  final code = (end?.airport.isNotEmpty ?? false) ? end!.airport : fallbackCode;
  final name = end?.airportName;
  return name != null && name.isNotEmpty && name != code
      ? '$name ($code)'
      : code;
}

/// Minutes on the ground between two legs, both clocks read at the same airport.
int? layoverMinutes(String? arrival, String? departure) {
  DateTime? read(String? iso) {
    if (iso == null || iso.length < 16) return null;
    return DateTime.tryParse('${iso.substring(0, 16)}:00Z');
  }

  final a = read(arrival);
  final d = read(departure);
  if (a == null || d == null || !d.isAfter(a)) return null;
  return d.difference(a).inMinutes;
}

/// The offer's directions in `segmentIndex` order; `index` keys `sliceDurations`.
List<({int index, List<FlightSegment> segments})> groupSegmentsBySlice(
  List<FlightSegment> segments,
) {
  final map = <int, List<FlightSegment>>{};
  for (final s in segments) {
    map.putIfAbsent(s.segmentIndex, () => []).add(s);
  }
  final keys = map.keys.toList()..sort();
  return [for (final k in keys) (index: k, segments: map[k]!)];
}

/// A plural message from V2's copy with its count written in.
///
/// V2's ICU messages print the number with `#` — "{count, plural, one {# flight} other {# flights}}"
/// — which next-intl fills in and Flutter's gen_l10n does not: the generated method returns
/// "# flights found". Until `tools/sync_design.dart` rewrites `#` to the plural's variable, every
/// plural this feature shows goes through here.
String withCount(String message, num count) =>
    message.replaceAll('#', NumberFormat.decimalPattern('en_US').format(count));

/// `Intl.NumberFormat('en-US', { style: 'currency', maximumFractionDigits: 0 })`.
String formatPrice(num amount, String currency) => NumberFormat.simpleCurrency(
  locale: 'en_US',
  name: currency.toUpperCase(),
  decimalDigits: 0,
).format(amount);

/// V2's checkout `formatMoney`: "PHP 8,108.79" — the code, then the figure to the currency's own
/// minor units (none for yen and won, two for most).
String checkoutMoney(num amount, String currency) {
  final code = currency.toUpperCase();
  final digits =
      NumberFormat.simpleCurrency(locale: 'en_US', name: code).decimalDigits ??
      2;
  final figure = NumberFormat.decimalPatternDigits(
    locale: 'en_US',
    decimalDigits: digits,
  ).format(amount);
  return '$code $figure';
}

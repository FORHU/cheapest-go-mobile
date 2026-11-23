/// Display formatting for prices, dates, and tee times.
library;

import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

import 'package:cheapest_go_mobile/shared/lib/env.dart';
import 'package:cheapest_go_mobile/shared/utils/currency.dart';
import 'package:cheapest_go_mobile/shared/utils/money.dart';

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

/// A catalogue price in the currency the brand charges: `4850` → `₩119,000`.
///
/// The catalogue is priced in pesos — `catalogCurrency` is PHP — and this used to print the
/// number with a ₱ in front of it and no conversion at all. On AirangGo, which charges in
/// won and says so everywhere else, the golf list quoted every green fee in a currency the
/// traveller is never billed in and the hotel beside it quoted won.
///
/// Converted rather than relabelled: writing ₩ in front of 6,200 would have been worse than
/// the peso, because it would have been wrong by a factor of twenty rather than merely
/// foreign. When the rates are not loaded `convertForDisplay` returns the amount in its
/// original currency and this prints that, which is the honest answer while it waits.
String formatCatalogPrice(num amount) {
  final shown = exchangeRates.convertForDisplay(
    amount,
    catalogCurrency,
    brandCurrency,
  );
  return formatMoney(shown.amount, shown.currency);
}

/// The same figure with no currency symbol, for a map pin that has no room for one.
///
/// The two callers used to take [formatCatalogPrice] and strip the `₱` back off with a
/// `replaceFirst`. That worked only while the symbol was always a peso: the moment the price
/// is converted the symbol is a won, the strip finds nothing, and the pin reads "₩119,000"
/// in a label sized for five digits.
String formatCatalogAmount(num amount) {
  final shown = exchangeRates.convertForDisplay(
    amount,
    catalogCurrency,
    brandCurrency,
  );
  return NumberFormat.decimalPattern('en_US').format(shown.amount.round());
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

/// `06:40` → `6:40 AM` in English, `오전 6:40` in Korean.
///
/// The AM and PM were written here as English literals, so a Korean golf screen listed every
/// tee time as "6:40 AM" — and in Korean the marker goes *before* the clock, which no amount
/// of translating the two words would have fixed. `DateFormat.jm` knows both the words and
/// where they belong, and takes its language from `Intl.defaultLocale` like the dates above.
String formatTeeTime(String hhmm) {
  final parts = hhmm.split(':');
  final h = int.parse(parts[0]);
  final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
  // The date is a carrier for the clock and never read: only hour and minute are formatted.
  final formatted = DateFormat.jm(
    Intl.defaultLocale,
  ).format(DateTime(2000, 1, 1, h, m));

  // CLDR separates the clock from AM/PM with a narrow no-break space (U+202F). It looks the
  // same on screen and is not the same character, which makes every `find.text('6:40 AM')`
  // and every string comparison fail for a reason nothing in the diff shows — the expected
  // and the actual print identically. Normalised to a plain space so what is on the screen
  // is what the code can be written against.
  return formatted.replaceAll(' ', ' ').replaceAll(' ', ' ');
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

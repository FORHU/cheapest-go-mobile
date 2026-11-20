import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:cheapest_go_mobile/shared/utils/format.dart';

/// Dates read in the language the app is set to.
///
/// They used to come from two const English arrays, so an app rendering Korean still wrote
/// "Nov 28 – 29" in the middle of Korean copy — which is how this was found, on a phone.
void main() {
    setUpAll(() async => initializeDateFormatting());
    tearDown(() => Intl.defaultLocale = null);

    final nov28 = DateTime(2026, 11, 28);

    test('English when nothing has chosen otherwise', () {
        // Unset is how the tests run, and why every other date expectation still passes.
        Intl.defaultLocale = null;
        expect(formatShortDate(nov28), 'Nov 28');
    });

    test('Korean when the app is Korean', () {
        Intl.defaultLocale = 'ko';
        final out = formatShortDate(nov28);
        expect(out, isNot(contains('Nov')), reason: 'the English month leaked through');
        expect(out, contains('11'), reason: 'Korean writes the month as a number');
    });

    test('the weekday follows too', () {
        Intl.defaultLocale = 'ko';
        expect(weekdayShort(nov28), isNot(anyOf('Sat', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sun')));
    });

    test('a range in Korean carries no English month', () {
        Intl.defaultLocale = 'ko';
        expect(formatDateRange(nov28, DateTime(2026, 12, 2)), isNot(contains('Dec')));
    });

    test('Japanese and Chinese are carried too, not just Korean', () {
        for (final locale in ['ja', 'zh']) {
            Intl.defaultLocale = locale;
            expect(() => formatShortDate(nov28), returnsNormally, reason: '$locale has no date symbols loaded');
        }
    });
}

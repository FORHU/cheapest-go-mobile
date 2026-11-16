import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/shared/lib/countries.dart';

/// The country list behind the nationality picker. See #62.
///
/// Nationality used to be a two-letter box somebody typed into, which asks every traveller to
/// know their own ISO code. The list is what replaced it, and the stored value is still the
/// code — `duffelIdentityDocuments` in api-v2 needs that form or it drops a passport silently.
void main() {
  test('every code is a well-formed ISO alpha-2', () {
    // The same shape api-v2 enforces. A malformed entry here would be refused on save, and
    // only by the one traveller who picked it.
    for (final code in kCountriesByCode.keys) {
      expect(RegExp(r'^[A-Z]{2}$').hasMatch(code), isTrue, reason: '$code is not alpha-2');
      expect(kCountriesByCode[code]!.trim(), isNotEmpty, reason: '$code has no name');
    }
  });

  test('the list is big enough to be the real one', () {
    // A truncated list looks fine until somebody's country is not in it.
    expect(kCountriesByCode.length, greaterThan(200));
  });

  test('sorted by name for the picker', () {
    final names = kCountriesByName.map((e) => e.value).toList();
    expect(names, orderedEquals(List.of(names)..sort()));
  });

  group('search', () {
    test('finds a country by name, however it is capitalised', () {
      expect(searchCountries('philippines').map((e) => e.key), contains('PH'));
      expect(searchCountries('PHILIPPINES').map((e) => e.key), contains('PH'));
    });

    test('finds a country by part of its name', () {
      // "korea" should find both, whichever way each is listed.
      final korea = searchCountries('korea').map((e) => e.key).toList();
      expect(korea, containsAll(['KR', 'KP']));
    });

    test('finds a country by code', () {
      expect(searchCountries('jp').first.key, 'JP');
    });

    test('a code match is anchored at the start', () {
      // Typing "in" should offer India and Indonesia, not every country with "in" buried in
      // its code. The name match is what legitimately widens it.
      final codes = searchCountries('in').map((e) => e.key).toList();
      expect(codes, contains('IN'));
      expect(codes, contains('ID'), reason: 'Indonesia matches on its name');
    });

    test('an empty query is the whole list, not nothing', () {
      expect(searchCountries('').length, kCountriesByCode.length);
      expect(searchCountries('   ').length, kCountriesByCode.length);
    });

    test('a query that matches nothing returns nothing rather than everything', () {
      expect(searchCountries('zzzzz'), isEmpty);
    });
  });

  _dialling();

  group('naming a stored code', () {
    test('gives the country name', () {
      expect(countryName('PH'), 'Philippines');
      expect(countryName('ph'), 'Philippines', reason: 'case should not matter');
    });

    test('falls back to the code rather than going blank', () {
      // The list moves. An account saved with a code this build has never heard of should
      // still show something.
      expect(countryName('ZZ'), 'ZZ');
    });
  });
}

/// The dialling prefixes that fill the phone field when a nationality is picked. See #62.
void _dialling() {
  group('dialling codes', () {
    test('every country has one, well formed', () {
      for (final code in kCountriesByCode.keys) {
        final dial = kCallingCodeByCountry[code];
        expect(dial, isNotNull, reason: '$code has no dialling code');
        expect(RegExp(r'^\+\d{1,4}$').hasMatch(dial!), isTrue, reason: '$code has "$dial"');
      }
    });

    test('the ones this product actually serves', () {
      expect(callingCode('PH'), '+63');
      expect(callingCode('KR'), '+82');
      expect(callingCode('JP'), '+81');
      expect(callingCode('CN'), '+86');
      expect(callingCode('US'), '+1');
    });

    test('shared prefixes are left shared', () {
      // +1 really does cover North America and much of the Caribbean. Normalising that away
      // would mean inventing prefixes that do not exist.
      expect(callingCode('CA'), '+1');
      expect(callingCode('US'), '+1');
      expect(callingCode('KZ'), '+7');
      expect(callingCode('RU'), '+7');
    });

    test('an unknown country gives nothing rather than a guess', () {
      // A wrong prefix is worse than none: it reads as something the app knew, and the rest
      // of the number gets typed after it.
      expect(callingCode('ZZ'), '');
    });

    test('case does not matter', () {
      expect(callingCode('ph'), '+63');
    });
  });
}

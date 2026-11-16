import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The strings this app owns, which V2 has no original for. See #62 and ADR-0005.
///
/// `tools/sync_design.dart` rebuilds each ARB from V2's locale JSON and writes the whole file,
/// which is right for mirrored copy — a string deleted in V2 should vanish here too — and
/// fatal for a screen V2 does not have. Onboarding is that screen, because mobile requires an
/// account and the web does not.
///
/// The generator carries these keys across a rebuild. This fails if that stops working, which
/// would otherwise show up as four untranslated screens at the one moment nobody can skip.
void main() {
  const locales = ['en', 'ja', 'ko', 'zh'];

  const onboardingKeys = [
    'onboarding_title',
    'onboarding_step',
    'onboarding_preferences_title',
    'onboarding_preferences_subtitle',
    'onboarding_details_title',
    'onboarding_details_subtitle',
    'onboarding_birthDate',
    'onboarding_phone',
    'onboarding_nationality',
    'onboarding_continue',
    'onboarding_skip',
    'onboarding_finish',
    'onboarding_saveFailed',
    'onboarding_birthDateFormat',
    'onboarding_birthDateReal',
    'onboarding_birthDateFuture',
    'onboarding_phoneFormat',
    'onboarding_nationalityFormat',
  ];

  Map<String, dynamic> arb(String locale) =>
      jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync()) as Map<String, dynamic>;

  for (final locale in locales) {
    test('$locale carries every onboarding string', () {
      final file = arb(locale);
      for (final key in onboardingKeys) {
        expect(file.containsKey(key), isTrue, reason: '$locale lost $key — did a sync wipe it?');
        expect(
          (file[key] as String).trim(),
          isNotEmpty,
          reason: '$locale has $key but it is blank',
        );
      }
    });
  }

  test('the translations are translations, not four copies of the English', () {
    // A sync that dropped the keys and a lazy re-add both leave the file "present"; only the
    // content tells them apart. Checked on the headline, which is the first thing read.
    final english = arb('en')['onboarding_title'] as String;
    for (final locale in ['ja', 'ko', 'zh']) {
      expect(
        arb(locale)['onboarding_title'],
        isNot(english),
        reason: '$locale is showing the English string',
      );
    }
  });

  test('the step counter keeps its placeholders in every language', () {
    // `onboarding_step` takes {current} and {total}. A translation that dropped one would
    // compile and then render "Step of 2" to the one audience least able to query it.
    for (final locale in locales) {
      final message = arb(locale)['onboarding_step'] as String;
      expect(message, contains('{current}'), reason: '$locale lost {current}');
      expect(message, contains('{total}'), reason: '$locale lost {total}');
    }
  });

  test('the generator is told these keys are ours', () {
    // The carry works off a prefix list. If a prefix comes off it, the keys above survive
    // only until the next sync — so the list itself is part of the contract.
    final source = File('tools/sync_design.dart').readAsStringSync();
    for (final prefix in ['onboarding_', 'coach_']) {
      expect(
        source,
        contains("'$prefix'"),
        reason: 'the $prefix prefix is no longer protected from a rebuild',
      );
    }
  });

  test('the first-run tour carries its copy in every language too', () {
    // Same reasoning as onboarding: the web has no tour, so `sync_design` has no original to
    // rebuild these from and would drop them.
    const coachKeys = [
      'coach_step',
      'coach_next',
      'coach_done',
      'coach_skip',
      'coach_faces_title',
      'coach_faces_body',
      'coach_search_title',
      'coach_search_body',
      'coach_bar_title',
      'coach_bar_body',
    ];

    for (final locale in locales) {
      final file = arb(locale);
      for (final key in coachKeys) {
        expect(file.containsKey(key), isTrue, reason: '$locale lost $key');
        expect((file[key] as String).trim(), isNotEmpty, reason: '$locale has $key but blank');
      }
      final step = file['coach_step'] as String;
      expect(step, contains('{current}'), reason: '$locale lost {current}');
      expect(step, contains('{total}'), reason: '$locale lost {total}');
    }
  });
}

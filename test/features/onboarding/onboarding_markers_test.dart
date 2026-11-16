import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/features/onboarding/lib/onboarding_markers.dart';

/// Reading what the account owes out of its preferences. See #62 and ADR-0005.
///
/// The same three states api-v2 writes, read from the other end. The "neither marker" case is
/// the one worth guarding: every account that existed before this shipped looks like that, and
/// reading it as unfinished would wall all of them out of an app they already use.
void main() {
  group('status', () {
    test('a new account owes onboarding', () {
      final markers = OnboardingMarkers.fromPreferences({
        'onboarding': {'startedAt': '2026-11-16T02:00:00.000Z'},
      });
      expect(markers.status, OnboardingStatus.required);
    });

    test('a finished account owes nothing', () {
      final markers = OnboardingMarkers.fromPreferences({
        'onboarding': {
          'startedAt': '2026-11-16T02:00:00.000Z',
          'completedAt': '2026-11-16T02:04:00.000Z',
        },
      });
      expect(markers.status, OnboardingStatus.completed);
    });

    test('an account from before onboarding existed is grandfathered', () {
      // What every existing row looks like: preferences the web wrote, and no markers.
      expect(
        OnboardingMarkers.fromPreferences({'displayCurrency': 'PHP'}).status,
        OnboardingStatus.notRequired,
      );
      expect(OnboardingMarkers.fromPreferences({}).status, OnboardingStatus.notRequired);
      expect(OnboardingMarkers.fromPreferences(null).status, OnboardingStatus.notRequired);
    });

    test('a completion without a start still counts as finished', () {
      // Should not happen, and if it does the traveller has answered the questions. Asking
      // again because a marker is missing would be the app arguing with itself.
      expect(
        OnboardingMarkers.fromPreferences({
          'onboarding': {'completedAt': '2026-11-16T02:04:00.000Z'},
        }).status,
        OnboardingStatus.completed,
      );
    });
  });

  group('malformed preferences', () {
    test('read as nothing stated rather than throwing', () {
      // Preferences are a blob the web may replace wholesale, so this is reachable, and the
      // safe reading is the one that lets somebody into the app rather than trapping them.
      for (final value in ['yes', 123, ['started'], null]) {
        expect(
          OnboardingMarkers.fromPreferences({'onboarding': value}).status,
          OnboardingStatus.notRequired,
          reason: 'onboarding: $value should not be taken as a marker',
        );
      }
    });

    test('an empty string is not a marker', () {
      expect(
        OnboardingMarkers.fromPreferences({
          'onboarding': {'startedAt': ''},
        }).status,
        OnboardingStatus.notRequired,
      );
    });
  });

  group('writing the completion', () {
    test('carries the start through rather than dropping it', () {
      // The start was written by api-v2 at account creation. Losing it on the way back would
      // leave a row that reads as grandfathered.
      final markers = OnboardingMarkers.fromPreferences({
        'onboarding': {'startedAt': '2026-11-16T02:00:00.000Z'},
      });

      final written = markers.completedNow(now: DateTime.utc(2026, 11, 16, 2, 4));

      expect(written['startedAt'], '2026-11-16T02:00:00.000Z');
      expect(written['completedAt'], '2026-11-16T02:04:00.000Z');
    });

    test('a grandfathered account that somehow finishes writes only the completion', () {
      final written = OnboardingMarkers().completedNow(now: DateTime.utc(2026, 11, 16, 2, 4));

      expect(written.containsKey('startedAt'), isFalse);
      expect(written['completedAt'], '2026-11-16T02:04:00.000Z');
    });

    test('what is written reads back as finished', () {
      final markers = OnboardingMarkers.fromPreferences({
        'onboarding': {'startedAt': '2026-11-16T02:00:00.000Z'},
      });
      final round = OnboardingMarkers.fromPreferences({'onboarding': markers.completedNow()});

      expect(round.status, OnboardingStatus.completed);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/app/router/auth_gate.dart';
import 'package:cheapest_go_mobile/features/onboarding/lib/onboarding_markers.dart';

/// The gate: no account, no app. See #62 and ADR-0005.
///
/// This is the one place mobile deliberately parts company with V2, which gates only `/admin`.
/// These cases are the ones that would catch somebody quietly relaxing it, and the two holes
/// that have to stay open: a reset link is opened by somebody who cannot sign in, and the
/// sign-in screen's own copy links to the Terms.
void main() {
  // The rule is a pure function, so each case states the whole world it is asked about: who is
  // signed in, and what the account owes. Nothing is left over from the case before.
  String? out(String path) => gateRedirect(path, isAuthenticated: false, onboarding: OnboardingStatus.unknown);
  String? inApp(String path, OnboardingStatus status) =>
      gateRedirect(path, isAuthenticated: true, onboarding: status);

  group('signed out', () {
    test('the app itself is refused', () {
      for (final path in ['/', '/stay', '/trips', '/hotels', '/profile', '/checkout']) {
        expect(out(path), '/login', reason: '$path should be behind the gate');
      }
    });

    test('the way in stays open', () {
      for (final path in ['/login', '/register', '/forgot-password']) {
        expect(out(path), isNull, reason: '$path is how somebody gets an account');
      }
    });

    test('a reset link is reachable, query string and all', () {
      // Opened from an email by somebody who by definition cannot sign in. Bouncing this to
      // the sign-in screen would strand them with a link that goes nowhere.
      expect(out('/reset-password?token=abc123'), isNull);
    });

    test('a failed Google round trip has somewhere to land', () {
      expect(out('/auth/auth-code-error'), isNull);
    });

    test('the legal documents are readable before signing up', () {
      // The sign-in screen says "By signing in you agree to our Terms and Privacy". A link
      // that bounces back to sign-in is a dead end.
      for (final path in ['/terms', '/privacy', '/cookies', '/refund']) {
        expect(out(path), isNull, reason: '$path must be readable before an account exists');
      }
    });

    test('help and about are not open', () {
      // Deliberate, and the narrow list is the point: every open path is a hole in the gate.
      expect(out('/help'), '/login');
      expect(out('/about'), '/login');
    });
  });

  group('signed in, onboarding owed', () {
    test('nothing but onboarding', () {
      for (final path in ['/', '/trips', '/profile', '/help']) {
        expect(inApp(path, OnboardingStatus.required), '/onboarding', reason: '$path should not be reachable mid-onboarding');
      }
    });

    test('onboarding itself is allowed', () {
      expect(inApp('/onboarding', OnboardingStatus.required), isNull);
    });

    test('the legal documents stay reachable', () {
      // Somebody being asked for their date of birth may reasonably want to read the privacy
      // policy first, and that is not a way around the flow.
      expect(inApp('/privacy', OnboardingStatus.required), isNull);
    });
  });

  group('signed in, nothing owed', () {
    test('a finished account goes straight in', () {
      expect(inApp('/', OnboardingStatus.completed), isNull);
      expect(inApp('/trips', OnboardingStatus.completed), isNull);
    });

    test('an account from before onboarding existed goes straight in', () {
      // Grandfathered: neither marker. Reading this as "not onboarded" would wall every
      // existing traveller out of an app they already use.
      expect(inApp('/', OnboardingStatus.notRequired), isNull);
    });

    test('onboarding cannot be revisited', () {
      expect(inApp('/onboarding', OnboardingStatus.completed), '/');
    });

    test('sign-in and register have nothing left to offer', () {
      expect(inApp('/login', OnboardingStatus.completed), '/');
      expect(inApp('/register', OnboardingStatus.completed), '/');
    });
  });

  group('signed in, answer not back yet', () {
    test('holds rather than guessing', () {
      // Both guesses are wrong in an expensive way, so it waits. A spinner for one request
      // beats walling an existing traveller out or waving a new one past the flow.
      expect(inApp('/', OnboardingStatus.unknown), '/starting');
      expect(inApp('/trips', OnboardingStatus.unknown), '/starting');
      expect(inApp('/starting', OnboardingStatus.unknown), isNull);
    });
  });
}

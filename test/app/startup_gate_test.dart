import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/app/router/auth_gate.dart';
import 'package:cheapest_go_mobile/features/onboarding/lib/onboarding_markers.dart';

/// The splash is not a courtesy, it is the only honest answer while the app is still waking.
///
/// Everything the gate asks about is read from stores that `AppStartup` is still filling: a
/// token not yet loaded reads as signed out, and an account that owes nothing reads the same
/// as one nobody has asked about. Routing on either before they are filled sends a signed-in
/// traveller to the sign-in form — the bug this rule exists to stop.
void main() {
  String? starting(String path, {required bool isAuthenticated}) => gateRedirect(
    path,
    isAuthenticated: isAuthenticated,
    onboarding: OnboardingStatus.unknown,
    starting: true,
  );

  test('while starting, every route is the splash', () {
    for (final path in ['/', '/trips', '/hotels', '/onboarding', '/checkout']) {
      expect(starting(path, isAuthenticated: false), splashPath, reason: path);
    }
  });

  test('an Open Screen is no exception while starting', () {
    // Sign-in especially: a session being restored reads as signed out until it is back,
    // and bouncing somebody to the form they do not need is the whole failure.
    expect(starting('/login', isAuthenticated: false), splashPath);
    expect(starting('/terms', isAuthenticated: false), splashPath);
  });

  test('the splash itself is where it is allowed to stay', () {
    expect(starting(splashPath, isAuthenticated: false), isNull);
    expect(starting(splashPath, isAuthenticated: true), isNull);
  });

  test('once started, the gate answers as it always did', () {
    // Not starting is the default, so every existing rule is asked the same question it was
    // asked before this one existed.
    expect(
      gateRedirect(
        '/',
        isAuthenticated: false,
        onboarding: OnboardingStatus.unknown,
      ),
      '/login',
    );
    expect(
      gateRedirect(
        '/',
        isAuthenticated: true,
        onboarding: OnboardingStatus.completed,
      ),
      isNull,
    );
    expect(
      gateRedirect(
        splashPath,
        isAuthenticated: true,
        onboarding: OnboardingStatus.completed,
      ),
      '/',
      reason: 'nothing left to wait for, so the splash is left behind',
    );
  });
}

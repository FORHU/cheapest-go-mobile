import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:cheapest_go_mobile/app/startup.dart';
import 'package:cheapest_go_mobile/features/auth/stores/auth_store.dart';
import 'package:cheapest_go_mobile/features/onboarding/lib/onboarding_markers.dart';
import 'package:cheapest_go_mobile/features/onboarding/stores/onboarding_store.dart';
import 'package:cheapest_go_mobile/shared/tips/tip_store.dart';

/// Nothing but the Open Screens is reachable without an account. See #62 and ADR-0005.
///
/// This is the one place mobile deliberately does not follow V2, which gates only `/admin` and
/// lets a signed-out visitor search freely. The reasoning, and what it costs, is in the ADR —
/// it is not an oversight and it is not a thing to quietly relax.
///
/// The gate is a router redirect rather than a check on each screen: a screen that guards
/// itself is a screen somebody can forget to guard, and every route added after this one would
/// be open by default.

/// Paths reachable with no account at all — **Open Screens** in CONTEXT.md.
///
/// The auth screens, because they are the way through the gate. `/reset-password` especially:
/// it is opened from an email by somebody who by definition cannot sign in, and
/// `/auth/auth-code-error` catches a Google round trip that failed.
///
/// The four legal documents, because the sign-in screen's own copy links to the Terms and the
/// Privacy policy — a link that bounces back to sign-in is a dead end — and because a policy
/// has to be readable before somebody creates an account.
///
/// Each entry is a hole in the gate. Adding one needs the same kind of reason these have.
const Set<String> openPaths = {
  '/login',
  '/register',
  '/forgot-password',
  '/reset-password',
  '/auth/auth-code-error',
  '/terms',
  '/privacy',
  '/cookies',
  '/refund',
};

/// Where onboarding happens. Open to a signed-in account that still owes it, and to nobody else.
const String onboardingPath = '/onboarding';

bool _isOpen(String location) {
  final path = Uri.parse(location).path;
  return openPaths.contains(path);
}

/// The redirect the router asks on every navigation.
///
/// Returns null to allow, or the path to go to instead. Four questions in order, and the order
/// is the point: an unknown onboarding status must not be mistaken for "not required".
///
/// Takes the two states rather than reading the stores, so the rule can be asked every
/// question in a test without a signed-in app around it. [routerGateRedirect] is what the
/// router actually calls.
String? gateRedirect(
  String location, {
  required bool isAuthenticated,
  required OnboardingStatus onboarding,
  bool starting = false,
}) {
  final path = Uri.parse(location).path;

  // 0. Still starting: the splash, whoever is signed in and whatever they owe. Both of the
  //    answers below are read from stores that [AppStartup] is still filling — a token not
  //    yet loaded reads as signed out, and sign-in is the wrong place to send somebody whose
  //    session is simply not back yet. Defaults to false so the rule can be asked about the
  //    four states that follow without a running app.
  if (starting) return path == splashPath ? null : splashPath;

  // 1. No account: only the Open Screens, and sign-in is where everything else lands.
  if (!isAuthenticated) {
    return _isOpen(location) ? null : '/login';
  }

  // 2. Signed in and already at an Open Screen: let them read it. Somebody signed in may still
  //    want the Terms, and bouncing them off would be strange.
  if (_isOpen(location)) {
    // ...except sign-in and register, which have nothing left to offer an account that exists.
    return (path == '/login' || path == '/register') ? '/' : null;
  }

  // 3. Onboarding owed: nothing but onboarding, which is what "cannot bypass" means.
  switch (onboarding) {
    case OnboardingStatus.required:
      return path == onboardingPath ? null : onboardingPath;
    case OnboardingStatus.unknown:
      // The answer has not arrived. Hold on the splash rather than guess: one guess walls an
      // existing traveller out of an app they already use, the other waves a new one past a
      // flow they have to finish.
      return path == splashPath ? null : splashPath;
    case OnboardingStatus.completed:
    case OnboardingStatus.notRequired:
      // 4. Finished or never needed: the app, and never onboarding again.
      return (path == onboardingPath || path == splashPath) ? '/' : null;
  }
}

/// What the router calls: the rule above, asked about the live stores.
String? routerGateRedirect(String location) => gateRedirect(
      location,
      isAuthenticated: authStore.isAuthenticated,
      onboarding: onboardingStore.status,
      starting: !appStartup.ready,
    );

/// Shown only while the onboarding status is unknown — the moment between a session being
/// restored and the server answering what it owes.
const String splashPath = '/starting';

/// Wakes the router when either store changes.
///
/// Two stores and not one because they answer different questions and change at different
/// times: being signed in is about this device holding a token, owing onboarding is about what
/// the account's preferences say. A single listener on either would leave the gate stale after
/// the other moved.
class GateListenable extends ChangeNotifier {
  GateListenable(this._sources) {
    for (final source in _sources) {
      source.addListener(notifyListeners);
    }
  }

  final List<Listenable> _sources;

  @override
  void dispose() {
    for (final source in _sources) {
      source.removeListener(notifyListeners);
    }
    super.dispose();
  }
}

/// Keeps the onboarding answer in step with who is signed in.
///
/// Signing in asks the server what this account owes; signing out forgets it, because the next
/// account is a different question and a stale "completed" would wave a brand-new traveller
/// straight past onboarding.
void wireGateToAuth() {
  var wasAuthenticated = authStore.isAuthenticated;

  authStore.addListener(() {
    final isAuthenticated = authStore.isAuthenticated;
    if (isAuthenticated == wasAuthenticated) return;
    wasAuthenticated = isAuthenticated;

    if (isAuthenticated) {
      unawaited(onboardingStore.load());
      // Which Tips this account has seen lives with the account too, so a second person on
      // a shared phone is offered help rather than inheriting somebody else's Skip.
      unawaited(tipStore.load());
    } else {
      onboardingStore.reset();
      tipStore.reset();
    }
  });

  // A session restored from storage at launch signs the user in before anything listens, so
  // the first answer has to be asked for here rather than waited for.
  if (authStore.isAuthenticated) {
    unawaited(onboardingStore.load());
    unawaited(tipStore.load());
  }
}

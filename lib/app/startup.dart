import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'package:cheapest_go_mobile/app/router/auth_gate.dart';
import 'package:cheapest_go_mobile/app/support_chat.dart';
import 'package:cheapest_go_mobile/features/auth/stores/auth_store.dart';
import 'package:cheapest_go_mobile/shared/flights/offline_route_maps.dart';
import 'package:cheapest_go_mobile/shared/lib/env.dart';
import 'package:cheapest_go_mobile/shared/lib/token.dart';
import 'package:cheapest_go_mobile/shared/stores/bookings_store.dart';
import 'package:cheapest_go_mobile/shared/stores/ui_store.dart';

const _kMapboxToken = String.fromEnvironment(
  'MAPBOX_PUBLIC_TOKEN',
  defaultValue: String.fromEnvironment('MAPBOX_ACCESS_TOKEN'),
);

/// Everything that has to be true before any screen is worth showing.
///
/// This used to be awaited in `main()` before `runApp`, which meant the handset sat on the
/// Android launch window — the app's own first frame came after the last await. Nothing was
/// wrong with it, but nothing could be shown either: no brand, no sign of life, and on a slow
/// cold start no way to tell a loading app from a stuck one.
///
/// Now it runs behind the app's own splash. The gate holds every route on that splash until
/// [ready], so moving work after `runApp` does not let a screen open before the thing it
/// depends on exists — the Stripe key before checkout, the Mapbox token before a map, the
/// stored language before a word of copy is drawn.
///
/// Deliberately not a list of stores to poll: the order here matters, and a phase that reads
/// what the one before it wrote is easier to keep right as a sequence than as a graph.
class AppStartup extends ChangeNotifier {
  bool _ready = false;
  bool _running = false;
  Object? _error;

  /// The app may show its screens.
  bool get ready => _ready;

  /// The last attempt did not finish. The splash offers to try again.
  bool get failed => _error != null;

  /// Declares the phases done without running them.
  ///
  /// For tests about what comes *after* the splash. [run] reaches Stripe, Mapbox and the
  /// stored session — in a mock build the last of those signs the demo user in — so a test
  /// asking "which screen does the app open on" would be answering a different question if
  /// it ran the real thing.
  @visibleForTesting
  void markReady() {
    _ready = true;
    _error = null;
    notifyListeners();
  }

  Future<void> run() async {
    if (_running || _ready) return;
    _running = true;
    _error = null;
    notifyListeners();

    try {
      // Month and weekday names for every locale the app carries. Without this, formatting a
      // date in anything but English throws LocaleDataException the first time it is asked.
      await initializeDateFormatting();

      if (_kMapboxToken.isNotEmpty) {
        MapboxOptions.setAccessToken(_kMapboxToken);
      }

      // The publishable key only: it identifies the account to Stripe and can do nothing on
      // its own. Amounts are set by api-v2 against its secret key, so a client cannot name a
      // price. Without a key the checkout says so rather than failing at the moment somebody
      // taps Pay.
      if (env.stripePublishableKey.isNotEmpty) {
        Stripe.publishableKey = env.stripePublishableKey;
        await Stripe.instance.applySettings();
      }

      await tokenStorage.init();
      await uiSettingsStore.init();
      await bookingsStore.init();

      // Keeps the gate's onboarding answer in step with who is signed in. Wired before the
      // session is restored, so the sign-in that restoring produces is one this is listening
      // for.
      wireGateToAuth();

      // Support Chat opens to an account that is through the gate, and forgets it on
      // sign-out. Wired here for the same reason: before the restore it has to hear.
      wireSupportChat();

      // Neither is awaited, and neither may be: a session is validated against a server that
      // might be slow or absent, and offline maps are a download. Holding the splash on
      // either would be holding it on the network. The gate has its own answer for a session
      // still being checked — see `OnboardingStatus.unknown`.
      authStore.restoreSession();
      offlineRouteMaps.refresh(bookingsStore.flights);

      _ready = true;
    } catch (error) {
      // Kept rather than rethrown: an exception on a background future has nowhere to go but
      // the console, and the traveller would be left on a logo that never moves. The splash
      // reads `failed` and offers the only useful thing, which is to try again.
      _error = error;
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}

final AppStartup appStartup = AppStartup();

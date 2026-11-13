import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:cheapest_go_mobile/app/app.dart';
import 'package:cheapest_go_mobile/features/auth/stores/auth_store.dart';
import 'package:cheapest_go_mobile/shared/flights/offline_route_maps.dart';
import 'package:cheapest_go_mobile/shared/lib/env.dart';
import 'package:cheapest_go_mobile/shared/lib/token.dart';
import 'package:cheapest_go_mobile/shared/stores/bookings_store.dart';
import 'package:cheapest_go_mobile/shared/stores/saved_store.dart';
import 'package:cheapest_go_mobile/shared/stores/ui_store.dart';

const _kMapboxToken = String.fromEnvironment(
  'MAPBOX_PUBLIC_TOKEN',
  defaultValue: String.fromEnvironment('MAPBOX_ACCESS_TOKEN'),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_kMapboxToken.isNotEmpty) {
    MapboxOptions.setAccessToken(_kMapboxToken);
  }
  // The publishable key only: it identifies the account to Stripe and can do nothing on its
  // own. Amounts are set by api-v2 against its secret key, so a client cannot name a price.
  // Without a key the checkout says so rather than failing at the moment someone taps Pay.
  if (env.stripePublishableKey.isNotEmpty) {
    Stripe.publishableKey = env.stripePublishableKey;
    await Stripe.instance.applySettings();
  }
  await tokenStorage.init();
  await uiSettingsStore.init();
  await savedStaysStore.init();
  await bookingsStore.init();
  bookingsStore.seedDemoHistory();
  // Download offline route maps for flights leaving soon; never blocks start-up.
  offlineRouteMaps.refresh(bookingsStore.flights);
  // Fire-and-forget session validation on startup
  authStore.restoreSession();
  runApp(const CheapestGoApp());
}

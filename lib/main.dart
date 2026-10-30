import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:cheapest_go_mobile/app/app.dart';
import 'package:cheapest_go_mobile/features/auth/stores/auth_store.dart';
import 'package:cheapest_go_mobile/features/trips/views/trips_view.dart';
import 'package:cheapest_go_mobile/shared/lib/token.dart';
import 'package:cheapest_go_mobile/shared/stores/ui_store.dart';

const _kMapboxToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_kMapboxToken.isNotEmpty) {
    MapboxOptions.setAccessToken(_kMapboxToken);
  }
  await tokenStorage.init();
  await uiSettingsStore.init();
  await savedHotelsStore.init();
  // Fire-and-forget session validation on startup
  authStore.restoreSession();
  runApp(const CheapestGoApp());
}

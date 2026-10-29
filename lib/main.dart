import 'package:flutter/material.dart';
import 'package:cheapest_go_mobile/app/app.dart';
import 'package:cheapest_go_mobile/features/auth/stores/auth_store.dart';
import 'package:cheapest_go_mobile/features/trips/views/trips_view.dart';
import 'package:cheapest_go_mobile/shared/lib/token.dart';
import 'package:cheapest_go_mobile/shared/stores/ui_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await tokenStorage.init();
  await uiSettingsStore.init();
  await savedHotelsStore.init();
  // Fire-and-forget session validation on startup
  authStore.restoreSession();
  runApp(const CheapestGoApp());
}

import 'package:flutter/material.dart';
import 'package:cheapest_go_mobile/app/router/app_router.dart';
import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/shared/flights/offline_route_maps.dart';
import 'package:cheapest_go_mobile/shared/stores/bookings_store.dart';
import 'package:cheapest_go_mobile/shared/stores/ui_store.dart';

class CheapestGoApp extends StatefulWidget {
  const CheapestGoApp({super.key});

  @override
  State<CheapestGoApp> createState() => _CheapestGoAppState();
}

class _CheapestGoAppState extends State<CheapestGoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back in the app (say, the evening before a flight): top up offline maps.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) offlineRouteMaps.refresh(bookingsStore.flights);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: uiSettingsStore,
      builder: (context, _) {
        return MaterialApp.router(
          title: 'CheapestGo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: uiSettingsStore.themeMode,
          routerConfig: appRouter,
        );
      },
    );
  }
}


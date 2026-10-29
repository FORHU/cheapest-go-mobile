import 'package:flutter/material.dart';
import 'package:cheapest_go_mobile/app/router/app_router.dart';
import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/shared/stores/ui_store.dart';

class CheapestGoApp extends StatelessWidget {
  const CheapestGoApp({super.key});

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


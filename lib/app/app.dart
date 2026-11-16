import 'package:flutter/material.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/app/router/app_router.dart';
import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/shared/coachmarks/coach_mark_overlay.dart';
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

          // V2's own copy, mirrored at the Design Pin. See docs/adr/0002.
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,

          // The chosen language, never the handset's, and English until somebody chooses.
          // That default mirrors V2 rather than the platform: there the locale lives in the
          // URL and defaults to English, with no cookie and no Accept-Language negotiation,
          // so a Korean browser gets English too. Onboarding is where it is first chosen
          // (#62); the account screen is where it is changed afterwards.
          locale: Locale(uiSettingsStore.language),

          routerConfig: appRouter,

          // The first-run tour sits above every screen rather than inside Home, so it can
          // point at the bottom bar — which belongs to the shell, not to any one page — and
          // so it survives the tab switches it is describing. See #63.
          //
          // `builder` and not a wrapper around the router: this is the one place that is
          // inside the MaterialApp, and therefore has localisations and a Directionality,
          // while still being outside every route.
          builder: (context, child) => CoachMarkOverlay(
            marks: coachMarksFor(AppLocalizations.of(context)!),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}


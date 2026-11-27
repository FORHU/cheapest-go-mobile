import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/lib/env.dart';
import 'package:cheapest_go_mobile/app/router/app_router.dart';
import 'package:cheapest_go_mobile/app/support_chat.dart';
import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/features/support/components/support_widget.dart';
import 'package:cheapest_go_mobile/shared/tips/tip_overlay.dart';
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
    if (state == AppLifecycleState.resumed) {
      offlineRouteMaps.refresh(bookingsStore.flights);
      // The OS has very likely cut the chat's stream while the app was away.
      supportChatStore.resumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: uiSettingsStore,
      builder: (context, _) {
        // Dates are formatted by plain functions in shared/utils/format.dart, which have no
        // BuildContext to read a locale from; intl reads this global instead. Set here rather
        // than once at startup because the language can change while the app is running, and
        // this builder is exactly what re-runs when it does.
        Intl.defaultLocale = uiSettingsStore.language;

        return MaterialApp.router(
          title: brandName,
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

          // Home's Tip lives here rather than inside Home, because it points at the bottom
          // bar — which belongs to the shell, not to any one page. Every other screen wraps
          // itself; a Tip belongs to the screen it explains. See #62 and ADR-0006.
          //
          // `builder` and not a wrapper around the router: this is the one place that is
          // inside the MaterialApp, and therefore has localisations and a Directionality,
          // while still being outside every route.
          builder: (context, child) => TipScope(
            tip: homeTip(AppLocalizations.of(context)!),
            child: SupportLayer(child: child ?? const SizedBox.shrink()),
          ),
        );
      },
    );
  }
}


/// Support Chat over every screen, as V2 mounts its widget in the locale layout (#60).
///
/// Here rather than in the tab shell because V2 shows it on every page — a hotel, a checkout,
/// a booking — not only on the three the bar reaches. Its own [Overlay] because it sits above
/// the router's, and the composer's text field needs one for its selection handles.
class SupportLayer extends StatelessWidget {
  const SupportLayer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (context) => Stack(
            children: [
              Positioned.fill(child: child),
              ListenableBuilder(
                listenable: Listenable.merge([popupsShowing, bottomBarHeight]),
                builder: (context, _) => SupportWidget(
                  store: supportChatStore,
                  visible: popupsShowing.value == 0,
                  bottomBar: bottomBarHeight.value,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

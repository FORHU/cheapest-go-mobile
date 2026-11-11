import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cheapest_go_mobile/app/router/app_router.dart';
import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';

/// 390 × 844 logical pixels, the size the design is drawn at.
void usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// The full app with a fresh router, starting at [location].
///
/// Carries the localisation delegates because the app does: since #35 the screens take their
/// words from V2's own translations, so a harness without them is not the app — every screen
/// that reads a string throws on a null `AppLocalizations`.
Future<void> pumpApp(WidgetTester tester, {String location = '/', ThemeData? theme}) async {
  usePhoneViewport(tester);
  final router = createAppRouter();
  addTearDown(router.dispose);
  router.go(location);
  await tester.pumpWidget(MaterialApp.router(
    theme: theme ?? AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    routerConfig: router,
  ));
  await tester.pumpAndSettle();
}

/// One screen, in the app's chrome. For tests that mount a view directly rather than routing
/// to it — they need the same delegates for the same reason.
Future<void> pumpScreen(WidgetTester tester, Widget screen, {ThemeData? theme}) async {
  usePhoneViewport(tester);
  await tester.pumpWidget(MaterialApp(
    theme: theme ?? AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: screen),
  ));
  await tester.pumpAndSettle();
}

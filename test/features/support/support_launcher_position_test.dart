import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:go_router/go_router.dart';

import 'package:cheapest_go_mobile/app/router/app_router.dart';
import 'package:cheapest_go_mobile/app/router/v2_bottom_nav.dart';
import 'package:cheapest_go_mobile/app/support_chat.dart';
import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/features/support/components/support_widget.dart';
import 'package:cheapest_go_mobile/features/support/stores/support_chat_store.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';

/// Where the support launcher sits, on a screen with a bottom bar and on one without.
///
/// V2 clears the bar with a flat 92 pixels because every page on the web has one. Mobile
/// pushes `/hotels`, `/hotel/:id` and both checkouts outside the shell, and on those the same
/// constant parked the button in the middle of empty space — "it should sit bottom right
/// whatever the device is".
SupportChatStore _store() => SupportChatStore(
      locale: () => 'en',
      pickFile: () async => null,
      openUrl: (_) async {},
    )..setEnabled(true);

Future<double> _bottomOf(
  WidgetTester tester, {
  required double bar,
  double safeBottom = 0,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: MediaQuery(
        data: MediaQueryData(viewPadding: EdgeInsets.only(bottom: safeBottom)),
        child: Scaffold(
          body: Stack(
            children: [SupportWidget(store: _store(), visible: true, bottomBar: bar)],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return tester.widget<Positioned>(find.byType(Positioned).first).bottom!;
}

void main() {
  _wiring();

  testWidgets('clears the bottom bar where there is one, as V2 does', (tester) async {
    final bottom = await _bottomOf(tester, bar: V2BottomNav.barHeight);

    // 68 + 24, which is V2's 92 — written as the sum so the bar can change height without
    // the launcher sliding onto it.
    expect(bottom, V2BottomNav.barHeight + SupportWidget.overBar);
    expect(bottom, 92);
  });

  /// The one this is for. `/hotels` has no bar, and the button was floating a bar's height
  /// above a bottom edge that has nothing on it.
  testWidgets('sits at the edge on a screen with no bar', (tester) async {
    final bottom = await _bottomOf(tester, bar: 0);

    expect(bottom, SupportWidget.overEdge);
    expect(bottom, lessThan(V2BottomNav.barHeight));
  });

  /// Whatever the clearance, the home indicator is below it and not under the button.
  testWidgets('rides above the home indicator on either kind of screen', (tester) async {
    expect(await _bottomOf(tester, bar: 0, safeBottom: 34),
        SupportWidget.overEdge + 34);
    expect(await _bottomOf(tester, bar: V2BottomNav.barHeight, safeBottom: 34),
        V2BottomNav.barHeight + SupportWidget.overBar + 34);
  });
}

/// The other half: that something actually tells the launcher a bar is there.
///
/// The shell is the only thing that does, because it is the only thing that has one. A route
/// declared beside it rather than inside it — `/hotels` is one — takes the shell down with it,
/// and the launcher has to notice.
void _wiring() {
  testWidgets('the shell reports its bar, and a route outside it reports none', (tester) async {
    addTearDown(() => bottomBarHeight.value = 0);

    final key = GlobalKey<NavigatorState>();
    final router = GoRouter(
      navigatorKey: key,
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => MainScaffoldShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(
              routes: [GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('home')))],
            ),
          ],
        ),
        // As `/hotels` is declared: beside the shell, not within it.
        GoRoute(path: '/hotels', builder: (_, _) => const Scaffold(body: Text('stays'))),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      routerConfig: router,
    ));
    await tester.pumpAndSettle();

    expect(bottomBarHeight.value, V2BottomNav.barHeight);

    router.go('/hotels');
    await tester.pumpAndSettle();
    expect(bottomBarHeight.value, 0, reason: 'nothing down there to clear');

    router.go('/');
    await tester.pumpAndSettle();
    expect(bottomBarHeight.value, V2BottomNav.barHeight);
  });
}

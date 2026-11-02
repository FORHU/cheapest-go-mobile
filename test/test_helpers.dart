import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cheapest_go_mobile/app/router/app_router.dart';
import 'package:cheapest_go_mobile/app/theme/app_theme.dart';

/// 390 × 844 logical pixels, the size the design is drawn at.
void usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// The full app with a fresh router, starting at [location].
Future<void> pumpApp(WidgetTester tester, {String location = '/', ThemeData? theme}) async {
  usePhoneViewport(tester);
  final router = createAppRouter();
  addTearDown(router.dispose);
  router.go(location);
  await tester.pumpWidget(MaterialApp.router(theme: theme ?? AppTheme.light, routerConfig: router));
  await tester.pumpAndSettle();
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cheapest_go_mobile/app/app.dart';

/// The splash draws no logo, and that is the point.
///
/// Android shows the launcher icon itself while the app starts — `windowSplashScreenAnimatedIcon`
/// from API 31, `@drawable/launch_background` before it — so anything drawn here is the brand a
/// second time. It was drawn here once, matched to the launch window at 108dp on the theory that
/// identical frames hand over invisibly. On an Android 16 handset they did not: the system scales
/// its icon into a 240dp canvas, so its pass was large and soft and this one was small and sharp,
/// and the two read as the logo twice at different sizes.
///
/// The background stays, because a white that does not change is what makes the handover
/// invisible, and the spinner stays, because a cold start slow enough to be noticed should say
/// something is happening.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the splash adds no second logo', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const CheapestGoApp());
    await tester.pump();

    expect(
      find.byType(Image),
      findsNothing,
      reason: 'the system has already shown the icon',
    );

    // Centred, so the one thing on the screen is where the eye already is.
    final spinner = find.byType(CircularProgressIndicator);
    expect(spinner, findsOneWidget);
    expect(
      tester.getCenter(spinner),
      tester.getCenter(find.byType(MaterialApp)),
    );

    // The same white the launch window is painted. A different one here would be the flash
    // the launch window exists to prevent.
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, const Color(0xFFFFFFFF));
  });
}

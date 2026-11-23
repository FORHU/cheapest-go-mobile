import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cheapest_go_mobile/app/app.dart';

/// The splash is the first thing the app shows, so it has to be right at rest: the brand
/// centred on the screen, not merely somewhere on it.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the brand sits in the middle of the splash', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const CheapestGoApp());
    await tester.pump();

    // One image, and it is the launcher icon's own foreground. The job of this screen is to
    // continue the Android launch window, not to introduce a second piece of artwork: the
    // window is already showing this, so anything else here is a swap mid-launch.
    final icon = find.byType(Image);
    expect(icon, findsOneWidget);

    // Dead centre of the screen, both axes. The launch window is the whole window, system
    // bars included, so its centre is the screen's — inset this and the icon hops at the
    // handover, which is the one thing it must not do.
    expect(tester.getCenter(icon), tester.getCenter(find.byType(MaterialApp)));

    // 108dp, which is what an adaptive icon's foreground measures in every density bucket
    // and therefore what the launch window draws at 1:1.
    expect(tester.getSize(icon), const Size(108, 108));

    // The spinner shares the icon's centre line and sits below it, which is the only way it
    // can be there without pushing the icon off the middle.
    final spinner = tester.getCenter(find.byType(CircularProgressIndicator));
    final middle = tester.getCenter(find.byType(MaterialApp));
    expect(spinner.dx, middle.dx);
    expect(spinner.dy, greaterThan(middle.dy + 54));
  });
}

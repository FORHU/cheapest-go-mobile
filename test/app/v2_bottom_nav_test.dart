import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/app/router/v2_bottom_nav.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/chrome_skin.dart';
import '../test_helpers.dart';

/// V2's bar, reproduced. See #36 and ADR-0001.
void main() {
    group('the bar itself', () {
        testWidgets('is three slots, named but unlabelled', (tester) async {
            await tester.pumpWidget(MaterialApp(
                home: Scaffold(
                    bottomNavigationBar: V2BottomNav(
                        activeIndex: 0,
                        onHome: () {},
                        onTrips: () {},
                        onSettings: () {},
                    ),
                ),
            ));

            for (final name in ['Home', 'Trips', 'Settings']) {
                expect(find.bySemanticsLabel(name), findsOneWidget);
                expect(find.text(name), findsNothing, reason: 'V2 draws icons only');
            }
            expect(find.byType(Icon), findsNWidgets(3));
        });

        /// The active slot is the only one that changes colour, and the colour is bronze
        /// rather than the blue of the token layer — a deliberate, contrast-tuned choice that
        /// `palette.ts` does not carry. See chrome_skin.dart before "correcting" it.
        testWidgets('marks the active slot in the skin\'s bronze', (tester) async {
            await tester.pumpWidget(MaterialApp(
                theme: ThemeData(brightness: Brightness.light),
                home: Scaffold(
                    bottomNavigationBar: V2BottomNav(
                        activeIndex: 1,
                        onHome: () {},
                        onTrips: () {},
                        onSettings: () {},
                    ),
                ),
            ));

            final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
            expect(icons[1].color, ChromeSkin.light.active);
            expect(icons[0].color, ChromeSkin.light.icon);
            expect(icons[2].color, ChromeSkin.light.icon);
        });

        testWidgets('takes its skin from the brightness', (tester) async {
            await tester.pumpWidget(MaterialApp(
                theme: ThemeData(brightness: Brightness.dark),
                home: Scaffold(
                    bottomNavigationBar: V2BottomNav(
                        activeIndex: 0,
                        onHome: () {},
                        onTrips: () {},
                        onSettings: () {},
                    ),
                ),
            ));

            final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
            expect(icons[0].color, ChromeSkin.dark.active);
            expect(icons[1].color, ChromeSkin.dark.icon);
        });

        testWidgets('each slot reports which it is', (tester) async {
            var home = 0, trips = 0, settings = 0;
            await tester.pumpWidget(MaterialApp(
                home: Scaffold(
                    bottomNavigationBar: V2BottomNav(
                        activeIndex: 0,
                        onHome: () => home++,
                        onTrips: () => trips++,
                        onSettings: () => settings++,
                    ),
                ),
            ));

            await tester.tap(find.bySemanticsLabel('Trips'));
            await tester.tap(find.bySemanticsLabel('Settings'));
            expect([home, trips, settings], [0, 1, 1]);
        });
    });

    group('in the app', () {
        /// V2's gear opens a sheet rather than navigating, and lights while it is open.
        testWidgets('the gear opens the account surface as a sheet', (tester) async {
            await pumpApp(tester);

            await tester.tap(find.descendant(
                of: find.byType(V2BottomNav),
                matching: find.bySemanticsLabel('Settings'),
            ));
            await tester.pumpAndSettle();

            expect(find.text('Settings'), findsOneWidget, reason: 'the sheet names itself');
            expect(find.text('App Theme'), findsOneWidget, reason: 'the account surface is inside');

            await tester.tap(find.byTooltip('Close settings'));
            await tester.pumpAndSettle();
            expect(find.text('App Theme'), findsNothing);
        });

        /// The thing ADR-0001 is about: no slot reaches the map any more.
        testWidgets('offers no way to the map', (tester) async {
            await pumpApp(tester);

            expect(find.bySemanticsLabel('Map'), findsNothing);
            expect(find.byIcon(Icons.public_rounded), findsNothing);
        });
    });
}

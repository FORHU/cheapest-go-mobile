import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/features/home/views/home_view.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';

/// Every face of the Stage has to survive being opened on a phone.
///
/// The Flights face did not: its two trip-type cards were a `Row` with
/// `CrossAxisAlignment.stretch` inside a scrolling `Column`, so they were asked to be
/// infinitely tall and the frame threw. On a device that reads as the app freezing — the
/// half-painted frame stays on screen, taps do nothing, and it looks like a design bug.
/// Nothing tapped these tabs before, which is why it reached a phone at all.
void main() {
    Future<void> pumpHome(WidgetTester tester) async {
        tester.view.physicalSize = const Size(390 * 3, 844 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.light,
            home: const Scaffold(body: HomeView()),
        ));
        await tester.pump();
    }

    for (final face in ['Stays', 'Flights', 'Golf']) {
        testWidgets('the $face face opens without throwing', (tester) async {
            await pumpHome(tester);

            await tester.tap(find.text(face));
            await tester.pump();

            expect(tester.takeException(), isNull);
        });
    }

    testWidgets('a promoted place is picked without asking the endpoint', (tester) async {
        // V2's `pickTile` sets the destination outright. Looking it up instead left a tapped
        // tile reading "No places match Seoul" whenever the destinations endpoint was
        // unreachable — which is every build that has no API_URL.
        await pumpHome(tester);

        await tester.tap(find.text('Seoul'));
        await tester.pump();

        expect(find.textContaining('No places match'), findsNothing);
        // Answered, so the step can be left: V2 names the step you are going to.
        expect(find.text('Next: dates'), findsOneWidget);
        await tester.tap(find.text('Next: dates'));
        await tester.pump();

        // On the dates step, and nothing threw on the way — the footer wraps rather than
        // overflowing once "Back" sits beside the next button.
        expect(find.text('When'), findsOneWidget);
        expect(tester.takeException(), isNull);
    });

    testWidgets('Flights opens on its trip-type cards', (tester) async {
        await pumpHome(tester);

        await tester.tap(find.text('Flights'));
        await tester.pump();

        // V2's own copy: `search.oneWay` and `search.roundTrip`, hyphenated.
        expect(find.text('One-way'), findsOneWidget);
        expect(find.text('Round-trip'), findsOneWidget);
    });
}

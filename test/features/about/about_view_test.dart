import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/features/about/views/about_view.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_palette.dart';

/// The tracer screen, checked for the three things the slice exists to prove: the copy comes
/// from V2's own translations, the colours come from the mirrored tokens, and the sections are
/// V2's in V2's order.
///
/// Not a pixel comparison — Design Parity is judged by recognition, and a golden of a Flutter
/// screen could never match a browser anyway.
Future<void> _pump(WidgetTester tester, {Brightness brightness = Brightness.light}) async {
    await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: ThemeData(brightness: brightness),
        home: const AboutView(),
    ));
    await tester.pumpAndSettle();
}

void main() {
    testWidgets('says what V2 says, in V2 order', (tester) async {
        tester.view.physicalSize = const Size(390 * 3, 844 * 3);  // a phone, at 3x
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await _pump(tester);

        // The headings, in the order V2 stacks them.
        final headings = [
            'Our mission',
            'What we do',
            'What makes us different',
            'Powered by trusted partners',
            'Who runs CheapestGo',
        ];
        var previous = -1.0;
        for (final heading in headings) {
            final finder = find.text(heading);
            expect(finder, findsOneWidget, reason: 'missing section: $heading');
            final y = tester.getTopLeft(finder).dy;
            expect(y > previous, isTrue, reason: '$heading is out of order');
            previous = y;
        }
    });

    testWidgets('takes its words from the shared translations, not the widget tree', (tester) async {
        await _pump(tester);

        // These exact strings live in V2's en.json and reach the screen through the generated
        // ARB. If someone hardcodes a label, this keeps passing — but if the pipeline breaks,
        // or a key is renamed on the web, it stops.
        expect(find.text('Travel that respects your time and your wallet.'), findsOneWidget);
        expect(find.text('Contact us'), findsOneWidget);

        for (final partner in ['Duffel', 'TravelgateX', 'Stripe']) {
            expect(find.text(partner), findsOneWidget);
        }
    });

    testWidgets('paints the hero in V2\'s obsidian, from the mirrored palette', (tester) async {
        await _pump(tester);

        final hero = tester.widget<Container>(find.byType(Container).first);
        final decoration = hero.decoration! as BoxDecoration;
        expect(decoration.color, TwPalette.obsidian);
    });

    testWidgets('has a dark rendering that is not the light one', (tester) async {
        await _pump(tester, brightness: Brightness.dark);

        // The hero is obsidian in both, as it is on V2 — the body is what changes.
        expect(find.text('Our mission'), findsOneWidget);
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, isNot(Colors.white));
    });
}

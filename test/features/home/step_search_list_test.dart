import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/features/home/views/home_view.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/search/destinations_api.dart';

/// How much of the answer a traveller can reach.
///
/// The picker drew three rows. That was a sensible panel size while it only offered places,
/// and became a filter once it offered properties too: "new york" matched three hotels named
/// after the city — Las Vegas, Johor Bahru, Barcelona — and New York itself, which the API had
/// returned, was cut off the end of a list with nothing to scroll.
///
/// Two things have to hold at once and they pull against each other. Everything the API offers
/// has to be reachable, and the panel still has to leave the field and the button on a phone
/// with its keyboard up. So the list is bounded and scrolls, rather than short.
class _ManyPlaces extends DestinationsApi {
    @override
    Future<List<DestinationSuggestion>> search(
        String query, {
        bool forFlights = false,
        int limit = 8,
    }) async =>
        List.generate(
            8,
            (i) => DestinationSuggestion(
                id: 'place.$i',
                kind: DestinationKind.city,
                name: 'Place $i',
                city: 'Subtitle $i',
                countryCode: 'PH',
            ),
        );
}

void main() {
    late DestinationsApi original;

    setUp(() {
        original = destinationsApi;
        destinationsApi = _ManyPlaces();
    });

    tearDown(() => destinationsApi = original);

    const height = 844.0;
    const keyboard = 340.0;
    const fold = height - keyboard;

    Future<void> typeInto(WidgetTester tester, String query) async {
        tester.view.physicalSize = const Size(390 * 3, height * 3);
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

        await tester.tap(find.byType(TextField));
        tester.view.viewInsets = const FakeViewPadding(bottom: keyboard * 3);
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), query);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
    }

    testWidgets('offers more than a screenful, and lets the rest be scrolled to',
        (tester) async {
        await typeInto(tester, 'place');

        // The first rows are drawn. The last is not — that is the point of bounding it.
        expect(find.text('Subtitle 0'), findsOneWidget);
        expect(find.text('Subtitle 7'), findsNothing);

        // And it is reachable, which three fixed rows never made it.
        await tester.drag(find.text('Subtitle 0'), const Offset(0, -260));
        await tester.pumpAndSettle();
        expect(find.text('Subtitle 7'), findsOneWidget);
    });

    testWidgets('does not grow until it pushes the field behind the keyboard',
        (tester) async {
        await typeInto(tester, 'place');

        // The regression a taller list would reintroduce: the panel eats the stage, and what
        // was typed goes under the keyboard with it.
        expect(tester.getRect(find.byType(TextField)).bottom, lessThanOrEqualTo(fold));

        // The first suggestion is still something the traveller can see and tap.
        expect(tester.getRect(find.text('Subtitle 0')).bottom, lessThanOrEqualTo(fold));
    });
}

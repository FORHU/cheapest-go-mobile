import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/features/home/views/home_view.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/search/destinations_api.dart';

/// What a traveller can actually see while they are typing.
///
/// Reported from a handset: typing "Manila" on the Where step put the matching places behind
/// the keyboard. Nothing said so — no scrollbar, no cut-off row — so the screen read as a
/// search box that had stopped answering, and the only way through was to dismiss the
/// keyboard and discover the list had been there all along.
///
/// The property is not "something scrolled". It is that the places are above the keyboard,
/// which is why this measures where they are drawn rather than the scroll offset.
class _StubApi extends DestinationsApi {
    @override
    Future<List<DestinationSuggestion>> search(
        String query, {
        bool forFlights = false,
        int limit = 8,
    }) async =>
        const [
            DestinationSuggestion(
                id: 'place.1057971',
                kind: DestinationKind.city,
                name: 'Manila',
                city: 'Manila, Philippines',
                countryCode: 'PH',
            ),
        ];
}

void main() {
    late DestinationsApi original;

    setUp(() {
        original = destinationsApi;
        destinationsApi = _StubApi();
    });

    tearDown(() => destinationsApi = original);

    /// A tall phone with a keyboard that takes the bottom 340 of it — roughly what a Galaxy
    /// shows. Everything below y = 504 is behind the keyboard.
    const height = 844.0;
    const keyboard = 340.0;
    const fold = height - keyboard;

    testWidgets('the places stay above the keyboard', (tester) async {
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

        // The keyboard comes up with the focus, so both are set before anything is measured.
        await tester.tap(find.byType(TextField));
        tester.view.viewInsets = const FakeViewPadding(bottom: keyboard * 3);
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Manila');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        final place = find.text('Manila, Philippines');
        expect(place, findsOneWidget, reason: 'the lookup answered');

        final rect = tester.getRect(place);
        expect(
            rect.bottom,
            lessThanOrEqualTo(fold),
            reason: 'a place drawn below $fold is behind the keyboard, which is the bug',
        );

        // And the field itself is still on screen — scrolling the answer into view must not
        // take what was typed with it, or the reader cannot tell which query these match.
        expect(tester.getRect(find.byType(TextField)).bottom, lessThanOrEqualTo(fold));
    });
}

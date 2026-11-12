import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/features/home/views/home_view.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/search/destinations_api.dart';

/// A lookup already on its way when a place is picked must not land. See #39.
///
/// What happened on a handset: typing "Manila" started a lookup, the suggestions from the
/// keystroke before it were already on screen, and tapping one picked the place — then the
/// lookup came back and captioned the chosen place "No places match Manila". The choice was
/// still made, so the state was both answered and contradicted.
class _SlowApi extends DestinationsApi {
    _SlowApi();

    final pending = <Completer<List<DestinationSuggestion>>>[];

    @override
    Future<List<DestinationSuggestion>> search(
        String query, {
        bool forFlights = false,
        int limit = 8,
    }) {
        final completer = Completer<List<DestinationSuggestion>>();
        pending.add(completer);
        return completer.future;
    }
}

void main() {
    late DestinationsApi original;
    late _SlowApi api;

    setUp(() {
        original = destinationsApi;
        api = _SlowApi();
        destinationsApi = api;
    });

    tearDown(() => destinationsApi = original);

    testWidgets('a reply that arrives after the pick is dropped', (tester) async {
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

        // Typed, and the first lookup answers with the place.
        await tester.enterText(find.byType(TextField), 'Manil');
        await tester.pump(const Duration(milliseconds: 300));
        expect(api.pending, hasLength(1));
        api.pending.first.complete(const [
            DestinationSuggestion(
                id: 'place.1057971',
                kind: DestinationKind.city,
                name: 'Manila',
                city: 'Manila, Philippines',
                countryCode: 'PH',
            ),
        ]);
        await tester.pump();
        expect(find.text('Manila, Philippines'), findsOneWidget);

        // One more keystroke starts a second lookup, which is still in flight.
        await tester.enterText(find.byType(TextField), 'Manila');
        await tester.pump(const Duration(milliseconds: 300));
        expect(api.pending, hasLength(2));

        // The place is picked while that lookup is out.
        await tester.tap(find.text('Manila, Philippines'));
        await tester.pump();

        // It comes back empty — a rate limit, a dropped connection, anything.
        api.pending.last.complete(const []);
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.textContaining('No places match'), findsNothing);
        expect(find.textContaining('selected'), findsOneWidget);
    });
}

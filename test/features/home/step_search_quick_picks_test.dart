import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/features/home/views/home_view.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/search/destinations_api.dart';
import 'package:cheapest_go_mobile/shared/search/recent_destinations.dart';

/// What the Where step offers before anything is typed, and what it keeps when a lookup fails.
///
/// The field used to answer an empty query with four photographs and nothing else, while the
/// web stepper had been offering recent searches and trending places all along — two pickers
/// for the same job, disagreeing about what exists.
class _StubApi extends DestinationsApi {
    _StubApi({this.trendingCities = const [], this.result});

    final List<String> trendingCities;

    /// `null` is a lookup that failed. That is the case worth a test: it used to be
    /// indistinguishable from "no such place".
    final List<DestinationSuggestion>? result;

    @override
    Future<List<DestinationSuggestion>?> search(
        String query, {
        bool forFlights = false,
        int limit = 8,
    }) async =>
        result;

    @override
    Future<List<DestinationSuggestion>> trending() async => [
            for (final c in trendingCities)
                DestinationSuggestion(id: c, kind: DestinationKind.city, name: c, city: 'Somewhere'),
        ];
}

DestinationSuggestion _city(String name) =>
    DestinationSuggestion(id: name, kind: DestinationKind.city, name: name, city: '$name, Testland');

void main() {
    TestWidgetsFlutterBinding.ensureInitialized();

    late DestinationsApi originalApi;
    late RecentDestinations originalRecent;

    setUp(() {
        SharedPreferences.setMockInitialValues({});
        originalApi = destinationsApi;
        originalRecent = recentDestinations;
    });

    tearDown(() {
        destinationsApi = originalApi;
        recentDestinations = originalRecent;
    });

    Future<void> openWhere(WidgetTester tester) async {
        tester.view.physicalSize = const Size(390 * 3, 900 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.light,
            home: const Scaffold(body: HomeView()),
        ));
        await tester.pumpAndSettle();
    }

    testWidgets('offers trending places before anything is typed', (tester) async {
        destinationsApi = _StubApi(trendingCities: const ['Osaka', 'Hanoi']);

        await openWhere(tester);

        expect(find.widgetWithText(ActionChip, 'Osaka'), findsOneWidget);
        expect(find.widgetWithText(ActionChip, 'Hanoi'), findsOneWidget);
    });

    testWidgets('offers somewhere searched before, ahead of what is trending', (tester) async {
        recentDestinations = RecentDestinations();
        await recentDestinations.remember('Vigan');
        destinationsApi = _StubApi(trendingCities: const ['Osaka']);

        await openWhere(tester);

        final chips = tester.widgetList<ActionChip>(find.byType(ActionChip)).toList();
        expect((chips.first.label as Text).data, 'Vigan');
        expect(chips.map((c) => (c.label as Text).data), contains('Osaka'));
    });

    /// A chip reading "Seoul" directly above a photograph of Seoul is two answers to one
    /// question. The tiles are fixed, so the chips give way.
    testWidgets('never offers a place the tiles below already show', (tester) async {
        destinationsApi = _StubApi(trendingCities: const ['Seoul', 'Osaka']);

        await openWhere(tester);

        expect(find.widgetWithText(ActionChip, 'Seoul'), findsNothing);
        expect(find.widgetWithText(ActionChip, 'Osaka'), findsOneWidget);
    });

    testWidgets('picking a chip answers the step without looking it up', (tester) async {
        // The stub would answer every lookup with null, so a chip that searched for its own
        // city would come back empty — which is the bug this guards.
        destinationsApi = _StubApi(trendingCities: const ['Osaka'], result: null);

        await openWhere(tester);
        await tester.tap(find.widgetWithText(ActionChip, 'Osaka'));
        await tester.pumpAndSettle();

        expect(find.text('Osaka'), findsWidgets);
        expect(find.byType(ActionChip), findsNothing, reason: 'the question is answered');
    });

    testWidgets('a failed lookup leaves the places already listed alone', (tester) async {
        destinationsApi = _StubApi(result: [_city('Cebu'), _city('Cebu City')]);

        await openWhere(tester);
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'ceb');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(find.text('Cebu City'), findsOneWidget);

        // The next keystroke's lookup fails outright.
        destinationsApi = _StubApi(result: null);
        await tester.enterText(find.byType(TextField), 'cebu');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(find.text('Cebu City'), findsOneWidget,
            reason: 'a dropped request is not evidence the places are wrong');
    });
}

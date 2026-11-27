import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/features/home/components/stage_chrome.dart';
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

        expect(find.widgetWithText(GlassPill, 'Osaka'), findsOneWidget);
        expect(find.widgetWithText(GlassPill, 'Hanoi'), findsOneWidget);
    });

    testWidgets('offers somewhere searched before, ahead of what is trending', (tester) async {
        recentDestinations = RecentDestinations();
        await recentDestinations.remember('Vigan');
        destinationsApi = _StubApi(trendingCities: const ['Osaka']);

        await openWhere(tester);

        final chips = tester.widgetList<GlassPill>(find.byType(GlassPill)).toList();
        expect(chips.first.label, 'Vigan');
        expect(chips.map((c) => c.label), contains('Osaka'));
    });

    /// A chip reading "Seoul" directly above a photograph of Seoul is two answers to one
    /// question. The tiles are fixed, so the chips give way.
    testWidgets('never offers a place the tiles below already show', (tester) async {
        destinationsApi = _StubApi(trendingCities: const ['Seoul', 'Osaka']);

        await openWhere(tester);

        expect(find.widgetWithText(GlassPill, 'Seoul'), findsNothing);
        expect(find.widgetWithText(GlassPill, 'Osaka'), findsOneWidget);
    });

    testWidgets('picking a chip answers the step without looking it up', (tester) async {
        // The stub would answer every lookup with null, so a chip that searched for its own
        // city would come back empty — which is the bug this guards.
        destinationsApi = _StubApi(trendingCities: const ['Osaka'], result: null);

        await openWhere(tester);
        await tester.tap(find.widgetWithText(GlassPill, 'Osaka'));
        await tester.pumpAndSettle();

        expect(find.text('Osaka'), findsWidgets);
        expect(find.widgetWithText(GlassPill, 'Osaka'), findsNothing,
            reason: 'the question is answered, so it is no longer being asked');
    });

    /// What shipped: two blank white boxes where the chips should be.
    ///
    /// `ActionChip` builds its surface as a `MaterialType.canvas` with no colour of its own,
    /// which paints `ThemeData.canvasColor` — and this app sets that to the page background.
    /// The `backgroundColor` the chips passed was an 8% white painted *on top* of an already
    /// white pill, and the white label and white icon then had nowhere to show. Nothing a chip
    /// exposes reaches that Material, so the fix was to stop using one.
    testWidgets('a chip is not painted with the page background', (tester) async {
        destinationsApi = _StubApi(trendingCities: const ['Osaka']);

        await openWhere(tester);

        final canvas = AppTheme.light.canvasColor;
        final surfaces = tester.widgetList<Material>(
            find.descendant(of: find.byType(GlassPill), matching: find.byType(Material)),
        );
        expect(surfaces, isNotEmpty);
        for (final m in surfaces) {
            final painted = m.color ?? (m.type == MaterialType.canvas ? canvas : null);
            expect(painted, isNot(canvas),
                reason: 'the pill sits on a photograph, not on the page');
        }

        // And it does carry a fill of its own, rather than relying on whatever is behind it.
        final box = tester.widget<Container>(
            find.descendant(of: find.byType(GlassPill), matching: find.byType(Container)).first,
        );
        expect((box.decoration! as BoxDecoration).color, isNotNull);
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

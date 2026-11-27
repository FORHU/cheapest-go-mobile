import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/features/home/views/home_view.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/search/destinations_api.dart';

/// Typing a hotel's name and tapping it.
///
/// The destinations endpoint began offering properties beside places. Mobile treated every row
/// as somewhere to search, so picking "Casa La El Baguio" ran a stay search for a town of that
/// name and found nothing — the suggestion arrived, and choosing it went nowhere useful.
///
/// Somebody who types a property's name has already chosen. app-v2 opens the property page for
/// this case; this is the same answer.
class _StubApi extends DestinationsApi {
    @override
    Future<List<DestinationSuggestion>?> search(
        String query, {
        bool forFlights = false,
        int limit = 8,
    }) async =>
        const [
            DestinationSuggestion(
                id: '13143275',
                kind: DestinationKind.hotel,
                name: 'Casa La El Baguio',
                city: 'Baguio, PH',
                countryCode: 'PH',
            ),
            DestinationSuggestion(
                id: 'place.820403',
                kind: DestinationKind.city,
                name: 'Baguio',
                city: 'Baguio, Philippines',
                countryCode: 'PH',
            ),
        ];

    @override
    Future<List<DestinationSuggestion>> trending() async => const [];
}

void main() {
    TestWidgetsFlutterBinding.ensureInitialized();

    late DestinationsApi original;

    setUp(() {
        SharedPreferences.setMockInitialValues({});
        original = destinationsApi;
        destinationsApi = _StubApi();
    });

    tearDown(() => destinationsApi = original);

    /// The real route takes the id in its path, so the stand-in reads it back out: asserting
    /// "a property page opened" without checking which property would pass on the wrong one.
    GoRouter buildRouter() => GoRouter(
            initialLocation: '/',
            routes: [
                GoRoute(path: '/', builder: (_, _) => const Scaffold(body: HomeView())),
                GoRoute(
                    path: '/hotel/:id',
                    builder: (_, state) => Scaffold(
                        body: Text('property:${state.pathParameters['id']}'),
                    ),
                ),
                GoRoute(path: '/hotels', builder: (_, _) => const Scaffold(body: Text('stay results'))),
            ],
        );

    Future<void> typeHotelName(WidgetTester tester) async {
        tester.view.physicalSize = const Size(390 * 3, 900 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.light,
            routerConfig: buildRouter(),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(TextField).first);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 'casa la el baguio');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
    }

    testWidgets('opens the property rather than searching for its name', (tester) async {
        await typeHotelName(tester);

        await tester.tap(find.text('Casa La El Baguio'));
        await tester.pumpAndSettle();

        expect(find.text('property:13143275'), findsOneWidget);
        expect(find.text('stay results'), findsNothing);
    });

    testWidgets('a place beside it still answers the step rather than navigating', (tester) async {
        await typeHotelName(tester);

        await tester.tap(find.text('Baguio, Philippines'));
        await tester.pumpAndSettle();

        // Still on the stage, with the question answered — not sent anywhere.
        expect(find.text('property:13143275'), findsNothing);
        expect(find.byType(HomeView), findsOneWidget);
    });
}

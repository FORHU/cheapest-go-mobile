import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/features/hotels/components/nearby_explorer.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/search/nearby_api.dart';

/// What is around a property. See #40.
class _FakeNearby extends NearbyApi {
    _FakeNearby(this.byCategory);

    final Map<NearbyCategory, List<NearbyPlace>> byCategory;
    final asked = <NearbyCategory>[];

    @override
    Future<List<NearbyPlace>> around(
        double latitude,
        double longitude, {
        NearbyCategory category = NearbyCategory.all,
        int radius = 3000,
    }) async {
        asked.add(category);
        return byCategory[category] ?? const [];
    }
}

NearbyPlace place(String id, String name, {String category = 'restaurant', double lat = 14.59, double lng = 120.98}) =>
    NearbyPlace(id: id, name: name, category: category, latitude: lat, longitude: lng, rating: 4.5);

void main() {
    Future<void> pump(WidgetTester tester, NearbyApi api) async {
        tester.view.physicalSize = const Size(390 * 3, 844 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.light,
            home: Scaffold(
                body: SingleChildScrollView(
                    child: NearbyExplorer(latitude: 14.5906, longitude: 120.9799, api: api),
                ),
            ),
        ));
        await tester.pumpAndSettle();
    }

    testWidgets('shows what is nearby, with how far it is', (tester) async {
        await pump(tester, _FakeNearby({
            NearbyCategory.all: [place('a', 'Bistro Remedios', lat: 14.5930, lng: 120.9820)],
        }));

        expect(find.text('Bistro Remedios'), findsOneWidget);
        // Measured from the property, and said the way a person says it.
        expect(find.textContaining(' m ·'), findsOneWidget);
    });

    testWidgets('a filter asks the endpoint for that category', (tester) async {
        final api = _FakeNearby({
            NearbyCategory.all: [place('a', 'Bistro Remedios')],
            NearbyCategory.cafe: [place('b', 'Kape Kostura', category: 'cafe')],
        });
        await pump(tester, api);

        await tester.tap(find.text('Cafés'));
        await tester.pumpAndSettle();

        expect(api.asked, [NearbyCategory.all, NearbyCategory.cafe]);
        expect(find.text('Kape Kostura'), findsOneWidget);
        expect(find.text('Bistro Remedios'), findsNothing);
    });

    testWidgets('offers every category V2 offers', (tester) async {
        await pump(tester, _FakeNearby({NearbyCategory.all: [place('a', 'Bistro Remedios')]}));

        // `POI_FILTERS` in V2: all, restaurant, cafe, attraction, grocery, medical, transit.
        // The strip scrolls, so each is dragged into view rather than assumed to be built.
        for (final label in ['All', 'Food', 'Cafés', 'Attractions', 'Groceries', 'Pharmacy', 'Transit']) {
            await tester.scrollUntilVisible(
                find.text(label),
                120,
                scrollable: find.byType(Scrollable).first,
            );
            expect(find.text(label), findsOneWidget, reason: '$label is missing');
        }
    });

    testWidgets('removes itself when the endpoint has nothing to say', (tester) async {
        // api-v2 answers 503 without a Places key, and the client turns that into an empty
        // list. An empty frame headed "What's nearby" is worse than no section.
        await pump(tester, _FakeNearby(const {}));

        expect(find.textContaining("What's nearby"), findsNothing);
    });
}

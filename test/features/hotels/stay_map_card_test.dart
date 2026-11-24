import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/features/hotels/components/stay_map.dart';
import 'package:cheapest_go_mobile/features/hotels/components/stay_pins.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';

/// The map's own behaviour, with stays that carry coordinates.
///
/// `booking_flows_test.dart` reaches the results screen through the mock catalogue, whose
/// stays have no latitude or longitude at all — `_stay()` never sets them — so its map draws
/// no pins and never could. That is why the rail was the only thing those tests could read a
/// stay from, and why removing it broke three of them.
///
/// The card the pins open is not here: it is painted into the map (ADR-0008), so there is no
/// widget for a test to find. What it is made of is covered in `stay_card_test.dart`.
Hotel _at(String id, String name, double lat, double lng) => Hotel(
  id: id,
  airportCode: 'MNL',
  name: name,
  area: 'Malate',
  distanceKm: 1,
  distanceFrom: 'MNL',
  score: 8.5,
  reviews: 100,
  tags: const [],
  rooms: const [],
  latitude: lat,
  longitude: lng,
);

void main() {
  // Far enough apart that the clustering radius leaves them as separate pins.
  final hotels = [
    _at('a', 'Bayside Grand Manila', 14.56, 120.98),
    _at('b', 'Ayala Triangle Suites', 14.62, 121.04),
  ];

  Future<void> pumpMap(
    WidgetTester tester, {
    required String? selectedId,
    required void Function(Hotel) onSelect,
    void Function(Hotel)? onOpen,
    VoidCallback? onMapTap,
  }) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.light,
        home: Scaffold(
          body: StayMap(
            hotels: hotels,
            currency: 'KRW',
            selectedId: selectedId,
            onSelect: onSelect,
            onOpen: onOpen ?? (_) {},
            onMapTap: onMapTap,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a pin reports the stay it stands for', (tester) async {
    final picked = <String>[];
    await pumpMap(
      tester,
      selectedId: null,
      onSelect: (h) => picked.add(h.id),
    );

    expect(find.byType(HotelPin), findsNWidgets(2));

    await tester.tap(find.byType(HotelPin).first);
    await tester.pumpAndSettle();
    expect(picked, hasLength(1));

    await tester.tap(find.byType(HotelPin).last);
    await tester.pumpAndSettle();
    expect(picked, hasLength(2));
    expect(picked.first, isNot(picked.last), reason: 'two pins, two stays');
  });

  testWidgets('the selected pin is drawn as the chosen one', (tester) async {
    await pumpMap(tester, selectedId: 'a', onSelect: (_) {});

    final pins = tester.widgetList<HotelPin>(find.byType(HotelPin)).toList();
    expect(pins.where((p) => p.active), hasLength(1));
  });
}

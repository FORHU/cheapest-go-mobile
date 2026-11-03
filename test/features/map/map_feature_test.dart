import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/features/map/components/airport_hub_sheet.dart';
import 'package:cheapest_go_mobile/features/map/components/flight_telemetry_hud.dart';
import 'package:cheapest_go_mobile/features/map/models/map_models.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/stores/trip_search_store.dart';
import '../../test_helpers.dart';

void main() {
  const catalog = travelCatalog;
  final mnl = catalog.airport('MNL')!;

  group('Map models', () {
    test('places near an airport are the catalogue stays and courses, at their distance', () {
      final places = placesNear(catalog, mnl, MapFilter.overview);
      final hotels = catalog.hotelsNear('MNL');
      final courses = catalog.coursesNear('MNL');
      expect(places.where((p) => !p.isGolf).map((p) => p.id), hotels.map((h) => h.id));
      expect(places.where((p) => p.isGolf).map((p) => p.id), courses.map((c) => c.id));

      for (final h in hotels) {
        final place = places.firstWhere((p) => p.id == h.id);
        expect(distanceKm((mnl.latitude, mnl.longitude), place.position), closeTo(h.distanceKm, 0.05));
      }
      // Same spot every time.
      expect(placesNear(catalog, mnl, MapFilter.overview).first.position, places.first.position);
    });

    test('filters keep only stays or only golf', () {
      expect(placesNear(catalog, mnl, MapFilter.stays).every((p) => !p.isGolf), isTrue);
      expect(placesNear(catalog, mnl, MapFilter.golf).every((p) => p.isGolf), isTrue);
    });

    test('tracked flights land at arrival airports and move along their route', () {
      final flights = trackedFlights(catalog);
      expect(flights, isNotEmpty);
      final arrivals = catalog.airports().map((a) => a.code).toSet();
      for (final f in flights) {
        expect(arrivals, contains(f.destination.code));
        expect(f.offer.nonStop, isTrue);
        expect(f.groundSpeedKnots, inInclusiveRange(250, 600));
        expect(distanceKm(f.positionAt(0), f.from), lessThan(1));
        expect(distanceKm(f.positionAt(1), f.to), lessThan(1));
        final half = f.positionAt(0.5);
        expect(distanceKm(f.from, half), closeTo(distanceKm(half, f.to), 1));
      }
    });

    test('flights into an airport are the cheapest per origin, cheapest first', () {
      final offers = flightsInto(catalog, mnl);
      expect(offers, isNotEmpty);
      expect(offers.every((f) => f.destination == 'MNL'), isTrue);
      expect(offers.map((f) => f.origin).toSet().length, offers.length);
      for (var i = 1; i < offers.length; i++) {
        expect(offers[i].price, greaterThanOrEqualTo(offers[i - 1].price));
      }
    });
  });

  group('Airport sheet', () {
    Widget sheet({
      MapFilter filter = MapFilter.overview,
      MapPlace? selected,
      void Function(MapFilter)? onFilter,
      void Function(MapPlace)? onPlace,
      void Function(MapPlace)? onOpen,
      VoidCallback? onHub,
      void Function(FlightOffer)? onFlight,
    }) =>
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AirportHubSheet(
              airport: mnl,
              places: placesNear(catalog, mnl, MapFilter.overview),
              filter: filter,
              selectedPlace: selected,
              onFilterChanged: onFilter ?? (_) {},
              onPlaceSelected: onPlace ?? (_) {},
              onOpenPlace: onOpen ?? (_) {},
              onOpenHub: onHub ?? () {},
              onBookFlight: onFlight ?? (_) {},
              onNextAirport: () {},
              onPreviousAirport: () {},
              onClose: () {},
            ),
          ),
        );

    testWidgets('overview shows peso prices and opens the airport hub', (tester) async {
      var hub = 0;
      MapFilter? picked;
      await tester.pumpWidget(sheet(onHub: () => hub++, onFilter: (f) => picked = f));

      expect(find.text('Manila, Philippines'), findsOneWidget);
      expect(find.textContaining('₱'), findsWidgets);
      expect(find.textContaining('\$'), findsNothing);

      await tester.tap(find.text('Open the MNL airport hub'));
      expect(hub, 1);
      await tester.tap(find.textContaining('Golf ·'));
      expect(picked, MapFilter.golf);
    });

    testWidgets('a stay in the list selects it; its preview opens it to book', (tester) async {
      MapPlace? selected;
      MapPlace? opened;
      await tester.pumpWidget(sheet(filter: MapFilter.stays, onPlace: (p) => selected = p));
      final first = catalog.hotelsNear('MNL').first;
      await tester.tap(find.text(first.name));
      expect(selected?.id, first.id);

      await tester.pumpWidget(sheet(selected: selected, onOpen: (p) => opened = p));
      expect(find.text('See rooms & book'), findsOneWidget);
      await tester.tap(find.text('See rooms & book'));
      expect(opened?.id, first.id);
    });

    testWidgets('flights in list books the tapped flight', (tester) async {
      FlightOffer? booked;
      await tester.pumpWidget(sheet(filter: MapFilter.flights, onFlight: (f) => booked = f));
      final cheapest = flightsInto(catalog, mnl).first;
      await tester.tap(find.textContaining('${cheapest.origin} → MNL'));
      expect(booked?.id, cheapest.id);
    });
  });

  group('Flight tracker panel', () {
    testWidgets('time left falls as progress grows, and it links the arrival airport', (tester) async {
      final flight = trackedFlights(catalog).first;
      var explore = 0;
      Widget hud(double progress) => MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: FlightTelemetryHud(
                flight: flight,
                progress: progress,
                onNextFlight: () {},
                onViewDestinationHub: () => explore++,
                onExitTracking: () {},
              ),
            ),
          );

      await tester.pumpWidget(hud(0.2));
      final early = tester.widget<Text>(find.textContaining('nm to go')).data;
      await tester.pumpWidget(hud(0.8));
      final late = tester.widget<Text>(find.textContaining('nm to go')).data;
      expect(early, isNot(late));

      await tester.tap(find.text('Stays & golf near ${flight.destination.code}'));
      expect(explore, 1);
    });
  });

  group('Map tab', () {
    setUp(() => tripSearchStore.setAirport('MNL'));

    testWidgets('opens on the searched airport and books a stay from the map', (tester) async {
      await pumpApp(tester, location: '/map');
      expect(find.text('Manila, Philippines'), findsOneWidget);

      await tester.tap(find.textContaining('Stays ·'));
      await tester.pumpAndSettle();
      final first = catalog.hotelsNear('MNL').first;
      await tester.tap(find.text(first.name));
      await tester.pumpAndSettle();
      await tester.tap(find.text('See rooms & book'));
      await tester.pumpAndSettle();
      expect(find.text(first.name), findsWidgets);
      expect(find.byType(AirportHubSheet), findsNothing);
    });

    testWidgets('zoomed out, every airport shows its stays and golf; tapping one opens it', (tester) async {
      await pumpApp(tester, location: '/map');
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(AirportHubSheet), findsNothing);

      final ceb = catalog.airport('CEB')!;
      final label = '${catalog.hotelsNear('CEB').length} stays · ${catalog.coursesNear('CEB').length} golf';
      await tester.scrollUntilVisible(find.text('CEB · ${ceb.city}'), 200, scrollable: find.byType(Scrollable).last);
      expect(find.text(label), findsOneWidget);

      await tester.tap(find.text('CEB · ${ceb.city}'));
      await tester.pumpAndSettle();
      expect(find.text('${ceb.city}, ${ceb.country}'), findsOneWidget);
    });

    testWidgets('live flights move, then hand over to the arrival airport', (tester) async {
      await pumpApp(tester, location: '/map');
      await tester.tap(find.text('Live flights'));
      await tester.pump();
      expect(find.byType(FlightTelemetryHud), findsOneWidget);

      final before = tester.widget<FlightTelemetryHud>(find.byType(FlightTelemetryHud)).progress;
      await tester.pump(const Duration(seconds: 2));
      final after = tester.widget<FlightTelemetryHud>(find.byType(FlightTelemetryHud)).progress;
      expect(after, greaterThan(before));

      final destination = trackedFlights(catalog).first.destination;
      await tester.tap(find.text('Stays & golf near ${destination.code}'));
      await tester.pumpAndSettle();
      expect(find.byType(FlightTelemetryHud), findsNothing);
      expect(find.text('${destination.city}, ${destination.country}'), findsOneWidget);
      expect(tripSearchStore.airportCode, destination.code);
    });
  });
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/features/map/components/airport_hub_sheet.dart';
import 'package:cheapest_go_mobile/features/map/components/flight_telemetry_hud.dart';
import 'package:cheapest_go_mobile/features/map/models/map_models.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/components/ui_kit.dart';
import 'package:cheapest_go_mobile/shared/flights/flight_status.dart';
import 'package:cheapest_go_mobile/shared/flights/offline_route_maps.dart';
import 'package:cheapest_go_mobile/shared/stores/bookings_store.dart';
import 'package:cheapest_go_mobile/shared/stores/trip_search_store.dart';
import '../../test_helpers.dart';

/// Books [offer] so it departs [departsIn] from now (negative: already left).
Booking bookFlight(FlightOffer offer, Duration departsIn) => bookingsStore.addFlight(
      origin: offer.origin,
      destination: offer.destination,
      airline: offer.airline,
      flightNo: offer.flightNo,
      day: DateTime.now(),
      departs: offer.departs,
      arrives: offer.arrives,
      stops: offer.stopsLabel,
      passengers: 1,
      total: offer.price,
      flight: BookedFlight(
        offerId: offer.id,
        airline: offer.airline,
        flightNo: offer.flightNo,
        origin: offer.origin,
        destination: offer.destination,
        departureUtc: DateTime.now().toUtc().add(departsIn),
        durationMinutes: offer.durationMinutes,
      ),
    );

void main() {
  const catalog = travelCatalog;
  final mnl = catalog.airport('MNL')!;
  final mnlToIcn = catalog.flights('MNL', 'ICN').firstWhere((f) => f.nonStop);
  final mnlToCeb = catalog.flights('MNL', 'CEB').firstWhere((f) => f.nonStop);

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

    test('every stay and course sits on the land side of its airport', () {
      // The land directions per airport, as in map_models.dart.
      const land = {
        'MNL': (340.0, 105.0), 'CEB': (260.0, 70.0), 'DVO': (200.0, 140.0), 'KLO': (130.0, 70.0),
        'PPS': (205.0, 25.0), 'BKK': (250.0, 160.0), 'TAG': (20.0, 70.0), 'ILO': (270.0, 180.0), 'DPS': (340.0, 60.0), 'ICN': (60.0, 70.0),
      };
      double bearing(LatLng a, LatLng b) {
        double r(double d) => d * math.pi / 180;
        final y = math.sin(r(b.$2 - a.$2)) * math.cos(r(b.$1));
        final x = math.cos(r(a.$1)) * math.sin(r(b.$1)) - math.sin(r(a.$1)) * math.cos(r(b.$1)) * math.cos(r(b.$2 - a.$2));
        return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
      }

      for (final MapEntry(key: code, value: (start, width)) in land.entries) {
        final airport = catalog.airport(code)!;
        for (final p in placesNear(catalog, airport, MapFilter.overview)) {
          final b = bearing((airport.latitude, airport.longitude), p.position);
          final inMain = (b - start + 360) % 360 <= width + 0.5;
          final inSouth = code == 'MNL' && (b - 170 + 360) % 360 <= 60.5; // second Manila arc
          expect(inMain || inSouth, isTrue, reason: '${p.id} near $code at ${b.round()}°');
        }
      }
    });

    test('filters keep only stays or only golf', () {
      expect(placesNear(catalog, mnl, MapFilter.stays).every((p) => !p.isGolf), isTrue);
      expect(placesNear(catalog, mnl, MapFilter.golf).every((p) => p.isGolf), isTrue);
    });

    test('a booked flight is trackable until 6 h after landing and moves along its route', () {
      final b = bookFlight(mnlToIcn, const Duration(hours: -1));
      final now = DateTime.now().toUtc();
      final tracked = trackableFlights(catalog, [b], (_) => now);
      expect(tracked.single.destination.code, 'ICN');
      final f = tracked.single;
      expect(f.groundSpeedKnots, inInclusiveRange(250, 600));
      expect(distanceKm(f.positionAt(0), f.from), lessThan(1));
      expect(distanceKm(f.positionAt(1), f.to), lessThan(1));
      final half = f.positionAt(0.5);
      expect(distanceKm(f.from, half), closeTo(distanceKm(half, f.to), 1));

      final later = b.flight!.arrivalUtc.add(kTrackAfterLanding + const Duration(minutes: 1));
      expect(trackableFlights(catalog, [b], (_) => later), isEmpty);
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
      await tester.tap(find.text('Golf ${catalog.coursesNear('MNL').length}'));
      expect(picked, MapFilter.golf);
    });

    testWidgets('all four tabs fit on a phone, Flights included', (tester) async {
      usePhoneViewport(tester);
      MapFilter? picked;
      await tester.pumpWidget(sheet(onFilter: (f) => picked = f));
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      for (final label in ['Overview', 'Stays ${catalog.hotelsNear('MNL').length}', 'Golf ${catalog.coursesNear('MNL').length}', 'Flights']) {
        final r = tester.getRect(find.text(label));
        expect(r.left >= 0 && r.right <= screen.width, isTrue, reason: '$label is off screen');
      }
      await tester.tap(find.text('Flights'));
      expect(picked, MapFilter.flights);
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
    final booking = bookFlight(mnlToIcn, const Duration(days: 1));
    final flight = TrackedFlight(booking: booking, origin: mnl, destination: catalog.airport('ICN')!);
    final dep = booking.flight!.departureUtc;

    Widget hud(DateTime now, {PositionSource source = PositionSource.schedule, VoidCallback? onExplore, VoidCallback? onSave}) => MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: SingleChildScrollView(
              child: FlightTelemetryHud(
                flight: flight,
                status: flightStatusService.statusOf(booking.flight!, now),
                positionSource: source,
                offlineMap: const OfflineMapStatus(OfflineMapState.none),
                onDownloadMap: onSave ?? () {},
                onExitTracking: () {},
                onViewDestinationHub: onExplore,
              ),
            ),
          ),
        );

    testWidgets('before take-off it counts down in local times', (tester) async {
      var saved = 0;
      await tester.pumpWidget(hud(dep.subtract(const Duration(hours: 3)), onSave: () => saved++));
      expect(find.text('Departs in 3h 00m'), findsOneWidget);
      expect(find.textContaining('MNL time'), findsOneWidget);
      await tester.tap(find.text('Save'));
      expect(saved, 1);

      await tester.pumpWidget(hud(dep.subtract(const Duration(minutes: 20))));
      expect(find.text('Boarding · departs in 20 min'), findsOneWidget);
    });

    testWidgets('in the air: time left falls, and it says where the position comes from', (tester) async {
      final span = booking.flight!.arrivalUtc.difference(dep);
      await tester.pumpWidget(hud(dep.add(span * 0.2)));
      final early = tester.widget<Text>(find.textContaining('nm to go')).data;
      expect(find.textContaining('Estimated from the schedule'), findsOneWidget);

      await tester.pumpWidget(hud(dep.add(span * 0.8), source: PositionSource.gps));
      expect(tester.widget<Text>(find.textContaining('nm to go')).data, isNot(early));
      expect(find.text('Your position from GPS'), findsOneWidget);

      await tester.pumpWidget(hud(dep.add(span * 0.5), source: PositionSource.scheduleNoPermission));
      expect(find.textContaining('Allow location'), findsOneWidget);
    });

    testWidgets('after landing it hands over to the arrival airport', (tester) async {
      var explore = 0;
      await tester.pumpWidget(hud(booking.flight!.arrivalUtc.add(const Duration(minutes: 30)), onExplore: () => explore++));
      expect(find.text('Landed in Seoul'), findsOneWidget);
      await tester.tap(find.text('Stays & golf near ICN'));
      expect(explore, 1);
    });
  });

  group('Map tab', () {
    setUp(() => tripSearchStore.setAirport('MNL'));

    testWidgets('opens on the searched airport and books a stay from the map', (tester) async {
      await pumpApp(tester, location: '/map');
      expect(find.text('Manila, Philippines'), findsOneWidget);
      // The legend names one colour per kind of pin.
      for (final kind in ['Hotels', 'Golf', 'Flights']) {
        expect(find.descendant(of: find.byType(Material), matching: find.text(kind)), findsWidgets);
      }

      await tester.tap(find.text('Stays ${catalog.hotelsNear('MNL').length}'));
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

    testWidgets('Trips › Track opens the flight in the air on the map', (tester) async {
      final b = bookFlight(mnlToIcn, const Duration(hours: -1));
      await pumpApp(tester, location: '/trips');
      final card = find.ancestor(of: find.text(b.reference), matching: find.byType(AppCard));
      await tester.scrollUntilVisible(card, 300, scrollable: find.byType(Scrollable).first);
      final track = find.descendant(of: card, matching: find.text('Track'));
      expect(find.descendant(of: card, matching: find.textContaining('In the air')), findsOneWidget);
      // Bring it up clear of the bottom navigation before tapping.
      await tester.drag(find.byType(Scrollable).first, Offset(0, 300 - tester.getCenter(track).dy));
      await tester.pumpAndSettle();
      await tester.tap(track);
      await tester.pump();
      await tester.pump();

      final hud = tester.widget<FlightTelemetryHud>(find.byType(FlightTelemetryHud));
      expect(hud.flight.reference, b.reference);
      expect(hud.status.phase, FlightPhase.inAir);
      expect(find.textContaining('nm to go'), findsOneWidget);
      await tester.tap(find.byTooltip('Stop tracking'));
      await tester.pump();
    });

    testWidgets('the tracker pauses on another tab and comes back on return', (tester) async {
      final b = bookFlight(mnlToIcn, const Duration(hours: -1));
      flightToTrack.value = b.reference;
      await pumpApp(tester, location: '/map');
      await tester.pump();
      expect(find.byType(FlightTelemetryHud), findsOneWidget);

      await tester.tap(find.text('Trips'));
      await tester.pumpAndSettle();
      expect(find.byType(FlightTelemetryHud), findsNothing);

      await tester.tap(find.byIcon(Icons.public_rounded).first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final hud = tester.widget<FlightTelemetryHud>(find.byType(FlightTelemetryHud));
      expect(hud.flight.reference, b.reference);
      expect(hud.status.phase, FlightPhase.inAir);
      await tester.tap(find.byTooltip('Stop tracking'));
      await tester.pump();
    });

    testWidgets('a landed flight hands over to its arrival airport', (tester) async {
      final b = bookFlight(mnlToCeb, const Duration(hours: -3));
      flightToTrack.value = b.reference;
      await pumpApp(tester, location: '/map');
      await tester.pump();
      expect(find.text('Landed in Cebu'), findsOneWidget);

      await tester.tap(find.text('Stays & golf near CEB'));
      await tester.pumpAndSettle();
      expect(find.byType(FlightTelemetryHud), findsNothing);
      expect(find.text('Cebu, Philippines'), findsOneWidget);
      expect(tripSearchStore.airportCode, 'CEB');
    });

    testWidgets('My flights with nothing booked offers to find flights', (tester) async {
      var found = 0;
      await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: Scaffold(body: NoFlightsCard(onFindFlights: () => found++))));
      expect(find.text('No flights to track'), findsOneWidget);
      await tester.tap(find.text('Find flights'));
      expect(found, 1);
    });
  });
}

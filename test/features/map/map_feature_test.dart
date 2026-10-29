import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/features/map/components/airport_hub_sheet.dart';
import 'package:cheapest_go_mobile/features/map/components/flight_telemetry_hud.dart';
import 'package:cheapest_go_mobile/features/map/components/map_tier_toggle.dart';
import 'package:cheapest_go_mobile/features/map/models/map_models.dart';
import 'package:cheapest_go_mobile/features/map/views/map_view.dart';

void main() {
  group('Map Feature Models & Hubs Tests', () {
    test('kGlobalDestinationHubs contains comprehensive hub data', () {
      expect(kGlobalDestinationHubs.isNotEmpty, isTrue);

      // Verify Manila hub
      final mnl = kGlobalDestinationHubs.firstWhere((h) => h.code == 'MNL');
      expect(mnl.name, 'Manila');
      expect(mnl.airportHotels.isNotEmpty, isTrue);
      expect(mnl.directFlights.isNotEmpty, isTrue);
      expect(mnl.golfCourses.isNotEmpty, isTrue);

      // Verify Clark hub with golf
      final crk = kGlobalDestinationHubs.firstWhere((h) => h.code == 'CRK');
      expect(crk.name, 'Clark');
      expect(crk.golfCourses.any((g) => g.name.contains('Mimosa')), isTrue);

      // Verify Bali hub
      final dps = kGlobalDestinationHubs.firstWhere((h) => h.code == 'DPS');
      expect(dps.name, 'Bali');
      expect(dps.golfCourses.any((g) => g.name.contains('New Kuta')), isTrue);
    });

    test('kActiveTrackedFlights contains valid live telemetry routes', () {
      expect(kActiveTrackedFlights.isNotEmpty, isTrue);
      final flight = kActiveTrackedFlights.first;
      expect(flight.flightNumber, 'PR 537');
      expect(flight.originHub.code, 'MNL');
      expect(flight.destinationHub.code, 'SIN');
      expect(flight.cruisingAltitudeFeet, 36000);
      expect(flight.groundSpeedKnots, 495);
    });
  });

  group('Map Tier Toggle Widget Tests', () {
    testWidgets('toggles between 2D Lite and 3D Standard Globe', (tester) async {
      MapTier selectedTier = MapTier.standard;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return MapTierToggle(
                  currentTier: selectedTier,
                  onTierChanged: (t) => setState(() => selectedTier = t),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('2D Lite'), findsOneWidget);
      expect(find.text('3D Globe'), findsOneWidget);

      // Tap 2D Lite
      await tester.tap(find.text('2D Lite'));
      await tester.pumpAndSettle();
      expect(selectedTier, MapTier.lite);

      // Tap 3D Globe
      await tester.tap(find.text('3D Globe'));
      await tester.pumpAndSettle();
      expect(selectedTier, MapTier.standard);
    });
  });

  group('Airport Hub Sheet Widget Tests', () {
    testWidgets('renders airport hotels, flights, and golf tabs properly', (tester) async {
      final hub = kGlobalDestinationHubs.firstWhere((h) => h.code == 'MNL');
      int nextCount = 0;
      int prevCount = 0;
      int closeCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: AirportHubSheet(
              hub: hub,
              onNextHub: () => nextCount++,
              onPreviousHub: () => prevCount++,
              onClose: () => closeCount++,
            ),
          ),
        ),
      );

      // Hub header
      expect(find.text('MNL'), findsOneWidget);
      expect(find.text('Manila, Philippines'), findsOneWidget);

      // Overview Tab is default
      expect(find.text('AIRPORT STAYS'), findsOneWidget);
      expect(find.text('DIRECT FLIGHTS'), findsOneWidget);

      // Switch to Airport Hotels tab
      await tester.tap(find.textContaining('Airport Hotels'));
      await tester.pumpAndSettle();
      expect(find.text('Belmont Hotel Manila'), findsOneWidget);
      expect(find.text('Book Stay'), findsWidgets);

      // Switch to Direct Flights tab
      await tester.tap(find.textContaining('Direct Flights'));
      await tester.pumpAndSettle();
      expect(find.textContaining('MNL ➔ SIN'), findsOneWidget);

      // Switch to Golf Getaways tab
      await tester.ensureVisible(find.textContaining('Golf Getaways'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Golf Getaways'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Villamor Golf Club'), findsOneWidget);

      // Next & Previous buttons
      await tester.tap(find.byTooltip('Next Hub'));
      expect(nextCount, 1);
      await tester.tap(find.byTooltip('Previous Hub'));
      expect(prevCount, 1);
    });
  });

  group('Flight Telemetry HUD Widget Tests', () {
    testWidgets('displays active telemetry HUD and triggers callbacks', (tester) async {
      final flight = kActiveTrackedFlights.first;
      int nextFlightCount = 0;
      int destinationExploreCount = 0;
      int exitCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: FlightTelemetryHud(
              flight: flight,
              progress: 0.65,
              onNextFlight: () => nextFlightCount++,
              onViewDestinationHub: () => destinationExploreCount++,
              onExitTracking: () => exitCount++,
            ),
          ),
        ),
      );

      expect(find.text('PR 537'), findsOneWidget);
      expect(find.text('Philippine Airlines'), findsOneWidget);
      expect(find.text('MNL'), findsOneWidget);
      expect(find.text('SIN'), findsOneWidget);
      expect(find.text('36,000 FT'), findsOneWidget);
      expect(find.text('495 KTS'), findsOneWidget);

      // Trigger next route
      await tester.tap(find.text('Next Route'));
      expect(nextFlightCount, 1);

      // Trigger destination explore
      await tester.tap(find.textContaining('Explore Hotels & Golf at Singapore'));
      expect(destinationExploreCount, 1);
    });
  });

  group('MapView Screen Smoke Test', () {
    testWidgets('renders MapView and switches mode to Live In-Flight', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const MapView(),
        ),
      );

      // Initial state is 3D Globe with Hubs & Stays
      expect(find.byType(MapView), findsOneWidget);
      expect(find.text('Hubs & Stays'), findsOneWidget);
      expect(find.text('All Hubs'), findsOneWidget);

      // Toggle to Live In-Flight Tracker
      await tester.tap(find.text('Hubs & Stays'));
      await tester.pump();
      expect(find.text('Live In-Flight'), findsOneWidget);
      expect(find.byType(FlightTelemetryHud), findsOneWidget);
    });
  });
}

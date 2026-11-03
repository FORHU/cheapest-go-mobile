import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/flights/flight_status.dart';
import 'package:cheapest_go_mobile/shared/stores/bookings_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const catalog = travelCatalog;

  final flight = BookedFlight(
    offerId: 'MNL-ICN-0',
    airline: 'Bayan Air',
    flightNo: 'BY 123',
    origin: 'MNL',
    destination: 'ICN',
    departureUtc: DateTime.utc(2026, 11, 20, 0, 30),
    durationMinutes: 240,
  );

  group('Flight status from the schedule', () {
    const service = ScheduleFlightStatusService();
    final dep = flight.departureUtc;

    test('scheduled, boarding, in the air, landed', () {
      expect(service.statusOf(flight, dep.subtract(const Duration(hours: 2))).phase, FlightPhase.scheduled);
      expect(service.statusOf(flight, dep.subtract(const Duration(minutes: 30))).phase, FlightPhase.boarding);

      final half = service.statusOf(flight, dep.add(const Duration(hours: 2)));
      expect(half.phase, FlightPhase.inAir);
      expect(half.progress, closeTo(0.5, 0.001));
      expect(half.untilArrival, const Duration(hours: 2));

      final landed = service.statusOf(flight, flight.arrivalUtc.add(const Duration(minutes: 1)));
      expect(landed.phase, FlightPhase.landed);
      expect(landed.progress, 1);
    });

    test('the simulator replays from just before take-off, fast', () {
      var now = DateTime.utc(2026, 11, 1, 12);
      final sim = FlightSimulator(clock: () => now);
      sim.start('CG-F-TEST', flight);
      expect(service.statusOf(flight, sim.nowFor('CG-F-TEST')).phase, FlightPhase.boarding);

      now = now.add(const Duration(seconds: 120)); // 2 h simulated
      expect(service.statusOf(flight, sim.nowFor('CG-F-TEST')).phase, FlightPhase.inAir);

      sim.stop('CG-F-TEST');
      expect(sim.nowFor('CG-F-TEST'), now);
    });
  });

  test('departure in the origin\'s local time converts to UTC', () {
    final offer = catalog.flights('MNL', 'ICN').first;
    final utc = offer.departureUtcOn(DateTime(2026, 11, 20));
    final local = utc.add(catalog.airport('MNL')!.utcOffset);
    expect('${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}', offer.departs);
    expect(local.day, 20);
    expect(catalog.airport('ICN')!.utcOffset, const Duration(hours: 9));
  });

  test('Seoul is an arrival airport with stays and golf', () {
    expect(catalog.airport('ICN'), isNotNull);
    expect(catalog.hotelsNear('ICN'), isNotEmpty);
    expect(catalog.coursesNear('ICN'), isNotEmpty);
    expect(catalog.flights('MNL', 'ICN').any((f) => f.nonStop), isTrue);
  });

  test('bookings, with their flight, survive a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final store = BookingsStore();
    final booked = store.addFlight(
      origin: 'MNL',
      destination: 'ICN',
      airline: flight.airline,
      flightNo: flight.flightNo,
      day: DateTime(2026, 11, 20),
      departs: '08:30',
      arrives: '12:30',
      stops: 'Non-stop',
      passengers: 2,
      total: 18400,
      flight: flight,
    );
    await Future<void>.delayed(Duration.zero);

    final reopened = BookingsStore();
    await reopened.init();
    final loaded = reopened.byReference(booked.reference)!;
    expect(loaded.flight!.departureUtc, flight.departureUtc);
    expect(loaded.flight!.destination, 'ICN');
    expect(reopened.flights.single.reference, booked.reference);

    reopened.seedDemoHistory();
    expect(reopened.all.length, 1, reason: 'demo trips only fill an empty store');
  });
}

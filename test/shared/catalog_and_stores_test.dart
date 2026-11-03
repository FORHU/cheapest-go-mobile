import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:cheapest_go_mobile/features/hotels/views/hotel_checkout_view.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/stores/bookings_store.dart';
import 'package:cheapest_go_mobile/shared/stores/trip_search_store.dart';
import 'package:cheapest_go_mobile/shared/utils/format.dart';

void main() {
  group('format', () {
    test('pesos get thousands separators', () {
      expect(formatPeso(0), '₱0');
      expect(formatPeso(980), '₱980');
      expect(formatPeso(4850), '₱4,850');
      expect(formatPeso(1234567), '₱1,234,567');
    });

    test('tee times read as 12-hour clock', () {
      expect(formatTeeTime('06:40'), '6:40 AM');
      expect(formatTeeTime('12:00'), '12:00 PM');
      expect(formatTeeTime('13:10'), '1:10 PM');
      expect(formatTeeTime('00:30'), '12:30 AM');
    });

    test('date ranges collapse within a month', () {
      expect(formatDateRange(DateTime(2026, 11, 14), DateTime(2026, 11, 17)), 'Nov 14 – 17');
      expect(formatDateRange(DateTime(2026, 11, 30), DateTime(2026, 12, 2)), 'Nov 30 – Dec 2');
      expect(formatDayDate(DateTime(2026, 11, 14)), 'Sat, Nov 14');
    });
  });

  group('mock catalogue', () {
    const catalog = MockTravelCatalog();

    test('every stay and course belongs to a listed airport', () {
      final codes = catalog.airports().map((a) => a.code).toSet();
      for (final code in codes) {
        for (final h in catalog.hotelsNear(code)) {
          expect(h.rooms, isNotEmpty, reason: h.id);
          expect(h.airportCode, code);
        }
        for (final c in catalog.coursesNear(code)) {
          expect(c.teeTimes, isNotEmpty, reason: c.id);
        }
      }
      expect(catalog.airport('XXX'), isNull);
      expect(catalog.hotel('missing'), isNull);
    });

    test('every arrival airport has plenty of stays and at least one course', () {
      expect(catalog.airports().length, greaterThanOrEqualTo(10));
      for (final a in catalog.airports()) {
        expect(catalog.hotelsNear(a.code).length, greaterThanOrEqualTo(4), reason: a.code);
        expect(catalog.coursesNear(a.code), isNotEmpty, reason: a.code);
      }
    });

    test('ids are unique and every origin can fly to every arrival', () {
      final hotelIds = [for (final a in catalog.airports()) ...catalog.hotelsNear(a.code).map((h) => h.id)];
      expect(hotelIds.toSet().length, hotelIds.length);
      final courseIds = [for (final a in catalog.airports()) ...catalog.coursesNear(a.code).map((c) => c.id)];
      expect(courseIds.toSet().length, courseIds.length);
      final origins = catalog.origins().map((o) => o.code).toList();
      expect(origins.toSet().length, origins.length);
      for (final from in origins) {
        for (final to in catalog.airports()) {
          if (from == to.code) continue;
          expect(catalog.flights(from, to.code), hasLength(5), reason: '$from → ${to.code}');
        }
      }
    });

    test('every photo the catalogue points at is bundled', () {
      final paths = <String>{
        for (final a in catalog.airports()) ...[
          a.photo!,
          for (final h in catalog.hotelsNear(a.code)) ...h.photos,
          for (final c in catalog.coursesNear(a.code)) c.photo,
        ],
      };
      for (final p in paths) {
        expect(File(p).existsSync(), isTrue, reason: p);
      }
      // Two room shots per hotel, never the same picture twice.
      for (final a in catalog.airports()) {
        for (final h in catalog.hotelsNear(a.code)) {
          expect(h.photos[1], isNot(h.photos[2]), reason: h.id);
        }
      }
    });

    test('domestic hops use local carriers, international ones do not', () {
      expect(catalog.flights('MNL', 'CEB').map((f) => f.airline), contains('Islas Express'));
      expect(catalog.flights('BKK', 'MNL').map((f) => f.airline), isNot(contains('Islas Express')));
    });

    test('stays sort by distance and courses by drive time', () {
      final hotels = catalog.hotelsNear('MNL');
      final distances = hotels.map((h) => h.distanceKm).toList();
      expect(distances, [...distances]..sort());
      final drives = catalog.coursesNear('MNL').map((c) => c.driveMinutes).toList();
      expect(drives, [...drives]..sort());
    });

    test('flights are stable, cheapest first, and resolvable by id', () {
      final offers = catalog.flights('SIN', 'MNL');
      expect(offers, hasLength(5));
      expect(offers.map((f) => f.price).toList(), [...offers.map((f) => f.price)]..sort());
      expect(catalog.flights('SIN', 'MNL').first.flightNo, offers.first.flightNo);
      expect(catalog.flight(offers.last.id)?.departs, offers.last.departs);
      expect(catalog.flights('MNL', 'MNL'), isEmpty);
      final connecting = offers.firstWhere((f) => !f.nonStop);
      expect(connecting.stopover, 'HKG');
      expect(catalog.flights('HKG', 'MNL').firstWhere((f) => !f.nonStop).stopover, 'TPE');
    });

    test('arrival clock rolls past midnight', () {
      const late = FlightOffer(
        id: 'X-Y-0', airline: 'A', flightNo: 'A 1', origin: 'X', destination: 'Y',
        departs: '22:30', durationMinutes: 200, stopover: null, baggage: '', price: 1,
      );
      expect(late.arrives, '01:50+1');
      expect(formatClock(late.arrives), '1:50 AM +1');
      expect(late.durationLabel, '3h 20m');
    });

    test('arrival is in the local time at the destination', () {
      const toSeoul = FlightOffer(
        id: 'MNL-ICN-0', airline: 'A', flightNo: 'A 1', origin: 'MNL', destination: 'ICN',
        departs: '06:15', durationMinutes: 236, stopover: null, baggage: '', price: 1,
      );
      expect(toSeoul.arrives, '11:11'); // 10:11 in Manila, Seoul is an hour ahead
      const toBangkok = FlightOffer(
        id: 'MNL-BKK-0', airline: 'A', flightNo: 'A 2', origin: 'MNL', destination: 'BKK',
        departs: '00:20', durationMinutes: 30, stopover: null, baggage: '', price: 1,
      );
      expect(toBangkok.arrives, '23:50-1'); // 00:50 in Manila, Bangkok is an hour behind
    });

    test('a hotel is priced from its cheapest room', () {
      final h = catalog.hotel('mnl-t3-garden')!;
      expect(h.fromRate, 4400);
      expect(h.hasShuttle, isTrue);
      expect(h.scoreLabel, 'Excellent');
    });
  });

  group('trip search', () {
    test('defaults to a three-night stay two weeks out', () {
      final s = TripSearchStore(today: DateTime(2026, 11, 2, 15));
      expect(s.checkIn, DateTime(2026, 11, 16));
      expect(s.nights, 3);
      expect(s.playDays, hasLength(4));
      expect(s.players, 2);
    });

    test('check-out never lands on or before check-in', () {
      final s = TripSearchStore(today: DateTime(2026, 11, 2));
      s.setDates(DateTime(2026, 12, 1), DateTime(2026, 12, 1));
      expect(s.nights, 1);
    });

    test('recent airports stay unique and capped at three', () {
      final s = TripSearchStore();
      for (final code in ['MNL', 'CRK', 'MNL', 'CEB', 'DPS']) {
        s
          ..setAirport(code)
          ..remember();
      }
      expect(s.recentAirports, ['DPS', 'CEB', 'MNL']);
    });
  });

  group('bookings', () {
    test('a future stay is upcoming, an old one is past', () {
      final store = BookingsStore(random: Random(1), clock: () => DateTime(2026, 11, 2));
      final stay = store.addStay(
        airportCode: 'MNL',
        hotelName: 'Terminal 3 Garden Hotel',
        roomName: 'Deluxe King',
        checkIn: DateTime(2026, 11, 14),
        checkOut: DateTime(2026, 11, 17),
        adults: 2,
        total: 16296,
      );
      store.addTeeTime(
        airportCode: 'MNL',
        courseName: 'Bayshore Links',
        courseMeta: '18 holes · Par 72',
        day: DateTime(2026, 10, 1),
        teeTime: '06:40',
        players: 2,
        total: 12400,
      );
      expect(store.upcoming.single.reference, stay.reference);
      expect(stay.reference, matches(RegExp(r'^CG-[A-Z2-9]{5}$')));
      expect(stay.when, 'Sat, Nov 14 → Tue, Nov 17 · 3 nights');
      expect(store.past.single.kind, BookingKind.teeTime);
      expect(store.past.single.reference, startsWith('CG-T'));
    });

    test('demo history fills Trips › Past only', () {
      final store = BookingsStore(random: Random(2), clock: () => DateTime(2026, 11, 2));
      store.seedDemoHistory();
      expect(store.upcoming, isEmpty);
      expect(store.past, hasLength(5));
      expect(store.past.map((b) => b.kind).toSet(), {BookingKind.flight, BookingKind.stay, BookingKind.teeTime});
    });

    test('stay taxes are 12% of the room total', () {
      expect(stayTaxes(14550), 1746);
    });
  });
}

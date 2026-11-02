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

    test('stays sort by distance and courses by drive time', () {
      final hotels = catalog.hotelsNear('MNL');
      final distances = hotels.map((h) => h.distanceKm).toList();
      expect(distances, [...distances]..sort());
      final drives = catalog.coursesNear('MNL').map((c) => c.driveMinutes).toList();
      expect(drives, [...drives]..sort());
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

    test('stay taxes are 12% of the room total', () {
      expect(stayTaxes(14550), 1746);
    });
  });
}

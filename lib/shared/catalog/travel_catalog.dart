/// Travel catalogue: arrival airports and the stays and golf courses near them.
///
/// Every feature reads data through [TravelCatalog]. Today the only
/// implementation is [MockTravelCatalog]; an API-backed one can replace it
/// later without touching the views.
library;

import 'dart:math';

class Airport {
  const Airport({
    required this.code,
    required this.name,
    required this.city,
    required this.country,
    required this.terminals,
  });

  final String code;
  final String name;
  final String city;
  final String country;
  final String terminals;
}

class Room {
  const Room({
    required this.id,
    required this.name,
    required this.meta,
    required this.nightlyRate,
    this.cancellation,
  });

  final String id;
  final String name;
  final String meta;

  /// Nightly rate in whole pesos.
  final int nightlyRate;

  /// Free-cancellation note, or `null` when the rate is non-refundable.
  final String? cancellation;

  bool get refundable => cancellation != null;
}

class Hotel {
  const Hotel({
    required this.id,
    required this.airportCode,
    required this.name,
    required this.area,
    required this.distanceKm,
    required this.distanceFrom,
    required this.score,
    required this.reviews,
    required this.tags,
    required this.rooms,
    this.badge,
  });

  final String id;
  final String airportCode;
  final String name;
  final String area;
  final double distanceKm;

  /// The terminal the distance is measured from, e.g. `Terminal 3`.
  final String distanceFrom;
  final double score;
  final int reviews;
  final List<String> tags;
  final List<Room> rooms;
  final String? badge;

  /// Lowest nightly rate across the rooms.
  int get fromRate => rooms.map((r) => r.nightlyRate).reduce((a, b) => a < b ? a : b);

  bool get hasShuttle => tags.contains(kTagShuttle);

  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km from $distanceFrom';

  String get scoreLabel {
    if (score >= 9) return 'Superb';
    if (score >= 8.5) return 'Excellent';
    if (score >= 8) return 'Very good';
    return 'Good';
  }
}

class GolfCourse {
  const GolfCourse({
    required this.id,
    required this.airportCode,
    required this.name,
    required this.holes,
    required this.par,
    required this.driveMinutes,
    required this.pricePerPlayer,
    required this.teeTimes,
    this.inclusion,
  });

  final String id;
  final String airportCode;
  final String name;
  final int holes;
  final int par;
  final int driveMinutes;

  /// Green fee per player in whole pesos.
  final int pricePerPlayer;

  /// Available tee times, `HH:mm` 24-hour.
  final List<String> teeTimes;

  /// What the green fee includes, e.g. `buggy included`.
  final String? inclusion;

  String get meta => [
        '$holes holes',
        'Par $par',
        ?inclusion,
      ].join(' · ');
}

class FlightOffer {
  const FlightOffer({
    required this.id,
    required this.airline,
    required this.flightNo,
    required this.origin,
    required this.destination,
    required this.departs,
    required this.durationMinutes,
    required this.stopover,
    required this.baggage,
    required this.price,
  });

  /// `<origin>-<destination>-<index>`, stable for the same route.
  final String id;
  final String airline;
  final String flightNo;
  final String origin;
  final String destination;

  /// Departure time, `HH:mm` 24-hour, local.
  final String departs;
  final int durationMinutes;

  /// Connecting airport code, or `null` for a non-stop flight.
  final String? stopover;
  final String baggage;

  /// One-way fare per passenger in whole pesos.
  final int price;

  bool get nonStop => stopover == null;

  /// Arrival time in the departure time zone, `HH:mm`; `+1` marks the next day.
  String get arrives {
    final p = departs.split(':');
    final total = int.parse(p[0]) * 60 + int.parse(p[1]) + durationMinutes;
    final hhmm = '${(total ~/ 60 % 24).toString().padLeft(2, '0')}:${(total % 60).toString().padLeft(2, '0')}';
    return total >= 24 * 60 ? '$hhmm+1' : hhmm;
  }

  String get durationLabel => '${durationMinutes ~/ 60}h ${(durationMinutes % 60).toString().padLeft(2, '0')}m';

  String get stopsLabel => nonStop ? 'Non-stop' : '1 stop · $stopover';
}

const kTagShuttle = 'Free airport shuttle';

abstract class TravelCatalog {
  List<Airport> airports();
  Airport? airport(String code);

  /// Airports a traveler can fly from into one of [airports].
  List<Airport> origins();
  Airport? origin(String code);
  List<FlightOffer> flights(String from, String to);
  FlightOffer? flight(String id);
  List<Hotel> hotelsNear(String airportCode);
  Hotel? hotel(String id);
  List<GolfCourse> coursesNear(String airportCode);
  GolfCourse? course(String id);
}

class MockTravelCatalog implements TravelCatalog {
  const MockTravelCatalog();

  @override
  List<Airport> airports() => _airports;

  @override
  Airport? airport(String code) => _firstWhere(_airports, (a) => a.code == code);

  @override
  List<Hotel> hotelsNear(String airportCode) =>
      _hotels.where((h) => h.airportCode == airportCode).toList()
        ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

  @override
  Hotel? hotel(String id) => _firstWhere(_hotels, (h) => h.id == id);

  @override
  List<GolfCourse> coursesNear(String airportCode) =>
      _courses.where((c) => c.airportCode == airportCode).toList()
        ..sort((a, b) => a.driveMinutes.compareTo(b.driveMinutes));

  @override
  GolfCourse? course(String id) => _firstWhere(_courses, (c) => c.id == id);

  @override
  List<Airport> origins() => [..._originsAbroad, ..._airports];

  @override
  Airport? origin(String code) => _firstWhere(origins(), (a) => a.code == code);

  @override
  List<FlightOffer> flights(String from, String to) {
    final a = _coords[from];
    final b = _coords[to];
    if (from == to || a == null || b == null) return const [];
    final km = _distanceKm(a, b);
    final baseMinutes = (km / 780 * 60).round() + 35;
    final baseFare = ((1600 + km * 3.1) / 10).round() * 10;
    final domestic = _airports.any((x) => x.code == from);
    final carriers = domestic ? _domesticCarriers : _internationalCarriers;
    return [
      for (var i = 0; i < _slots.length; i++)
        FlightOffer(
          id: '$from-$to-$i',
          airline: carriers[i % carriers.length].$1,
          flightNo: '${carriers[i % carriers.length].$2} ${_flightNumber(from, to, i)}',
          origin: from,
          destination: to,
          departs: _slots[i].$1,
          durationMinutes: baseMinutes + (_slots[i].$3 ? 150 : 0),
          stopover: _slots[i].$3 ? _hub(from, to, domestic: domestic) : null,
          baggage: _slots[i].$4,
          price: (baseFare * _slots[i].$2 / 10).round() * 10,
        ),
    ]..sort((x, y) => x.price.compareTo(y.price));
  }

  @override
  FlightOffer? flight(String id) {
    final parts = id.split('-');
    if (parts.length != 3) return null;
    return _firstWhere(flights(parts[0], parts[1]), (f) => f.id == id);
  }

  /// Where a connecting flight changes planes: Manila for domestic hops,
  /// Hong Kong abroad, or Iloilo / Taipei when the route already uses the hub.
  static String _hub(String from, String to, {required bool domestic}) {
    final (hub, alternative) = domestic ? ('MNL', 'ILO') : ('HKG', 'TPE');
    return from == hub || to == hub ? alternative : hub;
  }

  static int _flightNumber(String from, String to, int i) =>
      100 + (from.codeUnitAt(0) * 7 + to.codeUnitAt(1) * 3 + i * 41) % 800;

  static double _distanceKm((double, double) a, (double, double) b) {
    const r = 6371.0;
    double rad(double d) => d * pi / 180;
    final dLat = rad(b.$1 - a.$1);
    final dLng = rad(b.$2 - a.$2);
    final h = sin(dLat / 2) * sin(dLat / 2) + cos(rad(a.$1)) * cos(rad(b.$1)) * sin(dLng / 2) * sin(dLng / 2);
    return 2 * r * asin(sqrt(h));
  }

  static T? _firstWhere<T>(List<T> items, bool Function(T) test) {
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }
}

/// The catalogue the app reads from.
const TravelCatalog travelCatalog = MockTravelCatalog();

// Mock data. Airports are real; every hotel, course, and price is invented.

const _airports = [
  Airport(code: 'MNL', name: 'Ninoy Aquino International', city: 'Manila', country: 'Philippines', terminals: 'Terminals 1–3'),
  Airport(code: 'CRK', name: 'Clark International', city: 'Clark', country: 'Philippines', terminals: 'Passenger terminals 1–2'),
  Airport(code: 'CEB', name: 'Mactan–Cebu International', city: 'Cebu', country: 'Philippines', terminals: 'Terminals 1–2'),
];

const _originsAbroad = [
  Airport(code: 'SIN', name: 'Changi', city: 'Singapore', country: 'Singapore', terminals: 'Terminals 1–4'),
  Airport(code: 'HKG', name: 'Hong Kong International', city: 'Hong Kong', country: 'Hong Kong', terminals: 'Terminals 1–2'),
  Airport(code: 'ICN', name: 'Incheon International', city: 'Seoul', country: 'South Korea', terminals: 'Terminals 1–2'),
  Airport(code: 'NRT', name: 'Narita International', city: 'Tokyo', country: 'Japan', terminals: 'Terminals 1–3'),
  Airport(code: 'DXB', name: 'Dubai International', city: 'Dubai', country: 'United Arab Emirates', terminals: 'Terminals 1–3'),
];

/// Latitude, longitude per airport, for mock flight times and fares.
const _coords = <String, (double, double)>{
  'MNL': (14.51, 121.02),
  'CRK': (15.19, 120.56),
  'CEB': (10.31, 123.98),
  'SIN': (1.36, 103.99),
  'HKG': (22.31, 113.92),
  'ICN': (37.46, 126.44),
  'NRT': (35.77, 140.39),
  'DXB': (25.25, 55.36),
};

// Invented carriers so mock fares are never mistaken for real ones.
const _internationalCarriers = [('Bayan Air', 'BY'), ('Pacific Crest', 'PQ'), ('Lumen Airways', 'LU')];
const _domesticCarriers = [('Islas Express', 'IX'), ('Bayan Air', 'BY'), ('Isla Hop', 'IH')];

/// Departure time, fare multiplier, connecting?, baggage.
const _slots = [
  ('06:15', 1.0, false, '1 checked bag (20 kg)'),
  ('09:40', 1.18, false, 'Cabin bag only'),
  ('13:05', 0.86, true, '1 checked bag (20 kg)'),
  ('19:30', 1.07, false, '1 checked bag (23 kg)'),
];

const _deluxe = 'Deluxe King';
const _kingMeta = '1 king bed · 28 m² · sleeps 2';
const _twin = 'Twin Room';
const _twinMeta = '2 single beds · 26 m² · sleeps 2';

const _hotels = [
  Hotel(
    id: 'mnl-t3-garden',
    airportCode: 'MNL',
    name: 'Terminal 3 Garden Hotel',
    area: 'Pasay City',
    distanceKm: 0.4,
    distanceFrom: 'Terminal 3',
    score: 8.7,
    reviews: 1204,
    tags: [kTagShuttle, 'Outdoor pool', 'Breakfast'],
    badge: 'Closest to terminal',
    rooms: [
      Room(id: 'king', name: _deluxe, meta: _kingMeta, nightlyRate: 4850, cancellation: 'Free cancellation until 2 days before'),
      Room(id: 'twin', name: _twin, meta: _twinMeta, nightlyRate: 4400),
    ],
  ),
  Hotel(
    id: 'mnl-bay-suites',
    airportCode: 'MNL',
    name: 'Bay Airport Suites',
    area: 'Parañaque',
    distanceKm: 1.2,
    distanceFrom: 'Terminal 1',
    score: 8.2,
    reviews: 860,
    tags: ['24h front desk', 'Late checkout'],
    badge: 'Best price',
    rooms: [
      Room(id: 'king', name: 'Studio King', meta: '1 king bed · 24 m² · sleeps 2', nightlyRate: 3920, cancellation: 'Free cancellation until 1 day before'),
      Room(id: 'twin', name: _twin, meta: _twinMeta, nightlyRate: 3650),
    ],
  ),
  Hotel(
    id: 'mnl-skyline',
    airportCode: 'MNL',
    name: 'Pasay Skyline Residences',
    area: 'Pasay City',
    distanceKm: 2.6,
    distanceFrom: 'Terminal 3',
    score: 9.0,
    reviews: 532,
    tags: [kTagShuttle, 'Kitchenette', 'Gym'],
    rooms: [
      Room(id: 'suite', name: 'One-Bedroom Suite', meta: '1 king bed · 45 m² · sleeps 3', nightlyRate: 6300, cancellation: 'Free cancellation until 3 days before'),
    ],
  ),
  Hotel(
    id: 'mnl-bayside',
    airportCode: 'MNL',
    name: 'Manila Bayside Inn',
    area: 'Pasay City',
    distanceKm: 4.1,
    distanceFrom: 'Terminal 3',
    score: 7.8,
    reviews: 2110,
    tags: ['Breakfast', 'Bay view'],
    rooms: [
      Room(id: 'twin', name: 'Standard Twin', meta: _twinMeta, nightlyRate: 2780, cancellation: 'Free cancellation until 1 day before'),
    ],
  ),
  Hotel(
    id: 'crk-freeport',
    airportCode: 'CRK',
    name: 'Freeport Runway Hotel',
    area: 'Clark Freeport Zone',
    distanceKm: 0.8,
    distanceFrom: 'Terminal 2',
    score: 8.5,
    reviews: 640,
    tags: [kTagShuttle, 'Outdoor pool'],
    badge: 'Closest to terminal',
    rooms: [
      Room(id: 'king', name: _deluxe, meta: _kingMeta, nightlyRate: 4100, cancellation: 'Free cancellation until 2 days before'),
    ],
  ),
  Hotel(
    id: 'crk-fairway',
    airportCode: 'CRK',
    name: 'Fairway Lodge Clark',
    area: 'Clark Freeport Zone',
    distanceKm: 5.3,
    distanceFrom: 'Terminal 2',
    score: 8.9,
    reviews: 318,
    tags: ['Golf view', 'Breakfast'],
    rooms: [
      Room(id: 'king', name: 'Fairway King', meta: _kingMeta, nightlyRate: 5200, cancellation: 'Free cancellation until 3 days before'),
      Room(id: 'twin', name: _twin, meta: _twinMeta, nightlyRate: 4800),
    ],
  ),
  Hotel(
    id: 'ceb-mactan-gate',
    airportCode: 'CEB',
    name: 'Mactan Gateway Hotel',
    area: 'Lapu-Lapu City',
    distanceKm: 0.6,
    distanceFrom: 'Terminal 1',
    score: 8.3,
    reviews: 975,
    tags: [kTagShuttle, '24h front desk'],
    badge: 'Closest to terminal',
    rooms: [
      Room(id: 'king', name: _deluxe, meta: _kingMeta, nightlyRate: 3700, cancellation: 'Free cancellation until 1 day before'),
    ],
  ),
  Hotel(
    id: 'ceb-reef',
    airportCode: 'CEB',
    name: 'Reefside Resort Mactan',
    area: 'Punta Engaño',
    distanceKm: 9.8,
    distanceFrom: 'Terminal 2',
    score: 9.1,
    reviews: 1488,
    tags: ['Beachfront', 'Outdoor pool', 'Spa'],
    rooms: [
      Room(id: 'king', name: 'Ocean King', meta: '1 king bed · 38 m² · sleeps 2', nightlyRate: 8900, cancellation: 'Free cancellation until 5 days before'),
    ],
  ),
];

const _courses = [
  GolfCourse(id: 'mnl-bayshore', airportCode: 'MNL', name: 'Bayshore Links', holes: 18, par: 72, driveMinutes: 25, pricePerPlayer: 6200, inclusion: 'buggy included', teeTimes: ['06:40', '07:10', '07:50', '09:20']),
  GolfCourse(id: 'mnl-sierra', airportCode: 'MNL', name: 'Sierra Verde Golf Club', holes: 18, par: 71, driveMinutes: 45, pricePerPlayer: 7800, inclusion: 'caddy included', teeTimes: ['06:00', '06:30', '08:10']),
  GolfCourse(id: 'mnl-cavite', airportCode: 'MNL', name: 'Cavite Hills Country Club', holes: 27, par: 72, driveMinutes: 55, pricePerPlayer: 5400, teeTimes: ['07:00', '11:30']),
  GolfCourse(id: 'crk-sapang', airportCode: 'CRK', name: 'Sapang Bato Golf Club', holes: 18, par: 72, driveMinutes: 15, pricePerPlayer: 5900, inclusion: 'buggy included', teeTimes: ['06:20', '07:40', '13:10']),
  GolfCourse(id: 'crk-pinatubo', airportCode: 'CRK', name: 'Pinatubo Ridge Links', holes: 18, par: 70, driveMinutes: 30, pricePerPlayer: 4800, teeTimes: ['06:00', '08:30', '10:00', '14:20']),
  GolfCourse(id: 'ceb-mactan', airportCode: 'CEB', name: 'Mactan Island Golf', holes: 18, par: 72, driveMinutes: 20, pricePerPlayer: 5600, inclusion: 'caddy included', teeTimes: ['06:30', '07:20', '15:00']),
];

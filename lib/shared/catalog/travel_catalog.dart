/// Travel catalogue: arrival airports and the stays and golf courses near them.
///
/// Every feature reads data through [TravelCatalog]. Today the only
/// implementation is [MockTravelCatalog]; an API-backed one can replace it
/// later without touching the views.
library;

import 'dart:math';
import 'package:cheapest_go_mobile/shared/utils/format.dart';

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

  /// Destination photo, bundled for arrival airports only.
  String? get photo => _placeCodes.contains(code) ? 'assets/images/places/${code.toLowerCase()}.jpg' : null;
}

const _placeCodes = {'MNL', 'CRK', 'CEB', 'DVO', 'KLO', 'PPS', 'TAG', 'ILO', 'BKK', 'DPS'};
const _hotelPhotoCount = 24;
const _roomPhotoCount = 11;
const _golfPhotoCount = 16;

/// Stable small hash of an id, so a hotel keeps the same photos every launch.
int _seed(String id) => id.codeUnits.fold(7, (h, c) => (h * 31 + c) & 0x7fffffff);

String _pick(String folder, String prefix, int count, int n) =>
    'assets/images/$folder/$prefix${((n % count) + 1).toString().padLeft(2, '0')}.jpg';

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

  /// Cover first, then two room shots (mock photos, see assets/images/README.md).
  List<String> get photos {
    final s = _seed(id);
    final room = s % _roomPhotoCount;
    // Offset 1…count-1 from the first room, so the two room shots differ.
    final otherRoom = room + 1 + (s ~/ 7) % (_roomPhotoCount - 1);
    return [
      _pick('hotels', 'h', _hotelPhotoCount, s),
      _pick('rooms', 'r', _roomPhotoCount, room),
      _pick('rooms', 'r', _roomPhotoCount, otherRoom),
    ];
  }

  String get cover => photos.first;

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

  /// Course photo (mock, see assets/images/README.md).
  String get photo => _pick('golf', 'g', _golfPhotoCount, _seed(id));

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
  List<Airport> origins() => [..._airports, ..._originsAbroad];

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
    final domestic = _isPhilippine(from) && _isPhilippine(to);
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

  static bool _isPhilippine(String code) =>
      _airports.any((a) => a.code == code && a.country == 'Philippines');

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
  Airport(code: 'DVO', name: 'Francisco Bangoy International', city: 'Davao', country: 'Philippines', terminals: 'Main terminal'),
  Airport(code: 'KLO', name: 'Kalibo International', city: 'Kalibo (Boracay)', country: 'Philippines', terminals: 'Main terminal'),
  Airport(code: 'PPS', name: 'Puerto Princesa International', city: 'Puerto Princesa', country: 'Philippines', terminals: 'Main terminal'),
  Airport(code: 'TAG', name: 'Bohol–Panglao International', city: 'Bohol', country: 'Philippines', terminals: 'Main terminal'),
  Airport(code: 'ILO', name: 'Iloilo International', city: 'Iloilo', country: 'Philippines', terminals: 'Main terminal'),
  Airport(code: 'BKK', name: 'Suvarnabhumi', city: 'Bangkok', country: 'Thailand', terminals: 'Main terminal'),
  Airport(code: 'DPS', name: 'Ngurah Rai International', city: 'Bali', country: 'Indonesia', terminals: 'Domestic + international'),
];

const _originsAbroad = [
  Airport(code: 'SIN', name: 'Changi', city: 'Singapore', country: 'Singapore', terminals: 'Terminals 1–4'),
  Airport(code: 'HKG', name: 'Hong Kong International', city: 'Hong Kong', country: 'Hong Kong', terminals: 'Terminals 1–2'),
  Airport(code: 'ICN', name: 'Incheon International', city: 'Seoul', country: 'South Korea', terminals: 'Terminals 1–2'),
  Airport(code: 'NRT', name: 'Narita International', city: 'Tokyo', country: 'Japan', terminals: 'Terminals 1–3'),
  Airport(code: 'KIX', name: 'Kansai International', city: 'Osaka', country: 'Japan', terminals: 'Terminals 1–2'),
  Airport(code: 'TPE', name: 'Taoyuan International', city: 'Taipei', country: 'Taiwan', terminals: 'Terminals 1–2'),
  Airport(code: 'KUL', name: 'Kuala Lumpur International', city: 'Kuala Lumpur', country: 'Malaysia', terminals: 'Terminals 1–2'),
  Airport(code: 'SGN', name: 'Tan Son Nhat International', city: 'Ho Chi Minh City', country: 'Vietnam', terminals: 'Terminals 1–2'),
  Airport(code: 'SYD', name: 'Sydney Kingsford Smith', city: 'Sydney', country: 'Australia', terminals: 'Terminals 1–3'),
  Airport(code: 'DXB', name: 'Dubai International', city: 'Dubai', country: 'United Arab Emirates', terminals: 'Terminals 1–3'),
  Airport(code: 'LAX', name: 'Los Angeles International', city: 'Los Angeles', country: 'United States', terminals: 'Terminals 1–8'),
];

/// Latitude, longitude per airport, for mock flight times and fares.
const _coords = <String, (double, double)>{
  'MNL': (14.51, 121.02),
  'CRK': (15.19, 120.56),
  'CEB': (10.31, 123.98),
  'DVO': (7.13, 125.65),
  'KLO': (11.68, 122.38),
  'PPS': (9.74, 118.76),
  'TAG': (9.57, 123.77),
  'ILO': (10.83, 122.49),
  'BKK': (13.69, 100.75),
  'DPS': (-8.75, 115.17),
  'SIN': (1.36, 103.99),
  'HKG': (22.31, 113.92),
  'ICN': (37.46, 126.44),
  'NRT': (35.77, 140.39),
  'KIX': (34.43, 135.24),
  'TPE': (25.08, 121.23),
  'KUL': (2.75, 101.71),
  'SGN': (10.82, 106.66),
  'SYD': (-33.95, 151.18),
  'DXB': (25.25, 55.36),
  'LAX': (33.94, -118.41),
};

// Invented carriers so mock fares are never mistaken for real ones.
const _internationalCarriers = [('Bayan Air', 'BY'), ('Pacific Crest', 'PQ'), ('Lumen Airways', 'LU'), ('Monsoon Air', 'MO')];
const _domesticCarriers = [('Islas Express', 'IX'), ('Bayan Air', 'BY'), ('Isla Hop', 'IH')];

/// Departure time, fare multiplier, connecting?, baggage.
const _slots = [
  ('06:15', 1.0, false, '1 checked bag (20 kg)'),
  ('09:40', 1.18, false, 'Cabin bag only'),
  ('13:05', 0.86, true, '1 checked bag (20 kg)'),
  ('16:50', 0.93, true, 'Cabin bag only'),
  ('19:30', 1.07, false, '1 checked bag (23 kg)'),
];

const _deluxe = 'Deluxe King';
const _kingMeta = '1 king bed · 28 m² · sleeps 2';
const _twin = 'Twin Room';
const _twinMeta = '2 single beds · 26 m² · sleeps 2';

const _coreHotels = [
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

const _coreCourses = [
  GolfCourse(id: 'mnl-bayshore', airportCode: 'MNL', name: 'Bayshore Links', holes: 18, par: 72, driveMinutes: 25, pricePerPlayer: 6200, inclusion: 'buggy included', teeTimes: ['06:40', '07:10', '07:50', '09:20']),
  GolfCourse(id: 'mnl-sierra', airportCode: 'MNL', name: 'Sierra Verde Golf Club', holes: 18, par: 71, driveMinutes: 45, pricePerPlayer: 7800, inclusion: 'caddy included', teeTimes: ['06:00', '06:30', '08:10']),
  GolfCourse(id: 'mnl-cavite', airportCode: 'MNL', name: 'Cavite Hills Country Club', holes: 27, par: 72, driveMinutes: 55, pricePerPlayer: 5400, teeTimes: ['07:00', '11:30']),
  GolfCourse(id: 'crk-sapang', airportCode: 'CRK', name: 'Sapang Bato Golf Club', holes: 18, par: 72, driveMinutes: 15, pricePerPlayer: 5900, inclusion: 'buggy included', teeTimes: ['06:20', '07:40', '13:10']),
  GolfCourse(id: 'crk-pinatubo', airportCode: 'CRK', name: 'Pinatubo Ridge Links', holes: 18, par: 70, driveMinutes: 30, pricePerPlayer: 4800, teeTimes: ['06:00', '08:30', '10:00', '14:20']),
  GolfCourse(id: 'ceb-mactan', airportCode: 'CEB', name: 'Mactan Island Golf', holes: 18, par: 72, driveMinutes: 20, pricePerPlayer: 5600, inclusion: 'caddy included', teeTimes: ['06:30', '07:20', '15:00']),
];

final List<Hotel> _hotels = [..._coreHotels, ..._moreHotels];
final List<GolfCourse> _courses = [..._coreCourses, ..._moreCourses];

int _r10(num v) => (v / 10).round() * 10;

/// A stay with the usual room line-up: a refundable king, a cheaper
/// non-refundable twin, and optionally a suite.
Hotel _stay(
  String id,
  String airportCode,
  String name,
  String area,
  double km,
  String from,
  double score,
  int reviews,
  int rate,
  List<String> tags, {
  String? badge,
  bool suite = false,
  int freeDays = 2,
}) {
  final cancel = 'Free cancellation until ${plural(freeDays, 'day')} before';
  return Hotel(
    id: id,
    airportCode: airportCode,
    name: name,
    area: area,
    distanceKm: km,
    distanceFrom: from,
    score: score,
    reviews: reviews,
    tags: tags,
    badge: badge,
    rooms: [
      Room(id: 'king', name: _deluxe, meta: _kingMeta, nightlyRate: rate, cancellation: cancel),
      Room(id: 'twin', name: _twin, meta: _twinMeta, nightlyRate: _r10(rate * 0.9)),
      if (suite)
        Room(id: 'suite', name: 'One-Bedroom Suite', meta: '1 king bed · 48 m² · sleeps 3', nightlyRate: _r10(rate * 1.65), cancellation: cancel),
    ],
  );
}

const _pool = 'Outdoor pool';
const _bfast = 'Breakfast';
const _spa = 'Spa';
const _gym = 'Gym';
const _beach = 'Beachfront';
const _desk = '24h front desk';
const _late = 'Late checkout';
const _family = 'Family rooms';
const _golfView = 'Golf view';
const _kitchen = 'Kitchenette';

final _moreHotels = <Hotel>[
  // Manila
  _stay('mnl-aurora', 'MNL', 'Aurora Airport Hotel', 'Pasay City', 0.9, 'Terminal 1', 8.4, 1730, 4200, [kTagShuttle, _desk, _bfast]),
  _stay('mnl-resorts-tower', 'MNL', 'Newport Bay Tower', 'Pasay City', 1.6, 'Terminal 3', 8.8, 2410, 7400, [kTagShuttle, _pool, _spa, _gym], suite: true, badge: 'Top rated'),
  _stay('mnl-transit-pods', 'MNL', 'Transit Pods NAIA', 'Parañaque', 0.3, 'Terminal 3', 7.9, 3120, 1650, [_desk, _late], badge: 'Lowest price'),
  _stay('mnl-makati-loft', 'MNL', 'Makati Loft Residences', 'Makati', 6.8, 'Terminal 3', 8.9, 980, 5600, [_kitchen, _gym, _pool], suite: true),
  _stay('mnl-bgc-grand', 'MNL', 'BGC Grand Hotel', 'Taguig', 8.2, 'Terminal 3', 9.2, 1460, 8900, [_pool, _spa, _gym, _bfast], suite: true, freeDays: 3),
  _stay('mnl-ermita-heritage', 'MNL', 'Ermita Heritage Inn', 'Ermita', 9.5, 'Terminal 1', 8.1, 870, 2950, [_bfast, _family]),
  // Clark
  _stay('crk-acacia', 'CRK', 'Acacia Clark Hotel', 'Clark Freeport Zone', 3.1, 'Terminal 2', 8.7, 1120, 4600, [kTagShuttle, _pool, _bfast]),
  _stay('crk-angeles-city', 'CRK', 'Angeles City Suites', 'Angeles City', 6.4, 'Terminal 2', 7.8, 760, 2400, [_desk, _family]),
  _stay('crk-hills-resort', 'CRK', 'Sapang Hills Golf Resort', 'Clark Freeport Zone', 7.9, 'Terminal 2', 9.0, 540, 7200, [_golfView, _pool, _spa], suite: true, badge: 'Golf on site'),
  _stay('crk-parade-ground', 'CRK', 'Parade Ground Hotel', 'Clark Freeport Zone', 4.5, 'Terminal 2', 8.3, 690, 3600, [_bfast, _gym]),
  // Cebu
  _stay('ceb-lapu-bay', 'CEB', 'Lapu-Lapu Bay Hotel', 'Lapu-Lapu City', 2.4, 'Terminal 2', 8.2, 1340, 3300, [kTagShuttle, _pool]),
  _stay('ceb-shangri-cove', 'CEB', 'Coral Cove Resort', 'Punta Engaño', 8.6, 'Terminal 2', 9.3, 2870, 11200, [_beach, _pool, _spa], suite: true, badge: 'Top rated', freeDays: 5),
  _stay('ceb-it-park', 'CEB', 'IT Park Suites', 'Cebu City', 13.2, 'Terminal 1', 8.5, 1980, 3900, [_gym, _kitchen, _desk]),
  _stay('ceb-cordova-villas', 'CEB', 'Cordova Sea Villas', 'Cordova', 6.1, 'Terminal 1', 8.8, 410, 6100, [_beach, _family, _bfast]),
  _stay('ceb-hostel', 'CEB', 'Mactan Backpackers', 'Lapu-Lapu City', 1.8, 'Terminal 1', 7.6, 2240, 1200, [_desk], badge: 'Lowest price'),
  // Davao
  _stay('dvo-airport-inn', 'DVO', 'Davao Airport Inn', 'Buhangin', 0.7, 'Main terminal', 8.1, 860, 2600, [kTagShuttle, _desk, _bfast], badge: 'Closest to terminal'),
  _stay('dvo-lanang', 'DVO', 'Lanang Waterfront Hotel', 'Lanang', 3.9, 'Main terminal', 8.9, 1530, 5200, [_pool, _spa, _gym], suite: true),
  _stay('dvo-samal-beach', 'DVO', 'Samal Island Beach Resort', 'Island Garden City of Samal', 14.8, 'Main terminal', 9.1, 720, 6800, [_beach, _pool, _family], freeDays: 4),
  _stay('dvo-poblacion', 'DVO', 'Poblacion Boutique', 'Poblacion District', 9.6, 'Main terminal', 8.4, 640, 3100, [_bfast, _late]),
  _stay('dvo-eden-hills', 'DVO', 'Eden Hills Lodge', 'Toril', 22.0, 'Main terminal', 8.6, 380, 3800, [_golfView, _bfast, _family]),
  // Kalibo / Boracay
  _stay('klo-kalibo-transit', 'KLO', 'Kalibo Transit Hotel', 'Kalibo', 1.1, 'Main terminal', 7.9, 1150, 2100, [kTagShuttle, _desk], badge: 'Closest to terminal'),
  _stay('klo-white-beach', 'KLO', 'White Beach Station 2 Hotel', 'Boracay', 72.0, 'Main terminal', 8.8, 3640, 6500, [_beach, _pool, _bfast], badge: 'Beachfront'),
  _stay('klo-diniwid', 'KLO', 'Diniwid Cliff Villas', 'Boracay', 74.5, 'Main terminal', 9.4, 820, 12800, [_beach, _spa, _pool], suite: true, freeDays: 7),
  _stay('klo-bulabog', 'KLO', 'Bulabog Kite House', 'Boracay', 73.2, 'Main terminal', 8.5, 990, 3900, [_beach, _late]),
  _stay('klo-station-1', 'KLO', 'Station 1 Palms', 'Boracay', 73.8, 'Main terminal', 9.0, 1810, 8400, [_beach, _pool, _spa, _bfast], suite: true, freeDays: 5),
  _stay('klo-caticlan', 'KLO', 'Caticlan Jetty Lodge', 'Caticlan', 68.0, 'Main terminal', 7.7, 540, 1900, [_desk, _bfast], badge: 'Lowest price'),
  // Puerto Princesa
  _stay('pps-bay-walk', 'PPS', 'Baywalk Palawan Hotel', 'Puerto Princesa City', 1.4, 'Main terminal', 8.3, 1270, 3200, [kTagShuttle, _bfast], badge: 'Closest to terminal'),
  _stay('pps-honda-bay', 'PPS', 'Honda Bay Resort', 'Santa Lourdes', 12.5, 'Main terminal', 8.9, 680, 5900, [_beach, _pool, _family], freeDays: 4),
  _stay('pps-underground', 'PPS', 'Sabang River Lodge', 'Sabang', 78.0, 'Main terminal', 8.7, 450, 4800, [_beach, _bfast]),
  _stay('pps-rizal-ave', 'PPS', 'Rizal Avenue Suites', 'Puerto Princesa City', 2.2, 'Main terminal', 8.0, 910, 2500, [_desk, _kitchen]),
  _stay('pps-lagoon-villas', 'PPS', 'Lagoon Garden Villas', 'Puerto Princesa City', 4.8, 'Main terminal', 9.1, 520, 7600, [_pool, _spa], suite: true),
  // Bohol
  _stay('tag-panglao-gate', 'TAG', 'Panglao Gateway Hotel', 'Panglao', 1.9, 'Main terminal', 8.4, 760, 3500, [kTagShuttle, _pool], badge: 'Closest to terminal'),
  _stay('tag-alona-beach', 'TAG', 'Alona Beach Resort', 'Panglao', 6.2, 'Main terminal', 8.9, 2650, 6900, [_beach, _pool, _spa], suite: true, badge: 'Beachfront'),
  _stay('tag-dumaluan', 'TAG', 'Dumaluan Shore Villas', 'Panglao', 8.4, 'Main terminal', 9.2, 680, 9800, [_beach, _spa, _family], suite: true, freeDays: 5),
  _stay('tag-tagbilaran', 'TAG', 'Tagbilaran City Hotel', 'Tagbilaran City', 14.0, 'Main terminal', 7.9, 1120, 2300, [_desk, _bfast], badge: 'Lowest price'),
  _stay('tag-loboc-river', 'TAG', 'Loboc River Lodge', 'Loboc', 34.0, 'Main terminal', 8.6, 390, 4100, [_bfast, _family]),
  // Iloilo
  _stay('ilo-cabatuan', 'ILO', 'Cabatuan Airport Hotel', 'Cabatuan', 1.2, 'Main terminal', 8.0, 470, 2400, [kTagShuttle, _desk], badge: 'Closest to terminal'),
  _stay('ilo-esplanade', 'ILO', 'Esplanade River Hotel', 'Iloilo City', 18.5, 'Main terminal', 8.8, 1390, 4300, [_pool, _gym, _bfast]),
  _stay('ilo-smallville', 'ILO', 'Smallville Suites', 'Mandurriao', 17.2, 'Main terminal', 8.5, 880, 3600, [_late, _kitchen]),
  _stay('ilo-guimaras-view', 'ILO', 'Guimaras View Resort', 'Iloilo City', 21.0, 'Main terminal', 8.7, 330, 5200, [_pool, _family], suite: true),
  // Bangkok
  _stay('bkk-airport-link', 'BKK', 'Airport Link Hotel Bangkok', 'Lat Krabang', 2.3, 'Main terminal', 8.4, 4120, 2900, [kTagShuttle, _pool, _desk], badge: 'Closest to terminal'),
  _stay('bkk-riverside', 'BKK', 'Chao Phraya Riverside', 'Bang Rak', 31.0, 'Main terminal', 9.1, 2870, 7800, [_pool, _spa, _gym], suite: true, freeDays: 3),
  _stay('bkk-sukhumvit', 'BKK', 'Sukhumvit 24 Residence', 'Khlong Toei', 28.5, 'Main terminal', 8.7, 3350, 4700, [_kitchen, _pool, _gym]),
  _stay('bkk-silom-loft', 'BKK', 'Silom Loft Hotel', 'Silom', 30.2, 'Main terminal', 8.5, 1940, 3800, [_bfast, _late]),
  _stay('bkk-greens', 'BKK', 'Bangna Greens Golf Hotel', 'Bang Na', 18.0, 'Main terminal', 8.8, 760, 5600, [_golfView, _pool, _bfast], badge: 'Golf on site'),
  _stay('bkk-khaosan', 'BKK', 'Khao San Courtyard', 'Phra Nakhon', 36.0, 'Main terminal', 7.8, 5210, 1600, [_desk], badge: 'Lowest price'),
  // Bali
  _stay('dps-tuban', 'DPS', 'Tuban Airport Resort', 'Tuban', 1.0, 'International terminal', 8.5, 2340, 4400, [kTagShuttle, _beach, _pool], badge: 'Closest to terminal'),
  _stay('dps-seminyak', 'DPS', 'Seminyak Garden Villas', 'Seminyak', 11.0, 'International terminal', 9.0, 1980, 8200, [_pool, _spa, _bfast], suite: true, freeDays: 5),
  _stay('dps-ubud', 'DPS', 'Ubud Rice Terrace Lodge', 'Ubud', 37.0, 'International terminal', 9.4, 1430, 6600, [_spa, _bfast, _pool], freeDays: 5),
  _stay('dps-nusa-dua', 'DPS', 'Nusa Dua Lagoon Resort', 'Nusa Dua', 12.5, 'International terminal', 9.2, 2760, 10400, [_beach, _pool, _spa, _family], suite: true, badge: 'Top rated', freeDays: 7),
  _stay('dps-canggu', 'DPS', 'Canggu Surf House', 'Canggu', 19.0, 'International terminal', 8.6, 1150, 3700, [_beach, _late, _kitchen]),
  _stay('dps-jimbaran', 'DPS', 'Jimbaran Cliff Hotel', 'Jimbaran', 6.5, 'International terminal', 8.9, 870, 7100, [_beach, _spa, _golfView], suite: true),
];

const _moreCourses = <GolfCourse>[
  // Manila (keep Bayshore's 06:40 the only one at that time)
  GolfCourse(id: 'mnl-fort-links', airportCode: 'MNL', name: 'Fort Links Golf Club', holes: 18, par: 72, driveMinutes: 35, pricePerPlayer: 8900, inclusion: 'buggy + caddy', teeTimes: ['06:10', '07:30', '13:40']),
  GolfCourse(id: 'mnl-laguna-lakes', airportCode: 'MNL', name: 'Laguna Lakes Country Club', holes: 36, par: 72, driveMinutes: 70, pricePerPlayer: 4900, teeTimes: ['05:50', '07:15', '12:20', '14:00']),
  // Clark
  GolfCourse(id: 'crk-mimosa-greens', airportCode: 'CRK', name: 'Mimosa Greens', holes: 36, par: 72, driveMinutes: 10, pricePerPlayer: 6500, inclusion: 'buggy included', teeTimes: ['06:00', '06:45', '08:20', '15:30']),
  // Cebu
  GolfCourse(id: 'ceb-alta-vista', airportCode: 'CEB', name: 'Alta Vista Highlands', holes: 18, par: 72, driveMinutes: 45, pricePerPlayer: 6900, inclusion: 'caddy included', teeTimes: ['06:00', '07:40', '09:10']),
  GolfCourse(id: 'ceb-mountain-view', airportCode: 'CEB', name: 'Mountain View Golf Cebu', holes: 18, par: 70, driveMinutes: 60, pricePerPlayer: 4500, teeTimes: ['06:20', '10:30', '13:00']),
  // Davao
  GolfCourse(id: 'dvo-apo-links', airportCode: 'DVO', name: 'Apo Links Golf Club', holes: 18, par: 72, driveMinutes: 25, pricePerPlayer: 4200, inclusion: 'caddy included', teeTimes: ['06:00', '06:50', '08:30', '14:10']),
  GolfCourse(id: 'dvo-rancho', airportCode: 'DVO', name: 'Rancho Palos Country Club', holes: 18, par: 71, driveMinutes: 40, pricePerPlayer: 3600, teeTimes: ['06:30', '09:00', '13:30']),
  // Boracay
  GolfCourse(id: 'klo-fairways', airportCode: 'KLO', name: 'Boracay Fairways', holes: 18, par: 72, driveMinutes: 95, pricePerPlayer: 7600, inclusion: 'buggy + caddy', teeTimes: ['06:30', '08:00', '15:00']),
  // Palawan
  GolfCourse(id: 'pps-bay-greens', airportCode: 'PPS', name: 'Palawan Bay Greens', holes: 9, par: 36, driveMinutes: 20, pricePerPlayer: 2800, teeTimes: ['06:00', '07:00', '16:00']),
  // Bohol
  GolfCourse(id: 'tag-panglao-ridge', airportCode: 'TAG', name: 'Panglao Ridge Golf', holes: 18, par: 72, driveMinutes: 15, pricePerPlayer: 5200, inclusion: 'buggy included', teeTimes: ['06:15', '07:45', '14:30']),
  GolfCourse(id: 'tag-chocolate-hills', airportCode: 'TAG', name: 'Chocolate Hills Golf', holes: 9, par: 35, driveMinutes: 80, pricePerPlayer: 2600, teeTimes: ['07:00', '10:00']),
  // Iloilo
  GolfCourse(id: 'ilo-santa-barbara', airportCode: 'ILO', name: 'Santa Barbara Golf Club', holes: 18, par: 72, driveMinutes: 10, pricePerPlayer: 3400, inclusion: 'caddy included', teeTimes: ['06:00', '07:20', '09:40', '15:00']),
  GolfCourse(id: 'ilo-riverside', airportCode: 'ILO', name: 'Iloilo Riverside Links', holes: 18, par: 70, driveMinutes: 30, pricePerPlayer: 3900, teeTimes: ['06:30', '12:00']),
  // Bangkok
  GolfCourse(id: 'bkk-bangna', airportCode: 'BKK', name: 'Bang Na Lakeside Golf', holes: 27, par: 72, driveMinutes: 20, pricePerPlayer: 5900, inclusion: 'caddy + buggy', teeTimes: ['06:00', '06:35', '07:10', '12:40']),
  GolfCourse(id: 'bkk-royal-lakes', airportCode: 'BKK', name: 'Royal Lakes Country Club', holes: 18, par: 72, driveMinutes: 35, pricePerPlayer: 8400, inclusion: 'caddy included', teeTimes: ['06:20', '07:50', '13:20']),
  GolfCourse(id: 'bkk-river-bend', airportCode: 'BKK', name: 'River Bend Golf', holes: 18, par: 71, driveMinutes: 50, pricePerPlayer: 4600, teeTimes: ['05:55', '08:15', '14:45']),
  GolfCourse(id: 'bkk-pattaya-hills', airportCode: 'BKK', name: 'Pattaya Hills Golf Resort', holes: 27, par: 72, driveMinutes: 85, pricePerPlayer: 6300, inclusion: 'buggy included', teeTimes: ['06:40', '08:00', '11:10']),
  // Bali
  GolfCourse(id: 'dps-cliffside', airportCode: 'DPS', name: 'Cliffside Golf Bali', holes: 18, par: 72, driveMinutes: 25, pricePerPlayer: 11800, inclusion: 'buggy + caddy', teeTimes: ['06:30', '07:40', '15:20']),
  GolfCourse(id: 'dps-nusa-greens', airportCode: 'DPS', name: 'Nusa Greens Golf', holes: 18, par: 72, driveMinutes: 15, pricePerPlayer: 9200, inclusion: 'caddy included', teeTimes: ['06:00', '07:10', '08:30', '14:00']),
  GolfCourse(id: 'dps-highland-lake', airportCode: 'DPS', name: 'Highland Lake Golf', holes: 18, par: 72, driveMinutes: 95, pricePerPlayer: 7400, teeTimes: ['07:00', '09:30']),
];

/// Map data built from the shared [TravelCatalog]: where stays and golf
/// courses sit around their arrival airport, and the mock flights the live
/// tracker follows.
library;

import 'dart:math' as math;
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';

export 'package:cheapest_go_mobile/shared/lib/map_tier.dart';

/// Latitude and longitude in degrees.
typedef LatLng = (double lat, double lng);

/// What the airport sheet and the map show for the selected airport.
enum MapFilter { overview, stays, golf, flights }

/// A stay or golf course pinned on the map.
class MapPlace {
  const MapPlace.hotel(Hotel this.hotel, this.position) : course = null;
  const MapPlace.course(GolfCourse this.course, this.position) : hotel = null;

  final Hotel? hotel;
  final GolfCourse? course;
  final LatLng position;

  String get id => hotel?.id ?? course!.id;
  String get name => hotel?.name ?? course!.name;
  String get airportCode => hotel?.airportCode ?? course!.airportCode;
  bool get isGolf => course != null;

  /// Nightly rate for a stay, green fee per player for a course, in pesos.
  int get price => hotel?.fromRate ?? course!.pricePerPlayer;
}

/// Rough driving speed used to place a course from its drive time.
const double _driveKmPerMinute = 0.5;

/// Stays and courses near [airport], placed at their distance from it.
///
/// The mock catalogue has no coordinates for them, so each sits on a bearing
/// derived from its id: the same spot every launch, not its real address.
List<MapPlace> placesNear(TravelCatalog catalog, Airport airport, MapFilter filter) {
  final from = (airport.latitude, airport.longitude);
  return [
    if (filter != MapFilter.golf)
      for (final h in catalog.hotelsNear(airport.code)) MapPlace.hotel(h, offsetKm(from, h.distanceKm, _bearingFor(h.id))),
    if (filter != MapFilter.stays)
      for (final c in catalog.coursesNear(airport.code))
        MapPlace.course(c, offsetKm(from, c.driveMinutes * _driveKmPerMinute, _bearingFor(c.id))),
  ];
}

/// The cheapest flight from each origin into [airport] (non-stop when there is
/// one), cheapest first; only from other countries when [abroadOnly].
List<FlightOffer> flightsInto(TravelCatalog catalog, Airport airport, {int count = 6, bool abroadOnly = false}) {
  final offers = [
    for (final origin in catalog.origins())
      if (origin.code != airport.code && (!abroadOnly || origin.country != airport.country))
        if (catalog.flights(origin.code, airport.code) case final all when all.isNotEmpty)
          all.firstWhere((f) => f.nonStop, orElse: () => all.first),
  ]..sort((a, b) => a.price.compareTo(b.price));
  return offers.take(count).toList();
}

double _bearingFor(String id) => (id.codeUnits.fold(7, (h, c) => (h * 31 + c) & 0x7fffffff) % 360).toDouble();

double _rad(double deg) => deg * math.pi / 180;
double _deg(double rad) => rad * 180 / math.pi;

const double _earthKm = 6371;

/// Great-circle distance in kilometres.
double distanceKm(LatLng a, LatLng b) {
  final dLat = _rad(b.$1 - a.$1);
  final dLng = _rad(b.$2 - a.$2);
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(a.$1)) * math.cos(_rad(b.$1)) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * _earthKm * math.asin(math.sqrt(h));
}

/// The point [km] from [from] on [bearingDeg] (0 = north, clockwise).
LatLng offsetKm(LatLng from, double km, double bearingDeg) {
  final d = km / _earthKm;
  final b = _rad(bearingDeg);
  final lat1 = _rad(from.$1);
  final lng1 = _rad(from.$2);
  final lat2 = math.asin(math.sin(lat1) * math.cos(d) + math.cos(lat1) * math.sin(d) * math.cos(b));
  final lng2 = lng1 + math.atan2(math.sin(b) * math.sin(d) * math.cos(lat1), math.cos(d) - math.sin(lat1) * math.sin(lat2));
  return (_deg(lat2), _deg(lng2));
}

/// The point a [fraction] (0–1) of the way from [a] to [b] along the great circle.
LatLng interpolate(LatLng a, LatLng b, double fraction) {
  final lat1 = _rad(a.$1), lng1 = _rad(a.$2), lat2 = _rad(b.$1), lng2 = _rad(b.$2);
  final d = distanceKm(a, b) / _earthKm;
  if (d == 0) return a;
  final f1 = math.sin((1 - fraction) * d) / math.sin(d);
  final f2 = math.sin(fraction * d) / math.sin(d);
  final x = f1 * math.cos(lat1) * math.cos(lng1) + f2 * math.cos(lat2) * math.cos(lng2);
  final y = f1 * math.cos(lat1) * math.sin(lng1) + f2 * math.cos(lat2) * math.sin(lng2);
  final z = f1 * math.sin(lat1) + f2 * math.sin(lat2);
  return (_deg(math.atan2(z, math.sqrt(x * x + y * y))), _deg(math.atan2(y, x)));
}

/// Minutes a flight spends taxiing, climbing and landing; the rest is cruise.
const int _groundMinutes = 35;

/// A mock flight into an arrival airport, followed by the live tracker.
class TrackedFlight {
  const TrackedFlight({
    required this.offer,
    required this.origin,
    required this.destination,
    required this.aircraft,
    required this.cruiseFeet,
    required this.startProgress,
  });

  final FlightOffer offer;
  final Airport origin;

  /// Always one of the catalogue's arrival airports, so the tracker can open its hub.
  final Airport destination;
  final String aircraft;
  final int cruiseFeet;

  /// How far along the route the flight is when tracking starts (0–1).
  final double startProgress;

  LatLng get from => (origin.latitude, origin.longitude);
  LatLng get to => (destination.latitude, destination.longitude);

  int get distanceNm => (distanceKm(from, to) / 1.852).round();
  Duration get duration => Duration(minutes: offer.durationMinutes);

  int get groundSpeedKnots => (distanceNm / (math.max(offer.durationMinutes - _groundMinutes, 30) / 60)).round();

  LatLng positionAt(double progress) => interpolate(from, to, progress.clamp(0.0, 1.0));
}

/// Routes the tracker follows: origin, arrival airport, aircraft, how far along.
const _trackedRoutes = [
  ('NRT', 'MNL', 'Airbus A330-300', 0.35),
  ('SIN', 'DPS', 'Boeing 737-800', 0.6),
  ('MNL', 'CEB', 'Airbus A321neo', 0.2),
  ('HKG', 'CRK', 'Airbus A320neo', 0.5),
  ('ICN', 'KLO', 'Airbus A321neo', 0.7),
];

/// The flights the live tracker cycles through, each the route's first non-stop offer.
List<TrackedFlight> trackedFlights(TravelCatalog catalog) => [
      for (final (from, to, aircraft, progress) in _trackedRoutes)
        if (catalog.origin(from) case final origin?)
          if (catalog.airport(to) case final destination?)
            for (final offer in catalog.flights(from, to).where((f) => f.nonStop).take(1))
              TrackedFlight(
                offer: offer,
                origin: origin,
                destination: destination,
                aircraft: aircraft,
                cruiseFeet: origin.country == destination.country ? 28000 : 37000,
                startProgress: progress,
              ),
    ];

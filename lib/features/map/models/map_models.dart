/// Map data built from the shared [TravelCatalog]: where stays and golf
/// courses sit around their arrival airport, and the booked flights the
/// tracker follows.
library;

import 'dart:math' as math;
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/flights/flight_status.dart';
import 'package:cheapest_go_mobile/shared/stores/bookings_store.dart';
import 'package:cheapest_go_mobile/shared/utils/geo.dart';

export 'package:cheapest_go_mobile/shared/lib/map_tier.dart';
export 'package:cheapest_go_mobile/shared/utils/geo.dart';

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

/// Default distance threshold (in kilometres) under which places are considered
/// visually overlapping at regional/airport zoom and candidates for spiderfying.
const double kSpiderfyThresholdKm = 2.5;

/// Default radial offset distance (in kilometres) used to fan out overlapping pins.
const double kSpiderfyRadiusKm = 2.4;

/// A place fanned out visually in a spiderfied group, maintaining its pure catalog data
/// and original coordinates while presenting an offset position on the map.
class SpiderfiedPlace {
  const SpiderfiedPlace({
    required this.place,
    required this.spiderPosition,
    required this.centerPosition,
  });

  /// The underlying catalog place (coordinates remain pure and untouched).
  final MapPlace place;

  /// The visually displaced position where the pin is rendered.
  final LatLng spiderPosition;

  /// The original anchor/center position of the overlapping cluster.
  final LatLng centerPosition;
}

/// A collection of overlapping places that have been expanded into a radial spider fan.
class SpiderGroup {
  const SpiderGroup({
    required this.center,
    required this.spiderPlaces,
  });

  /// The centroid anchor of the overlapping cluster.
  final LatLng center;

  /// The places in the cluster with their visual fanned-out positions.
  final List<SpiderfiedPlace> spiderPlaces;

  /// Returns the underlying places in this group.
  List<MapPlace> get places => [for (final sp in spiderPlaces) sp.place];

  /// Whether [place] belongs to this spiderfied group.
  bool contains(MapPlace place) => places.any((p) => p.id == place.id);

  /// Gets the fanned-out position for [place], or its natural position if not in this group.
  LatLng positionFor(MapPlace place) {
    for (final sp in spiderPlaces) {
      if (sp.place.id == place.id) return sp.spiderPosition;
    }
    return place.position;
  }
}

/// Finds all places in [candidates] that visually overlap with [target] within [thresholdKm].
List<MapPlace> findOverlappingPlaces(
  MapPlace target,
  List<MapPlace> candidates, {
  double thresholdKm = kSpiderfyThresholdKm,
}) =>
    [
      for (final p in candidates)
        if (distanceKm(target.position, p.position) <= thresholdKm) p,
    ];

/// Creates a [SpiderGroup] fanning out [cluster] places radially around their centroid.
///
/// Keeps original place coordinates pure. The offset is visual only.
SpiderGroup createSpiderGroup(
  List<MapPlace> cluster, {
  double radiusKm = kSpiderfyRadiusKm,
}) {
  assert(cluster.isNotEmpty, 'Cannot create a spider group from an empty cluster');
  if (cluster.length == 1) {
    final single = cluster.first;
    return SpiderGroup(
      center: single.position,
      spiderPlaces: [
        SpiderfiedPlace(
          place: single,
          spiderPosition: single.position,
          centerPosition: single.position,
        ),
      ],
    );
  }

  // Calculate centroid
  final avgLat = cluster.fold(0.0, (sum, p) => sum + p.position.$1) / cluster.length;
  final avgLng = cluster.fold(0.0, (sum, p) => sum + p.position.$2) / cluster.length;
  final center = (avgLat, avgLng);

  // Slightly enlarge the radius if there are 4+ places so they have ample breathing room
  final effectiveRadius = cluster.length > 3 ? radiusKm * (1.0 + (cluster.length - 3) * 0.15) : radiusKm;

  final n = cluster.length;
  final spiderPlaces = <SpiderfiedPlace>[];
  for (var i = 0; i < n; i++) {
    final bearingDeg = (360.0 / n * i) % 360.0;
    final fannedPos = offsetKm(center, effectiveRadius, bearingDeg);
    spiderPlaces.add(SpiderfiedPlace(
      place: cluster[i],
      spiderPosition: fannedPos,
      centerPosition: center,
    ));
  }

  return SpiderGroup(center: center, spiderPlaces: spiderPlaces);
}

/// Rough driving speed used to place a course from its drive time.
const double _driveKmPerMinute = 0.5;

/// Stays and courses near [airport], placed at their distance from it.
///
/// The mock catalogue has no coordinates for them, so each sits on a bearing
/// derived from its id, inside the airport's land directions: the same spot
/// every launch, on land, but not its real address.
List<MapPlace> placesNear(TravelCatalog catalog, Airport airport, MapFilter filter) {
  final from = (airport.latitude, airport.longitude);
  return [
    if (filter != MapFilter.golf)
      for (final h in catalog.hotelsNear(airport.code))
        MapPlace.hotel(
          h,
          h.latitude != null && h.longitude != null
              ? (h.latitude!, h.longitude!)
              : offsetKm(from, h.distanceKm, _bearingFor(airport.code, h.id)),
        ),
    if (filter != MapFilter.stays)
      for (final c in catalog.coursesNear(airport.code))
        MapPlace.course(c, offsetKm(from, c.driveMinutes * _driveKmPerMinute, _bearingFor(airport.code, c.id))),
  ];
}

/// The cheapest flight from each origin into [airport] (non-stop when there is
/// one), cheapest first.
List<FlightOffer> flightsInto(TravelCatalog catalog, Airport airport, {int count = 6}) {
  final offers = [
    for (final origin in catalog.origins())
      if (origin.code != airport.code)
        if (catalog.flights(origin.code, airport.code) case final all when all.isNotEmpty)
          all.firstWhere((f) => f.nonStop, orElse: () => all.first),
  ]..sort((a, b) => a.price.compareTo(b.price));
  return offers.take(count).toList();
}

/// Directions from each airport (start bearing, degrees clockwise from north,
/// and width) where its stays and courses can sit without landing in water.
const _landBearings = <String, (double, double)>{
  'MNL': (340, 105), // north to east-north-east; Manila Bay is west
  'CRK': (0, 360),
  'CEB': (260, 70), // Mactan is small; Cebu City is across the channel to the west
  'DVO': (200, 140), // Davao Gulf lies east
  'KLO': (130, 70), // inland Panay; the sea is north and west
  'PPS': (205, 25), // along Palawan towards Narra; the island is narrow
  'TAG': (20, 70), // Panglao is small; Bohol is north-east
  'ILO': (270, 180), // Guimaras Strait lies south
  'BKK': (250, 160), // the city side; the Gulf of Thailand is south
  'DPS': (340, 60), // north of the isthmus, towards Kuta and Denpasar
  'ICN': (60, 70), // Incheon and Songdo across the bridge, east
};

/// Extra land arcs, for airports wedged between two bodies of water.
const _moreLandBearings = <String, (double, double)>{
  'MNL': (170, 60), // south towards Imus and Dasmariñas; Laguna de Bay is south-east
};

double _bearingFor(String airportCode, String id) {
  final arcs = [_landBearings[airportCode] ?? (0.0, 360.0), ?_moreLandBearings[airportCode]];
  final total = arcs.fold(0.0, (sum, a) => sum + a.$2);
  var at = (id.codeUnits.fold(7, (h, c) => (h * 31 + c) & 0x7fffffff) % 1000) / 1000 * total;
  for (final (start, width) in arcs) {
    if (at <= width) return (start + at) % 360;
    at -= width;
  }
  return arcs.first.$1;
}

/// Minutes a flight spends taxiing, climbing and landing; the rest is cruise.
const int _groundMinutes = 35;

/// A booked flight on the tracker, with its airports resolved.
class TrackedFlight {
  const TrackedFlight({required this.booking, required this.origin, required this.destination});

  final Booking booking;
  final Airport origin;
  final Airport destination;

  BookedFlight get flight => booking.flight!;
  String get reference => booking.reference;

  LatLng get from => (origin.latitude, origin.longitude);
  LatLng get to => (destination.latitude, destination.longitude);

  int get distanceNm => (distanceKm(from, to) / 1.852).round();

  /// Typical cruise: lower on short domestic hops.
  int get cruiseFeet => origin.country == destination.country ? 28000 : 37000;

  int get groundSpeedKnots => (distanceNm / (math.max(flight.durationMinutes - _groundMinutes, 30) / 60)).round();

  LatLng positionAt(double progress) => interpolate(from, to, progress.clamp(0.0, 1.0));

  /// Whether this arrival airport has stays and golf to hand over to.
  bool hasHub(TravelCatalog catalog) => catalog.airport(destination.code) != null;
}

/// The booked flights worth tracking at [nowFor] (each booking's now, which a
/// debug replay can shift): not yet landed, or landed within
/// [kTrackAfterLanding]; earliest departure first.
List<TrackedFlight> trackableFlights(
  TravelCatalog catalog,
  List<Booking> flightBookings,
  DateTime Function(String reference) nowFor,
) =>
    [
      for (final b in flightBookings)
        if (nowFor(b.reference).isBefore(b.flight!.arrivalUtc.add(kTrackAfterLanding)))
          if (catalog.origin(b.flight!.origin) case final origin?)
            if (catalog.origin(b.flight!.destination) case final destination?)
              TrackedFlight(booking: b, origin: origin, destination: destination),
    ];

/// Pixels between pins, at the map's zoom, under which they merge into a cluster.
const double kClusterRadiusPx = 34;

/// Groups [points] whose pins would sit within [radiusPx] of each other at
/// [zoom] (Web Mercator, Mapbox's 512 px world). Each group is a list of
/// indices into [points]; a group of one is a pin on its own.
///
/// Greedy and stable: points are taken in order and each one gathers the
/// unclaimed points near it, so the same input always clusters the same way.
List<List<int>> clusterGroups(List<LatLng> points, double zoom, {double radiusPx = kClusterRadiusPx}) {
  final scale = 512 * math.pow(2, zoom);
  final xs = [for (final p in points) (p.$2 + 180) / 360 * scale];
  final ys = [
    for (final p in points) (1 - math.log(math.tan(math.pi / 4 + p.$1.clamp(-85.0, 85.0) * math.pi / 360)) / math.pi) / 2 * scale,
  ];
  final claimed = List<bool>.filled(points.length, false);
  final groups = <List<int>>[];
  for (var i = 0; i < points.length; i++) {
    if (claimed[i]) continue;
    claimed[i] = true;
    final group = [i];
    for (var j = i + 1; j < points.length; j++) {
      if (claimed[j]) continue;
      final dx = xs[i] - xs[j], dy = ys[i] - ys[j];
      if (dx * dx + dy * dy <= radiusPx * radiusPx) {
        claimed[j] = true;
        group.add(j);
      }
    }
    groups.add(group);
  }
  return groups;
}

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
      for (final h in catalog.hotelsNear(airport.code)) MapPlace.hotel(h, offsetKm(from, h.distanceKm, _bearingFor(airport.code, h.id))),
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
/// and width) where its stays and courses can sit without landing in the sea.
const _landBearings = <String, (double, double)>{
  'MNL': (340, 190), // Manila Bay lies west
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

double _bearingFor(String airportCode, String id) {
  final (start, width) = _landBearings[airportCode] ?? (0.0, 360.0);
  final unit = (id.codeUnits.fold(7, (h, c) => (h * 31 + c) & 0x7fffffff) % 1000) / 1000;
  return (start + unit * width) % 360;
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

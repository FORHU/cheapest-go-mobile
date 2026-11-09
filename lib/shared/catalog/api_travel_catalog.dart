import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/lib/http.dart';

/// Live API-backed catalogue for hotels and flights, talking to `cheapestgo-api-v2`.
///
/// Falls back to local [SharedPreferences] cache when offline, and marks
/// queries with [isOfflineData] so views can display the offline saved results notice.
/// Golf courses delegate to [MockTravelCatalog] until a golf API exists.
class ApiTravelCatalog implements TravelCatalog {
  ApiTravelCatalog({
    HttpClientAdapter? client,
    SharedPreferences? prefs,
    MockTravelCatalog? mockFallback,
  })  : _client = client ?? http,
        _mock = mockFallback ?? const MockTravelCatalog() {
    _prefs = prefs;
  }

  final HttpClientAdapter _client;
  SharedPreferences? _prefs;
  final MockTravelCatalog _mock;

  final Map<String, List<Hotel>> _hotelsByAirport = {};
  final Map<String, Hotel> _hotelById = {};
  final Map<String, List<FlightOffer>> _flightsByRoute = {};
  final Map<String, FlightOffer> _flightById = {};
  final Set<String> _offlineKeys = {};

  Future<SharedPreferences> _getPrefs() async => _prefs ??= await SharedPreferences.getInstance();

  @override
  List<Airport> airports() => _mock.airports();

  @override
  Airport? airport(String code) => _mock.airport(code);

  @override
  List<Airport> origins() => _mock.origins();

  @override
  Airport? origin(String code) => _mock.origin(code);

  @override
  List<GolfCourse> coursesNear(String airportCode) => _mock.coursesNear(airportCode);

  @override
  GolfCourse? course(String id) => _mock.course(id);

  @override
  List<Hotel> hotelsNear(String airportCode) {
    final cached = _hotelsByAirport[airportCode];
    if (cached != null && cached.isNotEmpty) return cached;
    return _mock.hotelsNear(airportCode);
  }

  @override
  Hotel? hotel(String id) {
    return _hotelById[id] ?? _mock.hotel(id);
  }

  @override
  List<FlightOffer> flights(String from, String to) {
    final routeKey = '${from}_$to';
    final cached = _flightsByRoute[routeKey];
    if (cached != null && cached.isNotEmpty) return cached;
    return _mock.flights(from, to);
  }

  @override
  FlightOffer? flight(String id) {
    return _flightById[id] ?? _mock.flight(id);
  }

  @override
  bool isOfflineData(String key) => _offlineKeys.contains(key);

  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static String _countryCode(String country) {
    switch (country.toLowerCase()) {
      case 'philippines':
        return 'PH';
      case 'thailand':
        return 'TH';
      case 'indonesia':
        return 'ID';
      case 'south korea':
        return 'KR';
      case 'singapore':
        return 'SG';
      case 'japan':
        return 'JP';
      case 'malaysia':
        return 'MY';
      case 'vietnam':
        return 'VN';
      case 'taiwan':
        return 'TW';
      case 'hong kong':
        return 'HK';
      default:
        return 'PH';
    }
  }

  @override
  Future<List<Hotel>> fetchHotels(
    String airportCode, {
    DateTime? checkIn,
    DateTime? checkOut,
    int? adults,
  }) async {
    final ap = airport(airportCode);
    if (ap == null) return const [];

    final now = DateTime.now();
    final inDate = checkIn ?? now.add(const Duration(days: 14));
    final outDate = checkOut ?? inDate.add(const Duration(days: 3));

    final body = {
      'destination': ap.city,
      'checkIn': _formatDate(inDate),
      'checkOut': _formatDate(outDate),
      'adults': adults ?? 2,
      'children': 0,
      'rooms': 1,
      'lat': ap.latitude,
      'lng': ap.longitude,
      'countryCode': _countryCode(ap.country),
      'currency': 'PHP',
    };

    try {
      final res = await _client.post(
        '/api/v2/hotels/search',
        body: body,
        options: const HttpRequestOptions(useMobileApiKey: true, requiresAuth: false),
      );

      final list = <Hotel>[];
      if (res is Map<String, dynamic> && res['data'] is List) {
        for (final item in (res['data'] as List)) {
          if (item is Map<String, dynamic>) {
            final h = _parseHotelFromSearch(item, ap);
            list.add(h);
            _hotelById[h.id] = h;
          }
        }
      }

      if (list.isNotEmpty) {
        list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        _hotelsByAirport[airportCode] = list;
        _offlineKeys.remove(airportCode);

        // Persist to local disk cache for offline access
        final prefs = await _getPrefs();
        final raw = jsonEncode(list.map((h) => h.toJson()).toList());
        await prefs.setString('cheapestgo_cache_hotels_$airportCode', raw);
        return list;
      }
    } catch (_) {
      // Network failed or API unavailable: fallback to disk cache
    }

    // Attempt loading from SharedPreferences
    final prefs = await _getPrefs();
    final cachedJson = prefs.getString('cheapestgo_cache_hotels_$airportCode');
    if (cachedJson != null && cachedJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedJson) as List;
        final cachedHotels = decoded
            .map((e) => Hotel.fromJson(e as Map<String, dynamic>))
            .toList();
        _hotelsByAirport[airportCode] = cachedHotels;
        for (final h in cachedHotels) {
          _hotelById[h.id] = h;
        }
        _offlineKeys.add(airportCode);
        return cachedHotels;
      } catch (_) {}
    }

    // Final fallback to mock catalog when neither network nor cache is available
    final mockHotels = _mock.hotelsNear(airportCode);
    _hotelsByAirport[airportCode] = mockHotels;
    _offlineKeys.add(airportCode);
    return mockHotels;
  }

  @override
  Future<Hotel?> fetchHotel(
    String id, {
    DateTime? checkIn,
    DateTime? checkOut,
    int? adults,
  }) async {
    final now = DateTime.now();
    final inDate = checkIn ?? now.add(const Duration(days: 14));
    final outDate = checkOut ?? inDate.add(const Duration(days: 3));

    try {
      final res = await _client.get(
        '/api/v2/hotels/property/$id?checkIn=${_formatDate(inDate)}&checkOut=${_formatDate(outDate)}&adults=${adults ?? 2}',
        options: const HttpRequestOptions(useMobileApiKey: true, requiresAuth: false),
      );

      if (res is Map<String, dynamic>) {
        final content = res['content'] as Map<String, dynamic>?;
        final rawRooms = res['rooms'] as List?;
        final existing = _hotelById[id] ?? _mock.hotel(id);

        if (content != null) {
          final images = (content['images'] as List?)?.map((e) => e.toString()).toList() ??
              existing?.images ??
              const [];
          final rooms = <Room>[];
          if (rawRooms != null && rawRooms.isNotEmpty) {
            for (var i = 0; i < rawRooms.length; i++) {
              final r = rawRooms[i];
              if (r is Map<String, dynamic>) {
                rooms.add(Room(
                  id: r['offerId']?.toString() ?? r['roomCode']?.toString() ?? '${id}_r$i',
                  name: r['roomName']?.toString() ?? 'Room ${i + 1}',
                  meta: r['boardCode']?.toString() ?? 'Room only',
                  nightlyRate: (r['price'] as num?)?.round() ??
                      (r['gross'] as num?)?.round() ??
                      (existing?.fromRate ?? 5000),
                  cancellation: r['refundable'] == true
                      ? (r['refundableTag']?.toString() ?? 'Free cancellation')
                      : null,
                ));
              }
            }
          }
          if (rooms.isEmpty && existing != null) {
            rooms.addAll(existing.rooms);
          }

          final updated = Hotel(
            id: id,
            airportCode: existing?.airportCode ?? 'MNL',
            name: content['name']?.toString() ?? existing?.name ?? 'Hotel',
            area: content['city']?.toString() ?? existing?.area ?? 'City',
            distanceKm: existing?.distanceKm ?? 3.0,
            distanceFrom: existing?.distanceFrom ?? 'Terminal',
            score: (content['rating'] as num?)?.toDouble() ??
                (content['reviewRating'] as num?)?.toDouble() ??
                existing?.score ??
                8.5,
            reviews: (content['reviews'] as num?)?.toInt() ??
                (content['reviewCount'] as num?)?.toInt() ??
                existing?.reviews ??
                100,
            tags: existing?.tags ?? const [],
            rooms: rooms.isNotEmpty
                ? rooms
                : [
                    Room(
                      id: '${id}_default',
                      name: 'Standard Room',
                      meta: 'Room only',
                      nightlyRate: 5000,
                    ),
                  ],
            badge: existing?.badge,
            images: images,
            latitude: (content['lat'] as num?)?.toDouble() ?? existing?.latitude,
            longitude: (content['lng'] as num?)?.toDouble() ?? existing?.longitude,
            address: content['address']?.toString() ?? existing?.address,
            description: content['description']?.toString() ?? existing?.description,
          );
          _hotelById[id] = updated;
          return updated;
        }
      }
    } catch (_) {}

    return _hotelById[id] ?? _mock.hotel(id);
  }

  @override
  Future<List<FlightOffer>> fetchFlights(
    String from,
    String to, {
    DateTime? departureDate,
    int? adults,
  }) async {
    final routeKey = '${from}_$to';
    final now = DateTime.now();
    final depDate = departureDate ?? now.add(const Duration(days: 14));

    final body = {
      'origin': from,
      'destination': to,
      'departureDate': _formatDate(depDate),
      'adults': adults ?? 1,
      'cabinClass': 'economy',
      'tripType': 'one-way',
    };

    try {
      final res = await _client.post(
        '/api/v2/flights/search',
        body: body,
        options: const HttpRequestOptions(useMobileApiKey: true, requiresAuth: false),
      );

      final list = <FlightOffer>[];
      if (res is Map<String, dynamic> && res['offers'] is List) {
        final offers = res['offers'] as List;
        for (var i = 0; i < offers.length; i++) {
          final item = offers[i];
          if (item is Map<String, dynamic>) {
            final f = _parseFlightOffer(item, from, to, i);
            list.add(f);
            _flightById[f.id] = f;
          }
        }
      }

      if (list.isNotEmpty) {
        list.sort((a, b) => a.price.compareTo(b.price));
        _flightsByRoute[routeKey] = list;
        _offlineKeys.remove(routeKey);

        // Persist to local disk cache
        final prefs = await _getPrefs();
        final raw = jsonEncode(list.map((f) => f.toJson()).toList());
        await prefs.setString('cheapestgo_cache_flights_$routeKey', raw);
        return list;
      }
    } catch (_) {
      // Network failed or API unavailable: fallback to disk cache
    }

    // Attempt loading from SharedPreferences
    final prefs = await _getPrefs();
    final cachedJson = prefs.getString('cheapestgo_cache_flights_$routeKey');
    if (cachedJson != null && cachedJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedJson) as List;
        final cachedFlights = decoded
            .map((e) => FlightOffer.fromJson(e as Map<String, dynamic>))
            .toList();
        _flightsByRoute[routeKey] = cachedFlights;
        for (final f in cachedFlights) {
          _flightById[f.id] = f;
        }
        _offlineKeys.add(routeKey);
        return cachedFlights;
      } catch (_) {}
    }

    // Final fallback to mock catalog
    final mockFlights = _mock.flights(from, to);
    _flightsByRoute[routeKey] = mockFlights;
    _offlineKeys.add(routeKey);
    return mockFlights;
  }

  @override
  Future<void> refresh() async {
    final airportCodes = _hotelsByAirport.keys.toList();
    for (final code in airportCodes) {
      await fetchHotels(code);
    }
    final routes = _flightsByRoute.keys.toList();
    for (final r in routes) {
      final parts = r.split('_');
      if (parts.length == 2) {
        await fetchFlights(parts[0], parts[1]);
      }
    }
  }

  Hotel _parseHotelFromSearch(Map<String, dynamic> item, Airport airport) {
    final hId = item['hotelId']?.toString() ?? item['id']?.toString() ?? 'hotel_${item.hashCode}';
    final name = item['name']?.toString() ?? 'Hotel';
    final city = item['city']?.toString() ?? item['address']?.toString() ?? airport.city;
    final lat = (item['lat'] as num?)?.toDouble() ??
        ((item['coordinates'] as Map<String, dynamic>?)?['lat'] as num?)?.toDouble();
    final lng = (item['lng'] as num?)?.toDouble() ??
        ((item['coordinates'] as Map<String, dynamic>?)?['lng'] as num?)?.toDouble();

    double distance = (item['distanceKm'] as num?)?.toDouble() ?? 2.5;
    if (lat != null && lng != null) {
      distance = MockTravelCatalog.distanceKm((airport.latitude, airport.longitude), (lat, lng));
    }

    final score = (item['reviewRating'] as num?)?.toDouble() ??
        (item['rating'] as num?)?.toDouble() ??
        8.6;
    final reviews = (item['reviews'] as num?)?.toInt() ??
        (item['reviewCount'] as num?)?.toInt() ??
        120;

    final tags = <String>[];
    final amenities = (item['amenities'] as List?)
            ?.map((e) => e.toString().toLowerCase())
            .toList() ??
        const [];
    if (amenities.any((a) => a.contains('shuttle') || a.contains('transfer'))) {
      tags.add(kTagShuttle);
    }
    final refundableTag = item['refundableTag']?.toString();
    if (refundableTag != null && refundableTag.isNotEmpty) {
      tags.add(refundableTag);
    }

    final price = (item['price'] as num?)?.round() ?? 3500;
    final rooms = <Room>[];
    if (item['roomTypes'] is List && (item['roomTypes'] as List).isNotEmpty) {
      final rTypes = item['roomTypes'] as List;
      for (var i = 0; i < rTypes.length; i++) {
        final r = rTypes[i];
        if (r is Map<String, dynamic>) {
          rooms.add(Room(
            id: r['offerId']?.toString() ?? r['roomCode']?.toString() ?? '${hId}_r$i',
            name: r['roomName']?.toString() ?? 'Room ${i + 1}',
            meta: r['boardCode']?.toString() ?? 'Room only',
            nightlyRate: (r['price'] as num?)?.round() ?? price,
            cancellation: r['refundable'] == true
                ? (r['refundableTag']?.toString() ?? 'Free cancellation')
                : null,
          ));
        }
      }
    }
    if (rooms.isEmpty) {
      rooms.add(Room(
        id: '${hId}_standard',
        name: 'Standard Room',
        meta: 'Room only',
        nightlyRate: price,
        cancellation: refundableTag,
      ));
    }

    final images = <String>[];
    if (item['images'] is List && (item['images'] as List).isNotEmpty) {
      for (final img in (item['images'] as List)) {
        if (img is String && img.isNotEmpty) images.add(img);
      }
    } else if (item['image'] != null && item['image'].toString().isNotEmpty) {
      images.add(item['image'].toString());
    }

    final starRating = (item['starRating'] as num?)?.toInt();
    final badge = starRating != null && starRating >= 5
        ? '5-star'
        : (item['badge']?.toString());

    return Hotel(
      id: hId,
      airportCode: airport.code,
      name: name,
      area: city,
      distanceKm: distance,
      distanceFrom: airport.terminals.split(',').first.trim(),
      score: score,
      reviews: reviews,
      tags: tags,
      rooms: rooms,
      badge: badge,
      images: images,
      latitude: lat,
      longitude: lng,
      address: item['address']?.toString(),
      description: item['description']?.toString(),
    );
  }

  FlightOffer _parseFlightOffer(Map<String, dynamic> offer, String origin, String dest, int index) {
    final offerId = offer['offerId']?.toString() ?? '$origin-$dest-$index';
    final segments = (offer['segments'] as List?) ?? const [];
    final firstSeg = segments.isNotEmpty ? segments.first as Map<String, dynamic>? : null;
    final lastSeg = segments.isNotEmpty ? segments.last as Map<String, dynamic>? : null;

    // api-v2 sends `airline` as the IATA code ("7C") with the name in
    // `airlineName`; older payloads sent an object {code, name}. Accept both.
    final rawAirline = firstSeg?['airline'];
    final airlineObj = rawAirline is Map<String, dynamic> ? rawAirline : null;
    final airlineCode = airlineObj?['code']?.toString() ??
        (rawAirline is String ? rawAirline : null);
    final airline = firstSeg?['airlineName']?.toString() ??
        airlineObj?['name']?.toString() ??
        airlineCode ??
        'Commercial Flight';
    final flightNo = firstSeg?['flightNumber']?.toString() ??
        '${airlineCode ?? 'CG'} ${200 + index * 15}';

    String departs = '08:00';
    final depTime = (firstSeg?['departure'] as Map<String, dynamic>?)?['time']?.toString();
    if (depTime != null && depTime.contains('T')) {
      final tPart = depTime.split('T')[1];
      departs = tPart.substring(0, 5);
    }

    String? arrivesOverride;
    final arrTime = (lastSeg?['arrival'] as Map<String, dynamic>?)?['time']?.toString();
    if (arrTime != null && arrTime.contains('T')) {
      final tPart = arrTime.split('T')[1];
      arrivesOverride = tPart.substring(0, 5);
    }

    final duration = (offer['totalDuration'] as num?)?.toInt() ?? 120;
    final totalStops = (offer['totalStops'] as num?)?.toInt() ?? 0;
    String? stopover;
    if (totalStops > 0 && segments.length > 1) {
      stopover = firstSeg?['destination']?.toString();
    }

    final baggageObj = offer['baggage'] as Map<String, dynamic>?;
    final checkedBags = (baggageObj?['checkedBags'] as num?)?.toInt() ?? 0;
    final baggage = checkedBags > 0 ? '$checkedBags checked bag (20kg)' : 'Cabin bag only';

    final priceObj = offer['price'] as Map<String, dynamic>?;
    final price = (priceObj?['total'] as num?)?.round() ??
        (priceObj?['pricePerAdult'] as num?)?.round() ??
        (offer['price'] as num?)?.round() ??
        4500;

    return FlightOffer(
      id: offerId,
      airline: airline,
      flightNo: flightNo,
      origin: firstSeg?['origin']?.toString() ?? origin,
      destination: lastSeg?['destination']?.toString() ?? dest,
      departs: departs,
      durationMinutes: duration,
      stopover: stopover,
      baggage: baggage,
      price: price,
      arrivesOverride: arrivesOverride,
    );
  }
}

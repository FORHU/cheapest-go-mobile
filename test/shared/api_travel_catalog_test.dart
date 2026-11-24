import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http_pkg;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cheapest_go_mobile/shared/catalog/api_travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/lib/http.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiTravelCatalog - Online Search & Parsing', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('fetchHotels parses API payload, computes distance, and populates cache', () async {
      final mockHttp = HttpClientAdapter(
        client: MockClient((request) async {
          if (request.url.path.contains('/api/v2/hotels/search')) {
            final payload = jsonDecode(request.body) as Map<String, dynamic>;
            expect(payload['destination'], 'Manila');
            expect(payload['countryCode'], 'PH');

            final responseBody = {
              'data': [
                {
                  'hotelId': 'h-live-01',
                  'name': 'Grand Hyatt Manila Live',
                  'city': 'Taguig',
                  'lat': 14.553,
                  'lng': 121.049,
                  'rating': 9.2,
                  'reviewCount': 350,
                  'starRating': 5,
                  'amenities': ['Free WiFi', 'Free Airport Shuttle', 'Outdoor Pool'],
                  'images': [
                    'https://images.cheapestgo.com/hotel1.jpg',
                    'https://images.cheapestgo.com/hotel2.jpg',
                  ],
                  'roomTypes': [
                    {
                      'offerId': 'off-live-1',
                      'roomName': '1 King Bed Deluxe',
                      'price': 8500,
                      'refundable': true,
                      'refundableTag': 'Free cancellation until Nov 18',
                    },
                  ],
                },
              ],
              'totalCount': 1,
            };
            return http_pkg.Response(jsonEncode(responseBody), 200, headers: {'content-type': 'application/json'});
          }
          return http_pkg.Response('Not Found', 404);
        }),
      );

      final prefs = await SharedPreferences.getInstance();
      final catalog = ApiTravelCatalog(client: mockHttp, prefs: prefs);

      final hotels = await catalog.fetchHotels('MNL');
      expect(hotels, hasLength(1));
      final hotel = hotels.first;
      expect(hotel.id, 'h-live-01');
      expect(hotel.name, 'Grand Hyatt Manila Live');
      expect(hotel.area, 'Taguig');
      expect(hotel.score, 9.2);
      expect(hotel.reviews, 350);
      expect(hotel.hasShuttle, isTrue);
      expect(hotel.badge, '5-star');
      expect(hotel.cover, 'https://images.cheapestgo.com/hotel1.jpg');
      expect(hotel.photos, hasLength(2));
      expect(hotel.rooms, hasLength(1));
      expect(hotel.fromRate, 8500);
      expect(hotel.rooms.first.cancellation, 'Free cancellation until Nov 18');
      expect(catalog.isOfflineData('MNL'), isFalse);

      // Verify synchronous getter returns the live hotel from cache
      final syncHotels = catalog.hotelsNear('MNL');
      expect(syncHotels.first.name, 'Grand Hyatt Manila Live');
      expect(catalog.hotel('h-live-01')?.name, 'Grand Hyatt Manila Live');

      // Verify SharedPreferences has cached the result
      final cachedRaw = prefs.getString('cheapestgo_cache_hotels_MNL');
      expect(cachedRaw, isNotNull);
      expect(cachedRaw, contains('Grand Hyatt Manila Live'));
    });

    // #74, in the shape api-v2 actually answers — captured from a live response, not guessed.
    // A room's `price` covers the whole stay; `nights` is on the **hotel**, not the room; and
    // the hotel's own `price` is already per night. Read as a nightly rate, the room's figure
    // put a two-night total on the card under a "/박" label.
    //
    // The first version of this test put `nights` inside the room, so it passed against a
    // payload the server never sends while the handset was unchanged. Hence the real keys.
    test('a room priced for the stay is held as a nightly rate, not the total', () async {
      final mockHttp = HttpClientAdapter(
        client: MockClient((request) async {
          if (!request.url.path.contains('/api/v2/hotels/search')) {
            return http_pkg.Response('Not Found', 404);
          }
          return http_pkg.Response(
            jsonEncode({
              'data': [
                {
                  'hotelId': 'h-nights-01',
                  'name': 'Two Night Total Inn',
                  'city': 'Manila',
                  'lat': 14.5995,
                  'lng': 120.9842,
                  // The supplier answers in its own currency whatever was asked for.
                  'currency': 'USD',
                  'price': 61.6,
                  'stayTotal': 123.2,
                  'nights': 2,
                  'roomTypes': [
                    {
                      'offerId': 'o-1',
                      'roomName': 'Standard Double',
                      'price': 123.2,
                      'gross': 123.2,
                      'currency': 'USD',
                    },
                  ],
                },
              ],
              'totalCount': 1,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final prefs = await SharedPreferences.getInstance();
      final catalog = ApiTravelCatalog(client: mockHttp, prefs: prefs);
      final hotel = (await catalog.fetchHotels('MNL')).single;

      expect(hotel.rooms.single.nightlyRate, 62, reason: '123.2 over 2 nights, not 123');
      expect(hotel.fromRate, 62);
      // And the supplier's currency survives, so the figure is converted as dollars.
      expect(hotel.currency, 'USD');
    });

    test('fetchHotel property details enriches hotel with description and rooms', () async {
      final mockHttp = HttpClientAdapter(
        client: MockClient((request) async {
          if (request.url.path.contains('/api/v2/hotels/property/h-live-01')) {
            final responseBody = {
              'content': {
                'name': 'Grand Hyatt Manila Luxury Suite',
                'city': 'Bonifacio Global City',
                'address': '8th Avenue corner 35th Street',
                'description': 'A luxury stay in the heart of BGC.',
                'rating': 9.4,
                'reviews': 400,
                'images': ['https://images.cheapestgo.com/suite.jpg'],
              },
              'rooms': [
                {
                  'offerId': 'room-suite-01',
                  'roomName': 'Presidential Suite',
                  'boardCode': 'Breakfast Included',
                  'price': 16000,
                  'refundable': true,
                  'refundableTag': 'Free cancellation',
                },
              ],
            };
            return http_pkg.Response(jsonEncode(responseBody), 200, headers: {'content-type': 'application/json'});
          }
          return http_pkg.Response('Not Found', 404);
        }),
      );

      final prefs = await SharedPreferences.getInstance();
      final catalog = ApiTravelCatalog(client: mockHttp, prefs: prefs);

      final detailed = await catalog.fetchHotel('h-live-01');
      expect(detailed, isNotNull);
      expect(detailed!.name, 'Grand Hyatt Manila Luxury Suite');
      expect(detailed.address, '8th Avenue corner 35th Street');
      expect(detailed.description, 'A luxury stay in the heart of BGC.');
      expect(detailed.rooms.first.name, 'Presidential Suite');
      expect(detailed.fromRate, 16000);
    });

    test('fetchFlights parses API flight search offers and caches them', () async {
      final mockHttp = HttpClientAdapter(
        client: MockClient((request) async {
          if (request.url.path.contains('/api/v2/flights/search')) {
            final payload = jsonDecode(request.body) as Map<String, dynamic>;
            expect(payload['origin'], 'SIN');
            expect(payload['destination'], 'MNL');

            final responseBody = {
              'offers': [
                {
                  'offerId': 'fl-live-01',
                  'totalDuration': 210,
                  'totalStops': 0,
                  'price': {
                    'total': 6850,
                    'pricePerAdult': 6850,
                    'currency': 'PHP',
                  },
                  'baggage': {
                    'checkedBags': 1,
                  },
                  'segments': [
                    {
                      'airline': {
                        'name': 'Singapore Airlines',
                        'code': 'SQ',
                      },
                      'flightNumber': 'SQ 912',
                      'origin': 'SIN',
                      'destination': 'MNL',
                      'departure': {
                        'airport': 'SIN',
                        'time': '2026-11-20T12:30:00',
                      },
                      'arrival': {
                        'airport': 'MNL',
                        'time': '2026-11-20T16:00:00',
                      },
                    },
                  ],
                },
              ],
              'totalResults': 1,
            };
            return http_pkg.Response(jsonEncode(responseBody), 200, headers: {'content-type': 'application/json'});
          }
          return http_pkg.Response('Not Found', 404);
        }),
      );

      final prefs = await SharedPreferences.getInstance();
      final catalog = ApiTravelCatalog(client: mockHttp, prefs: prefs);

      final flights = await catalog.fetchFlights('SIN', 'MNL');
      expect(flights, hasLength(1));
      final flight = flights.first;
      expect(flight.id, 'fl-live-01');
      expect(flight.airline, 'Singapore Airlines');
      expect(flight.flightNo, 'SQ 912');
      expect(flight.departs, '12:30');
      expect(flight.arrives, '16:00');
      expect(flight.price, 6850);
      expect(flight.baggage, '1 checked bag (20kg)');
      expect(catalog.isOfflineData('SIN_MNL'), isFalse);

      // Verify sync getters
      expect(catalog.flights('SIN', 'MNL').first.flightNo, 'SQ 912');
      expect(catalog.flight('fl-live-01')?.airline, 'Singapore Airlines');

      // Verify persistence
      expect(prefs.getString('cheapestgo_cache_flights_SIN_MNL'), contains('SQ 912'));
    });

    test('fetchFlights asks for pesos and shows the API\'s PHP price, never a USD figure as pesos', () async {
      Map<String, dynamic> usdOffer(String id, {Map<String, dynamic>? displayPrice}) => {
            'offerId': id,
            'totalDuration': 243,
            'totalStops': 0,
            'price': {'total': 117.55, 'pricePerAdult': 117.55, 'currency': 'USD'},
            'displayPrice': ?displayPrice,
            'segments': [
              {
                // api-v2's current shape: the code as a string, the name beside it.
                'airline': '7C',
                'airlineName': 'Jeju Air',
                'flightNumber': '7C2302',
                'origin': 'MNL',
                'destination': 'ICN',
                'departure': {'airport': 'MNL', 'time': '2026-11-25T18:34:00'},
                'arrival': {'airport': 'ICN', 'time': '2026-11-26T04:10:00'},
              },
            ],
          };

      Map<String, dynamic>? sent;
      final mockHttp = HttpClientAdapter(
        client: MockClient((request) async {
          sent = jsonDecode(request.body) as Map<String, dynamic>;
          final body = {
            'offers': [
              usdOffer('converted', displayPrice: {
                'currency': 'PHP',
                'total': 6914.71,
                'pricePerAdult': 6914.71,
                'rateSource': 'live',
              }),
              // No rate on the server: no displayPrice, so the app has no peso price for it.
              usdOffer('unconverted'),
            ],
          };
          return http_pkg.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});
        }),
      );

      final catalog = ApiTravelCatalog(client: mockHttp, prefs: await SharedPreferences.getInstance());
      final flights = await catalog.fetchFlights('MNL', 'ICN');

      expect(sent?['currency'], 'PHP');
      expect(flights.map((f) => f.id), ['converted']);
      expect(flights.single.price, 6915);
      expect(flights.single.airline, 'Jeju Air');
      expect(flights.single.flightNo, '7C2302');
    });
  });

  group('ApiTravelCatalog - Offline Fallback & Cache', () {
    test('when network fails, returns saved results from SharedPreferences with offline flag', () async {
      final failingHttp = HttpClientAdapter(
        client: MockClient((request) async {
          throw Exception('Network unreachable (Offline)');
        }),
      );

      final cachedHotel = Hotel(
        id: 'h-cached-01',
        airportCode: 'CEB',
        name: 'Crimson Resort & Spa Mactan (Cached)',
        area: 'Lapu-Lapu City',
        distanceKm: 4.5,
        distanceFrom: 'Terminal 2',
        score: 9.0,
        reviews: 210,
        tags: const ['Free airport shuttle', 'Private Beach'],
        rooms: const [
          Room(
            id: 'room-cached-01',
            name: 'Deluxe Villa',
            meta: 'Breakfast included',
            nightlyRate: 9800,
            cancellation: 'Free cancellation',
          ),
        ],
      );

      final initialPrefs = {
        'cheapestgo_cache_hotels_CEB': jsonEncode([cachedHotel.toJson()]),
      };
      SharedPreferences.setMockInitialValues(initialPrefs);
      final prefs = await SharedPreferences.getInstance();

      final catalog = ApiTravelCatalog(client: failingHttp, prefs: prefs);

      final hotels = await catalog.fetchHotels('CEB');
      expect(hotels, hasLength(1));
      expect(hotels.first.name, 'Crimson Resort & Spa Mactan (Cached)');
      expect(catalog.isOfflineData('CEB'), isTrue);
    });

    // #73. This used to assert the opposite — that a failed search was filled from the demo
    // catalogue — which is how Manila fixtures ended up on screen, priced and bookable, as
    // the results for Seoul. A stay shown as bookable has to be one a supplier will honour.
    test('when network fails and cache is empty, stays answer nothing — never invented rooms', () async {
      final failingHttp = HttpClientAdapter(
        client: MockClient((request) async {
          throw Exception('Network timeout');
        }),
      );

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final catalog = ApiTravelCatalog(client: failingHttp, prefs: prefs);

      await expectLater(catalog.fetchHotels('BKK'), throwsA(isA<StateError>()));
      expect(catalog.hotelsNear('BKK'), isEmpty);
    });

    // The distinction the screen depends on: a supplier that answered "nothing for these
    // dates" must not read as a supplier that could not be reached, and must not be papered
    // over by a cache saved from an earlier search of the same city.
    test('an empty answer is returned as empty, not replaced by the cache', () async {
      final emptyHttp = HttpClientAdapter(
        client: MockClient((request) async {
          return http_pkg.Response('{"data":[],"allMappable":[],"totalCount":0}', 200,
              headers: {'content-type': 'application/json'});
        }),
      );

      // A stay saved from an earlier, successful search of this same city.
      final stale = Hotel(
        id: 'h-stale-01',
        airportCode: 'CEB',
        name: 'Crimson Resort & Spa Mactan (Cached)',
        area: 'Lapu-Lapu City',
        distanceKm: 4.5,
        distanceFrom: 'Terminal 2',
        score: 9.0,
        reviews: 210,
        tags: const ['Free airport shuttle'],
        rooms: const [
          Room(
            id: 'room-stale-01',
            name: 'Deluxe Villa',
            meta: 'Breakfast included',
            nightlyRate: 9800,
            cancellation: 'Free cancellation',
          ),
        ],
      );

      SharedPreferences.setMockInitialValues({
        'cheapestgo_cache_hotels_CEB': jsonEncode([stale.toJson()]),
      });
      final prefs = await SharedPreferences.getInstance();
      final catalog = ApiTravelCatalog(client: emptyHttp, prefs: prefs);

      final hotels = await catalog.fetchHotels('CEB');
      expect(hotels, isEmpty);
      // Answered, so not offline — the screen shows "none found", not stale prices.
      expect(catalog.isOfflineData('CEB'), isFalse);
    });

    // #47: a fare shown as bookable must be one an airline sells. Since #73 stays follow the
    // same rule, so this is no longer the exception it was written as.
    test('when network fails and cache is empty, flights answer nothing — never invented fares', () async {
      final failingHttp = HttpClientAdapter(
        client: MockClient((request) async {
          throw Exception('Network timeout');
        }),
      );

      SharedPreferences.setMockInitialValues({});
      final catalog = ApiTravelCatalog(client: failingHttp, prefs: await SharedPreferences.getInstance());

      expect(await catalog.fetchFlights('SIN', 'MNL'), isEmpty);
      expect(catalog.flights('SIN', 'MNL'), isEmpty);
      expect(catalog.flight('SIN-MNL-0'), isNull);
    });

    test('golf courses always delegate to mock catalog', () {
      final catalog = ApiTravelCatalog();
      final courses = catalog.coursesNear('MNL');
      expect(courses, isNotEmpty);
      expect(courses.first.holes, greaterThanOrEqualTo(18));
      expect(catalog.course(courses.first.id), isNotNull);
    });
  });

  group('DefaultTravelCatalog', () {
    test('DefaultTravelCatalog delegates to configured delegate and allows test injection', () {
      const mock = MockTravelCatalog();
      DefaultTravelCatalog.delegate = mock;

      expect(travelCatalog.airports(), isNotEmpty);
      expect(travelCatalog.hotelsNear('MNL'), isNotEmpty);
      expect(travelCatalog.flights('SIN', 'MNL'), isNotEmpty);
      expect(travelCatalog.isOfflineData('MNL'), isFalse);
    });
  });

  /// Zero is not a place.
  ///
  /// A stay whose content has never been geocoded comes back from the live supplier as
  /// `lat: 0, lng: 0`. Read literally that is a point in the Atlantic off West Africa, and
  /// the results map frames itself on the stays it is given — so one ungeocoded stay in a
  /// Seoul search stretched the camera from Korea to the Gulf of Guinea, drew open ocean,
  /// and collapsed every pin into a single cluster in the middle of it. 283 of 317 Seoul
  /// stays answered that way the first time this app was pointed at the live supplier.
  ///
  /// The mock catalogue never produced a zero, which is why only real data found this.
  group('ApiTravelCatalog - ungeocoded stays', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<List<Hotel>> search(List<Map<String, dynamic>> rows) async {
      final mockHttp = HttpClientAdapter(
        client: MockClient((request) async {
          if (request.url.path.contains('/api/v2/hotels/search')) {
            return http_pkg.Response(jsonEncode({'data': rows}), 200,
                headers: {'content-type': 'application/json'});
          }
          return http_pkg.Response('{}', 404);
        }),
      );
      final prefs = await SharedPreferences.getInstance();
      return ApiTravelCatalog(client: mockHttp, prefs: prefs).fetchHotels('ICN');
    }

    Map<String, dynamic> row(String id, Object? lat, Object? lng) => {
          'hotelId': id,
          'name': 'Stay $id',
          'lat': lat,
          'lng': lng,
          'coordinates': {'lat': lat, 'lng': lng},
          'roomTypes': [
            {'offerId': 'o-$id', 'roomName': 'Room', 'price': 90000, 'currency': 'KRW'},
          ],
        };

    test('a stay at 0,0 is unplaced rather than dropped into the Atlantic', () async {
      final hotels = await search([row('a', 0, 0)]);

      expect(hotels, hasLength(1), reason: 'it is still a bookable stay');
      expect(hotels.first.latitude, isNull);
      expect(hotels.first.longitude, isNull);
    });

    test('a real coordinate still comes through', () async {
      final hotels = await search([row('b', 37.481, 126.89)]);

      expect(hotels.first.latitude, 37.481);
      expect(hotels.first.longitude, 126.89);
    });

    /// Only the pair means "not known". The equator runs through Kenya and Indonesia, and
    /// the prime meridian through Ghana, so a single zero is a place somebody can stay.
    test('a stay on the equator keeps its coordinates', () async {
      final hotels = await search([row('c', 0, 109.33)]);

      expect(hotels.first.latitude, 0);
      expect(hotels.first.longitude, 109.33);
    });

    test('the map is framed only on the stays that have a place', () async {
      final hotels = await search([row('d', 0, 0), row('e', 37.56, 126.97)]);

      final placed = hotels.where((h) => h.latitude != null && h.longitude != null);
      expect(hotels, hasLength(2));
      expect(placed, hasLength(1), reason: 'the ungeocoded one must not reach the map');
    });
  });

  /// Each room shows its own photographs, as the property page on the web does.
  ///
  /// api-v2 matches every offer's room name to the supplier's room group and hands back that
  /// group's pictures on `content.gallery` — nine rooms of one Manila property come back with
  /// six distinct galleries, the repeats being two rates of the same physical room. Where a
  /// room has none, the card falls back to the hotel's own photograph, which is why a property
  /// with no room content at all shows the same picture on every card. That is an empty
  /// catalogue, not a parsing fault, and this is what proves the difference.
  group('ApiTravelCatalog - room photography', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<Hotel?> property(List<Map<String, dynamic>> rooms) async {
      final mockHttp = HttpClientAdapter(
        client: MockClient((request) async {
          if (request.url.path.contains('/api/v2/hotels/property/h-rooms')) {
            return http_pkg.Response(
              jsonEncode({
                'content': {
                  'name': 'Victoria Mansions',
                  'city': 'Manila',
                  'images': ['https://cdn.test/hotel-1.jpg', 'https://cdn.test/hotel-2.jpg'],
                },
                'rooms': rooms,
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http_pkg.Response('Not Found', 404);
        }),
      );
      final prefs = await SharedPreferences.getInstance();
      return ApiTravelCatalog(client: mockHttp, prefs: prefs).fetchHotel('h-rooms');
    }

    Map<String, dynamic> offer(String id, String name, List<String> gallery) => {
          'offerId': id,
          'roomName': name,
          'price': 16000,
          'content': {'gallery': gallery, 'matchedRoomName': name},
        };

    test('two rooms keep two galleries', () async {
      final hotel = await property([
        offer('r1', 'Deluxe Double', ['https://cdn.test/deluxe-1.jpg', 'https://cdn.test/deluxe-2.jpg']),
        offer('r2', 'Standard Twin', ['https://cdn.test/twin-1.jpg']),
      ]);

      expect(hotel!.rooms, hasLength(2));
      expect(hotel.rooms[0].images, ['https://cdn.test/deluxe-1.jpg', 'https://cdn.test/deluxe-2.jpg']);
      expect(hotel.rooms[1].images, ['https://cdn.test/twin-1.jpg']);
      expect(hotel.rooms[0].images, isNot(hotel.rooms[1].images),
          reason: 'the whole point: two rooms, two sets of pictures');
    });

    /// The supplier sells the same physical room under more than one name — "Double Studio
    /// (full double bed)" and "Studio" are one room group — so matching galleries here are
    /// the truth, not a bug. The app passes them through rather than inventing a difference.
    test('two rates of one room type legitimately share a gallery', () async {
      final shared = ['https://cdn.test/studio-1.jpg', 'https://cdn.test/studio-2.jpg'];
      final hotel = await property([
        offer('r1', 'Double Studio (full double bed)', shared),
        offer('r2', 'Studio', shared),
      ]);

      expect(hotel!.rooms[0].images, shared);
      expect(hotel.rooms[1].images, shared);
    });

    /// What a property with no room content looks like. The room carries nothing, so the card
    /// falls back to the hotel's own picture — every card the same, which is exactly what an
    /// unseeded catalogue produces and must not be mistaken for a parsing fault.
    test('a room with no pictures of its own carries none', () async {
      final hotel = await property([
        {'offerId': 'r1', 'roomName': 'Standard Triple', 'price': 16000},
      ]);

      expect(hotel!.rooms.single.images, isEmpty);
      expect(hotel.photos, isNotEmpty, reason: 'the hotel still has its own, for the fallback');
    });

    /// The older wire name, still sent by some responses.
    test('roomPhotos is read as well as content.gallery', () async {
      final hotel = await property([
        {
          'offerId': 'r1',
          'roomName': 'Standard Triple',
          'price': 16000,
          'roomPhotos': ['https://cdn.test/triple-1.jpg'],
        },
      ]);

      expect(hotel!.rooms.single.images, ['https://cdn.test/triple-1.jpg']);
    });
  });
}

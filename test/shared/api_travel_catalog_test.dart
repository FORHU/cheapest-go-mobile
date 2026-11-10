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

    test('when network fails and cache is empty, falls back to MockTravelCatalog with offline flag', () async {
      final failingHttp = HttpClientAdapter(
        client: MockClient((request) async {
          throw Exception('Network timeout');
        }),
      );

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final catalog = ApiTravelCatalog(client: failingHttp, prefs: prefs);

      final hotels = await catalog.fetchHotels('BKK');
      expect(hotels, isNotEmpty);
      expect(catalog.isOfflineData('BKK'), isTrue);
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
}

import 'package:cheapest_go_mobile/features/hotels/contracts/hotels_contract.dart';
import 'package:cheapest_go_mobile/shared/errors/api_error.dart';
import 'package:cheapest_go_mobile/shared/lib/http.dart';

class HotelsClient {
  static const Map<String, String> _keywordAliases = {
    'beijing airport': 'Beijing',
    'beijing capital airport': 'Beijing',
    'beijing city': 'Beijing',
    'beijing downtown': 'Beijing',
    'hk': 'Hong Kong',
    'hongkong': 'Hong Kong',
    'hong kong airport': 'Hong Kong',
    'new york city': 'New York',
    'new york': 'New York',
    'nyc': 'New York',
    'los angeles': 'Los Angeles',
    'la': 'Los Angeles',
    'sao paulo': 'São Paulo',
    'saopaulo': 'São Paulo',
    'saint petersburg': 'St. Petersburg',
    'san francisco': 'San Francisco',
    'sf': 'San Francisco',
    'sfo': 'San Francisco',
    'london airport': 'London',
    'tokyo airport': 'Tokyo',
  };

  static String normalizeKeyword(String keyword) {
    final cleaned = keyword.trim().replaceAll(RegExp(r'\s+'), ' ');
    return _keywordAliases[cleaned.toLowerCase()] ?? cleaned;
  }

  /// Calls `POST /api/v2/autocomplete` with fallback to `GET /api/v2/hotels/destinations`
  Future<List<DestinationSuggestion>> autocompleteDestinations(
    String keyword, {
    String locale = 'en',
  }) async {
    final normalized = normalizeKeyword(keyword);
    if (normalized.length < 2) return const [];

    try {
      final res = await http.post(
        '/api/v2/autocomplete',
        body: {'query': normalized, 'locale': locale},
        options: const HttpRequestOptions(requiresAuth: false),
      );
      final rawList = res is List
          ? res
          : (res is Map<String, dynamic>
              ? (res['data'] as List? ?? const [])
              : const []);
      final results = rawList
          .whereType<Map<String, dynamic>>()
          .map(DestinationSuggestion.fromJson)
          .where((d) => d.title.isNotEmpty)
          .toList();
      if (results.isNotEmpty) return results;
    } catch (_) {}

    try {
      final dests = await http.get(
        '/api/v2/hotels/destinations?query=${Uri.encodeQueryComponent(normalized)}&locale=$locale',
        options: const HttpRequestOptions(requiresAuth: false),
      );
      if (dests is Map<String, dynamic> && dests['data'] is List) {
        return (dests['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map(DestinationSuggestion.fromJson)
            .where((d) => d.title.isNotEmpty)
            .toList();
      }
    } catch (_) {}

    return const [];
  }

  /// Calls `POST /api/v2/hotels/search` matching `searchSchema` in `hotels.controller.ts`
  Future<List<HotelSummary>> searchHotels(HotelSearchParams params) async {
    final normalizedCity = normalizeKeyword(params.destination);
    final res = await http.post(
      '/api/v2/hotels/search',
      body: {
        'destination': normalizedCity,
        'checkIn': params.checkIn,
        'checkOut': params.checkOut,
        'adults': params.adults,
        'children': params.children,
        'rooms': params.rooms,
        'countryCode': ?params.countryCode,
        'currency': params.currency,
        'lat': ?params.lat,
        'lng': ?params.lng,
      },
      options: const HttpRequestOptions(
        requiresAuth: false,
        timeout: Duration(seconds: 45),
      ),
    );

    if (res is Map<String, dynamic> && res['data'] is List) {
      return (res['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(HotelSummary.fromJson)
          .toList();
    }
    return const [];
  }

  /// Calls `GET /api/v2/hotels/property/:id?checkIn=...&checkOut=...&adults=...&children=...`
  Future<HotelSummary?> getHotelDetails(
    String hotelId, {
    required String checkIn,
    required String checkOut,
    int adults = 2,
    int children = 0,
    int rooms = 1,
    String currency = 'USD',
    HotelSummary? fallback,
  }) async {
    final query = Uri(
      queryParameters: {
        'checkIn': checkIn,
        'checkOut': checkOut,
        'adults': adults.toString(),
        'children': children.toString(),
      },
    ).query;
    final res = await http.get(
      '/api/v2/hotels/property/${Uri.encodeComponent(hotelId)}?$query',
      options: const HttpRequestOptions(
        requiresAuth: false,
        timeout: Duration(seconds: 45),
      ),
    );
    if (res is Map<String, dynamic>) {
      if (res.containsKey('content') || res.containsKey('rooms')) {
        return HotelSummary.fromPropertyResponse(
          res,
          fallback: fallback,
          currency: currency,
        );
      }
      if (res['data'] is Map<String, dynamic>) {
        return HotelSummary.fromJson(res['data'] as Map<String, dynamic>);
      }
    }
    return fallback;
  }

  /// Calls `POST /api/v2/hotels/prebook` matching `prebookSchema` in `hotels.controller.ts`
  Future<PrebookQuote> prebookRoom({
    required String offerId,
    required String currency,
    int adults = 2,
    int children = 0,
    String? roomName,
    double? expectedTotal,
  }) async {
    final res = await http.post(
      '/api/v2/hotels/prebook',
      body: {
        'offerId': offerId,
        'currency': currency,
        'adults': adults,
        'children': children,
        'roomName': ?roomName,
        'expectedTotal': ?expectedTotal,
      },
      options: const HttpRequestOptions(requiresAuth: false),
    );
    if (res is Map<String, dynamic> && res['data'] is Map<String, dynamic>) {
      return PrebookQuote.fromJson(res['data'] as Map<String, dynamic>);
    }
    throw ApiError(
      'Prebook failed — room may no longer be available.',
      category: ErrorCategory.server,
    );
  }

  /// Calls `POST /api/v2/hotels/create-payment` (`requireAuth`)
  Future<Map<String, String>> createHotelPayment({
    required String prebookId,
    required double amount,
    required String currency,
    required String holderEmail,
    String? holderFirstName,
    String? holderLastName,
    String? propertyName,
    String? roomName,
    String? checkIn,
    String? checkOut,
    double? displayedTotal,
    int adults = 2,
    int children = 0,
  }) async {
    final res = await http.post(
      '/api/v2/hotels/create-payment',
      body: {
        'prebookId': prebookId,
        'amount': amount,
        'currency': currency,
        'holderEmail': holderEmail,
        'propertyName': ?propertyName,
        'roomName': ?roomName,
        'checkIn': ?checkIn,
        'checkOut': ?checkOut,
        'displayedTotal': ?displayedTotal,
        'adults': adults,
        'children': children,
        if (holderFirstName != null && holderLastName != null)
          'holder': {
            'firstName': holderFirstName,
            'lastName': holderLastName,
            'email': holderEmail,
          },
      },
    );
    if (res is Map<String, dynamic> && res['data'] is Map<String, dynamic>) {
      final data = res['data'] as Map<String, dynamic>;
      return {
        'clientSecret': (data['clientSecret'] ?? '').toString(),
        'paymentIntentId': (data['paymentIntentId'] ?? '').toString(),
        'bookingReference': (data['bookingReference'] ?? '').toString(),
      };
    }
    throw ApiError('Failed to initialize hotel payment.');
  }

  /// Calls `POST /api/v2/hotels/confirm` (`requireAuth`)
  Future<String> confirmHotelBooking({
    required String prebookId,
    required String paymentIntentId,
    required String firstName,
    required String lastName,
    required String email,
    String? propertyName,
    String? roomName,
    String? checkIn,
    String? checkOut,
    int adults = 2,
    int children = 0,
    String currency = 'USD',
    double? quotedPrice,
    String? board,
    Map<String, dynamic>? cancellationPolicies,
  }) async {
    final res = await http.post(
      '/api/v2/hotels/confirm',
      body: {
        'prebookId': prebookId,
        'paymentIntentId': paymentIntentId,
        'holder': {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
        },
        'guests': [
          {
            'firstName': firstName,
            'lastName': lastName,
          },
        ],
        'propertyName': ?propertyName,
        'roomName': ?roomName,
        'checkIn': ?checkIn,
        'checkOut': ?checkOut,
        'adults': adults,
        'children': children,
        'currency': currency,
        'quotedPrice': ?quotedPrice,
        'board': ?board,
        'cancellationPolicies': ?cancellationPolicies,
      },
    );
    if (res is Map<String, dynamic> && res['data'] is Map<String, dynamic>) {
      final data = res['data'] as Map<String, dynamic>;
      return (data['bookingId'] ?? '').toString();
    }
    throw ApiError('Booking confirmation failed.');
  }
}

final HotelsClient hotelsClient = HotelsClient();

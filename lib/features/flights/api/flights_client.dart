import 'package:cheapest_go_mobile/features/flights/contracts/flights_contract.dart';
import 'package:cheapest_go_mobile/shared/errors/api_error.dart';
import 'package:cheapest_go_mobile/shared/lib/http.dart';

class FlightsClient {
  /// Calls `POST /api/v2/flights/search` matching `searchSchema` in `flights.controller.ts`
  Future<List<FlightOffer>> searchFlights(FlightSearchParams params) async {
    final origin = params.origin.trim().toUpperCase();
    final destination = params.destination.trim().toUpperCase();
    final segments = <Map<String, String>>[
      {
        'origin': origin,
        'destination': destination,
        'departureDate': params.departureDate,
      },
      if (params.tripType == 'round-trip' &&
          params.returnDate != null &&
          params.returnDate!.isNotEmpty)
        {
          'origin': destination,
          'destination': origin,
          'departureDate': params.returnDate!,
        },
    ];

    final res = await http.post(
      '/api/v2/flights/search',
      body: {
        'origin': origin,
        'destination': destination,
        'departureDate': params.departureDate,
        'returnDate': ?params.returnDate,
        'adults': params.adults,
        'children': params.children,
        'infants': params.infants,
        'cabinClass': params.cabinClass.wireValue,
        'tripType': params.tripType,
        'segments': segments,
      },
      options: const HttpRequestOptions(
        requiresAuth: false,
        timeout: Duration(seconds: 45),
      ),
    );

    if (res is Map<String, dynamic>) {
      final data = res['data'];
      final rawOffers = data is Map<String, dynamic>
          ? (data['offers'] as List? ?? const [])
          : (res['offers'] as List? ?? const []);
      return rawOffers
          .whereType<Map<String, dynamic>>()
          .map(FlightOffer.fromJson)
          .toList();
    }
    return const [];
  }

  /// Calls `POST /api/v2/mobile/flights/book` (or `/api/v2/flights/book`)
  Future<Map<String, String>> bookFlight({
    required FlightOffer offer,
    required String firstName,
    required String lastName,
    required String gender,
    required String birthDate,
    required String email,
    required String phone,
  }) async {
    final res = await http.post(
      '/api/v2/mobile/flights/book',
      body: {
        'provider': offer.provider,
        'flight': {
          'offerId': offer.offerId,
          'provider': offer.provider,
          'price': {
            'total': offer.price.total,
            'base': offer.price.base,
            'taxes': offer.price.taxes,
            'currency': offer.price.currency,
            'pricePerAdult': offer.price.pricePerAdult,
          },
        },
        'passengers': [
          {
            'type': 'adult',
            'firstName': firstName,
            'lastName': lastName,
            'gender': gender,
            'birthDate': birthDate,
          },
        ],
        'contact': {
          'email': email,
          'phone': phone,
          'countryCode': 'US',
          'addressLine': '1 Main St',
          'city': 'Seoul',
          'postalCode': '04524',
          'country': 'KR',
        },
        'idempotencyKey':
            '${offer.offerId}-${DateTime.now().millisecondsSinceEpoch}',
        'confirmedPrice': offer.price.total,
      },
      options: const HttpRequestOptions(useMobileApiKey: true),
    );

    if (res is Map<String, dynamic>) {
      return {
        'clientSecret': (res['clientSecret'] ?? '').toString(),
        'sessionId': (res['sessionId'] ?? '').toString(),
      };
    }
    throw ApiError('Failed to create flight booking session.');
  }

  /// Calls `POST /api/v2/mobile/flights/confirm`
  Future<String> confirmFlightBooking({
    required String paymentIntentId,
    required String sessionId,
  }) async {
    final res = await http.post(
      '/api/v2/mobile/flights/confirm',
      body: {
        'paymentIntentId': paymentIntentId,
        'sessionId': sessionId,
      },
      options: const HttpRequestOptions(useMobileApiKey: true),
    );
    if (res is Map<String, dynamic>) {
      return (res['pnr'] ?? res['bookingId'] ?? '').toString();
    }
    throw ApiError('Flight booking confirmation failed.');
  }
}

final FlightsClient flightsClient = FlightsClient();

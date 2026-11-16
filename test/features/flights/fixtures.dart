import 'package:cheapest_go_mobile/features/flights/api/flights_api.dart';
import 'package:cheapest_go_mobile/features/flights/models/flight_fare.dart';
import 'package:cheapest_go_mobile/shared/errors/api_error.dart';

/// Offers in the exact shape api-v2's `/flights/search` returned for MNL → SIN from Duffel's
/// test environment on 2026-11-12 — field for field, so the parser is tested against the wire
/// and not against a guess. Only the values differ between them.
Map<String, dynamic> offerJson({
  String id = 'off_034wAvwB5YwUzZRDSUHUOW',
  String airline = 'ZZ',
  String airlineName = 'Duffel Airways',
  String depart = '2026-12-03T01:32:00',
  String arrive = '2026-12-03T05:17:00',
  int duration = 225,
  double total = 116.17,
  bool refundable = true,
  int checkedBags = 1,
  String? via,
}) {
  Map<String, dynamic> seg(int index, String from, String to, String dep, String arr, int minutes, String number) => {
    'segmentIndex': index,
    'airline': airline,
    'airlineName': airlineName,
    'origin': from,
    'destination': to,
    'flightNumber': number,
    'departure': {
      'airport': from,
      'airportName': from == 'MNL' ? 'Ninoy Aquino International Airport' : '$from Airport',
      'city': from,
      'terminal': '2',
      'time': dep,
    },
    'arrival': {
      'airport': to,
      'airportName': to == 'SIN' ? 'Singapore Changi Airport' : '$to Airport',
      'city': to,
      'terminal': '1',
      'time': arr,
    },
    'duration': minutes,
    'stops': 0,
    'cabinClass': 'economy',
  };

  final segments = via == null
      ? [seg(0, 'MNL', 'SIN', depart, arrive, duration, '${airline}6677')]
      : [
          seg(0, 'MNL', via, depart, '${depart.substring(0, 11)}03:00:00', 90, '${airline}100'),
          seg(0, via, 'SIN', '${depart.substring(0, 11)}04:10:00', arrive, 120, '${airline}200'),
        ];

  return {
    'offerId': id,
    'provider': 'duffel',
    'price': {'total': total, 'base': total * 0.85, 'taxes': total * 0.15, 'currency': 'USD', 'pricePerAdult': total},
    'segments': segments,
    'totalDuration': duration,
    'sliceDurations': [duration],
    'totalStops': segments.length - 1,
    'refundable': refundable,
    'farePolicy': null,
    'baggage': {'cabinBag': true, 'checkedBags': checkedBags},
    'tripType': 'one-way',
    '_rawOffer': {'id': id},
    'normalizedPriceUsd': total,
    'bestScore': 1,
    'physicalFlightId': '$airline-$id',
  };
}

List<FlightFare> sampleOffers() => [
  FlightFare.tryParse(
    offerJson(
      id: 'off_pal',
      airline: 'PR',
      airlineName: 'Philippine Airlines',
      total: 210.40,
      duration: 215,
      depart: '2026-12-03T08:00:00',
      arrive: '2026-12-03T11:35:00',
    ),
  )!,
  FlightFare.tryParse(offerJson(id: 'off_duffel', total: 116.17))!,
  FlightFare.tryParse(
    offerJson(
      id: 'off_sq',
      airline: 'SQ',
      airlineName: 'Singapore Airlines',
      total: 180.00,
      duration: 330,
      via: 'KUL',
      refundable: false,
      checkedBags: 0,
      depart: '2026-12-03T00:30:00',
      arrive: '2026-12-03T06:00:00',
    ),
  )!,
];

/// The API, answered from fixtures and recording what it was asked.
class FakeFlightsApi extends FlightsApi {
  FakeFlightsApi({
    List<FlightFare>? offers,
    this.providersFailed = false,
    this.revalidateResult = const RevalidateResult(priceChanged: false, offerExpired: false),
    this.bookError,
    this.offerGone = false,
    this.confirmError,
  }) : offers = offers ?? sampleOffers();

  List<FlightFare> offers;
  bool providersFailed;
  RevalidateResult revalidateResult;
  ApiError? bookError;
  bool offerGone;
  ApiError? confirmError;

  final searches = <Map<String, Object?>>[];
  final revalidated = <String>[];
  final books = <Map<String, Object?>>[];
  final confirms = <Map<String, String>>[];

  @override
  Future<FlightSearchResult> search({
    required String origin,
    required String destination,
    required String departureDate,
    String? returnDate,
    required int adults,
    required int children,
    required int infants,
    required String cabinClass,
    required String tripType,
    String? currency,
  }) async {
    searches.add({
      'origin': origin,
      'destination': destination,
      'departureDate': departureDate,
      'returnDate': returnDate,
      'adults': adults,
      'cabinClass': cabinClass,
      'tripType': tripType,
    });
    return FlightSearchResult(offers: providersFailed ? const [] : offers, providersFailed: providersFailed);
  }

  @override
  Future<RevalidateResult> revalidate(FlightFare offer) async {
    revalidated.add(offer.offerId);
    return revalidateResult;
  }

  @override
  Future<FlightFare?> offer(String offerId, {String? currency}) async {
    if (offerGone) throw const FareGone();
    final json = offerJson(id: offerId);
    json['quote'] = {'currency': 'PHP', 'fare': 7304.18, 'serviceFee': 804.61, 'total': 8108.79};
    return FlightFare.tryParse(json);
  }

  @override
  Future<BookingHold> book({
    required String offerId,
    required String displayCurrency,
    double? confirmedPrice,
    required String email,
    required String phone,
    required String phoneCode,
    required List<Map<String, Object?>> passengers,
  }) async {
    books.add({
      'offerId': offerId,
      'displayCurrency': displayCurrency,
      'confirmedPrice': confirmedPrice,
      'email': email,
      'phone': phone,
      'phoneCode': phoneCode,
      'passengers': passengers,
    });
    if (bookError != null) throw bookError!;
    return const BookingHold(
      clientSecret: 'pi_1_secret_test',
      sessionId: 'sess_1',
      paymentIntentId: 'pi_1',
      amount: 8108.79,
      currency: 'PHP',
      fare: 7304.18,
      serviceFee: 804.61,
    );
  }

  @override
  Future<FlightConfirmation> confirm({required String paymentIntentId, required String sessionId}) async {
    confirms.add({'paymentIntentId': paymentIntentId, 'sessionId': sessionId});
    if (confirmError != null) throw confirmError!;
    return const FlightConfirmation(bookingId: 'bk_1', pnr: 'QZX7PA', status: 'ticketed');
  }
}

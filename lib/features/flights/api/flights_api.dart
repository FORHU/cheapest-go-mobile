import 'package:cheapest_go_mobile/features/flights/models/flight_fare.dart';
import 'package:cheapest_go_mobile/shared/errors/api_error.dart';
import 'package:cheapest_go_mobile/shared/lib/http.dart';

/// The four calls V2's flight pages make, against the same api-v2 routes.
///
/// Every fare comes from the airline through `/api/v2/flights/search` — Duffel, in test mode on
/// the dev API. There is deliberately no fallback to invented fares: a search that cannot reach
/// the airline says so, as V2's does, rather than showing flights nobody can book.
class FlightsApi {
  FlightsApi({HttpClientAdapter? client}) : _client = client ?? http;

  final HttpClientAdapter _client;

  static const _public = HttpRequestOptions(useMobileApiKey: true, requiresAuth: false);

  /// V2 gives a search 45 seconds before calling it timed out; the adapter's default is 30.
  static const _search = HttpRequestOptions(useMobileApiKey: true, requiresAuth: false, timeout: Duration(seconds: 45));

  /// `POST /flights/search`, with V2's body. [currency] asks the server for a `displayPrice`
  /// beside the airline's own figure.
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
    final res = await _client.post(
      '/api/v2/flights/search',
      body: {
        'origin': origin,
        'destination': destination,
        'departureDate': departureDate,
        'returnDate': returnDate,
        'adults': adults,
        'children': children,
        'infants': infants,
        'cabinClass': cabinClass,
        'tripType': tripType,
        'currency': ?currency,
      },
      options: _search,
    );
    final body = res is Map<String, dynamic> ? res : const <String, dynamic>{};
    final offers = (body['offers'] as List?)?.map(FlightFare.tryParse).whereType<FlightFare>().toList() ?? const [];
    return FlightSearchResult(offers: offers, providersFailed: body['providersFailed'] == true);
  }

  /// `POST /flights/revalidate`: is the fare still on sale at the price shown?
  /// Soft failures answer 200 with nothing changed, so a provider hiccup never blocks a booking.
  Future<RevalidateResult> revalidate(FlightFare offer) async {
    final res = await _client.post(
      '/api/v2/flights/revalidate',
      body: {'provider': offer.provider, 'flightPayload': offer.raw},
      options: _public,
    );
    final body = res is Map<String, dynamic> ? res : const <String, dynamic>{};
    return RevalidateResult(
      priceChanged: body['priceChanged'] == true,
      newPrice: (body['newPrice'] as num?)?.toDouble(),
      offerExpired: body['offerExpired'] == true,
    );
  }

  /// `GET /flights/offers/:id` — the offer being bought, with the server's quote of what the card
  /// would be held for, in [currency]. Throws [FareGone] when the airline no longer has it.
  Future<FlightFare?> offer(String offerId, {String? currency}) async {
    try {
      final query = currency == null ? '' : '?currency=${Uri.encodeQueryComponent(currency)}';
      final res = await _client.get('/api/v2/flights/offers/${Uri.encodeComponent(offerId)}$query', options: _public);
      return FlightFare.tryParse(res);
    } on ApiError catch (e) {
      if (e.code == 'OFFER_EXPIRED') throw const FareGone();
      rethrow;
    }
  }

  /// `POST /flights/book` — opens the booking: re-reads the offer, refuses a fare that has risen
  /// past [confirmedPrice], and holds the card's amount. Orders nothing and takes nothing.
  /// Needs a signed-in traveller, as on the web.
  Future<BookingHold> book({
    required String offerId,
    required String displayCurrency,
    double? confirmedPrice,
    required String email,
    required String phone,
    required String phoneCode,
    required List<Map<String, Object?>> passengers,
  }) async {
    final res = await _client.post(
      '/api/v2/flights/book',
      body: {
        'offerId': offerId,
        'displayCurrency': displayCurrency,
        if (confirmedPrice != null && confirmedPrice > 0) 'confirmedPrice': confirmedPrice,
        'contact': {'email': email, 'phone': phone, 'countryCode': phoneCode},
        // Stable per attempt, so a retry after a dropped answer cannot hold a second card.
        'idempotencyKey': 'flight-$offerId-$email-$displayCurrency',
        'passengers': passengers,
      },
    );
    final body = res is Map<String, dynamic> ? res : const <String, dynamic>{};
    final amount = (body['amount'] as num?)?.toDouble();
    return BookingHold(
      clientSecret: body['clientSecret']?.toString() ?? '',
      sessionId: body['sessionId']?.toString() ?? '',
      paymentIntentId: body['paymentIntentId']?.toString() ?? '',
      amount: amount,
      currency: body['currency']?.toString().toUpperCase(),
      fare: (body['fare'] as num?)?.toDouble() ?? amount,
      serviceFee: (body['serviceFee'] as num?)?.toDouble() ?? 0,
    );
  }

  /// `POST /flights/confirm` — once Stripe has authorised the card: api-v2 places the airline
  /// order and takes the money only when the airline says yes. A refusal is an [ApiError]; read
  /// it with [readConfirmFailure].
  Future<FlightConfirmation> confirm({required String paymentIntentId, required String sessionId}) async {
    final res = await _client.post(
      '/api/v2/flights/confirm',
      body: {'paymentIntentId': paymentIntentId, 'sessionId': sessionId},
      // The airline can take two minutes to answer.
      options: const HttpRequestOptions(timeout: Duration(seconds: 150)),
    );
    final body = res is Map<String, dynamic> ? res : const <String, dynamic>{};
    final pnr = body['pnr']?.toString();
    return FlightConfirmation(
      bookingId: body['bookingId']?.toString() ?? '',
      pnr: pnr == null || pnr.isEmpty ? null : pnr,
      status: body['status']?.toString() ?? '',
    );
  }

  /// Where a booking stands, asked by session rather than by payment.
  ///
  /// `confirm` answers once. When it answers `BOOKING_PROCESSING` — the card charged, the
  /// order placed, the booking row not yet readable — nothing else was ever asked, and a
  /// booking that finished a second later went on claiming it was still being worked on. This
  /// is what the settling screen asks, until it has an answer.
  ///
  /// Returns null while there is still nothing to report, so a caller can keep waiting without
  /// telling a traveller anything it does not yet know.
  Future<FlightConfirmation?> bookingStatus(String sessionId) async {
    final res = await _client.get(
      '/api/v2/flights/booking-status?sessionId=$sessionId',
      options: const HttpRequestOptions(timeout: Duration(seconds: 20)),
    );
    final body = res is Map<String, dynamic> ? res : const <String, dynamic>{};

    // Said plainly rather than left to the caller: a failed booking is an outcome, and one
    // the settling screen must stop claiming to be in progress.
    if (body['failed'] == true) {
      throw ApiError(
        body['error']?.toString() ?? 'This booking could not be completed.',
        category: ErrorCategory.server,
        code: body['code']?.toString(),
      );
    }

    if (body['found'] != true) return null;

    final pnr = body['pnr']?.toString();
    return FlightConfirmation(
      bookingId: body['bookingId']?.toString() ?? '',
      pnr: pnr == null || pnr.isEmpty ? null : pnr,
      status: body['status']?.toString() ?? '',
    );
  }
}

/// What `/flights/confirm` answered with when the airline said yes.
class FlightConfirmation {
  const FlightConfirmation({required this.bookingId, this.pnr, required this.status});

  final String bookingId;
  final String? pnr;
  final String status;
}

/// What a refused `/flights/confirm` means, as V2's `readFlightConfirmError` reads it.
sealed class ConfirmFailure {
  const ConfirmFailure();
}

/// The airline has not settled it yet — or no answer came, and the order may be placed anyway.
/// Never "failed, try again": the card may be captured.
class ConfirmProcessing extends ConfirmFailure {
  const ConfirmProcessing({required this.needsReview});
  final bool needsReview;
}

/// The fare rose before the airline confirmed; the hold was released.
class ConfirmPriceChanged extends ConfirmFailure {
  const ConfirmPriceChanged({required this.was, required this.now, required this.currency});
  final double was;
  final double now;
  final String currency;
}

/// The fare sold out before the airline confirmed; the hold was released.
class ConfirmOfferExpired extends ConfirmFailure {
  const ConfirmOfferExpired();
}

/// Any other "no" after which the hold was released, in the server's words.
class ConfirmRefused extends ConfirmFailure {
  const ConfirmRefused(this.message);
  final String message;
}

/// Anything else: the payment may be exactly where it was.
class ConfirmError extends ConfirmFailure {
  const ConfirmError(this.message);
  final String message;
}

const _released = {
  'PRICE_CHANGED',
  'OFFER_EXPIRED',
  'DUFFEL_ORDER_FAILED',
  'INVALID_PHONE',
  'UPSTREAM_UNAVAILABLE',
  'BOOKING_EXPIRED',
};

ConfirmFailure readConfirmFailure(Object error) {
  if (error is! ApiError) return const ConfirmProcessing(needsReview: false);
  final body = error.body ?? const <String, dynamic>{};
  final code = error.code;
  if (code == 'BOOKING_PROCESSING') return ConfirmProcessing(needsReview: body['needsReview'] == true);
  if (code == 'OFFER_EXPIRED') return const ConfirmOfferExpired();
  final was = body['oldPrice'];
  final now = body['newPrice'];
  if (code == 'PRICE_CHANGED' && was is num && now is num) {
    return ConfirmPriceChanged(was: was.toDouble(), now: now.toDouble(), currency: body['currency']?.toString() ?? '');
  }
  if (code != null && _released.contains(code)) return ConfirmRefused(error.message);
  // No answer from the API, or one from something in front of it: the order may well be placed.
  final status = error.status;
  final named = code != null && RegExp(r'^[A-Z][A-Z0-9_]+$').hasMatch(code);
  if (status == null || status == 0 || (!named && status >= 500)) return const ConfirmProcessing(needsReview: false);
  return ConfirmError(error.message);
}

class FlightSearchResult {
  const FlightSearchResult({required this.offers, required this.providersFailed});

  final List<FlightFare> offers;

  /// No offers because an airline could not answer — not the same as no flights on the route.
  final bool providersFailed;
}

class RevalidateResult {
  const RevalidateResult({required this.priceChanged, this.newPrice, required this.offerExpired});

  final bool priceChanged;
  final double? newPrice;
  final bool offerExpired;
}

/// What `/flights/book` says the card is held for.
class BookingHold {
  const BookingHold({
    required this.clientSecret,
    required this.sessionId,
    required this.paymentIntentId,
    this.amount,
    this.currency,
    this.fare,
    this.serviceFee = 0,
  });

  /// The PaymentIntent's secret, which Stripe's sheet pays. Not a key: it can only pay this
  /// one intent.
  final String clientSecret;
  final String sessionId;
  final String paymentIntentId;
  final double? amount;
  final String? currency;
  final double? fare;
  final double serviceFee;
}

/// The airline has stopped selling the fare.
class FareGone implements Exception {
  const FareGone();
}

/// The app's flight API. Replaced in tests.
FlightsApi flightsApi = FlightsApi();

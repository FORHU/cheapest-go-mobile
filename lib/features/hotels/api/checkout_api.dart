import 'package:cheapest_go_mobile/shared/lib/http.dart';

/// The three calls a booking is made of. See #41.
///
/// **Prebook, pay, confirm** — in that order, and none of them optional. api-v2 owns what each
/// does (ADR-0017); this carries the shapes across the wire and does no arithmetic on money.
///
/// The wire shapes here are the ones app-v2's `hotel-checkout-api.ts` reads, field for field.
/// Two rules come with them, and they are the reason this file is not a thinner one:
///
///  * **The charged amount is the server's `display` block.** api-v2 converts into the
///    traveller's currency and adds the service fee; the client charges what it is handed and
///    never works a figure out for itself. No `display`, no payment.
///  * **A confirm that did not confirm is not an error.** It answers 200 with a meaning —
///    pending, needs review, failed — and [ConfirmOutcome] is that meaning. Only `failed` with
///    `released` true means nobody was charged.

/// What api-v2 says the stay costs in the traveller's own currency, fee included.
///
/// Every figure here is the server's. [chargedTotal] is what goes on the card.
class StayPrice {
    const StayPrice({
        required this.currency,
        required this.subtotal,
        required this.taxes,
        required this.total,
        required this.serviceFee,
        required this.chargedTotal,
        required this.converted,
    });

    final String currency;
    final num subtotal;
    final num taxes;

    /// The stay itself, before the service fee.
    final num total;
    final num serviceFee;

    /// The figure on the card. Nothing is billed above it.
    final num chargedTotal;

    /// True when api-v2 converted from the supplier's currency to this one.
    final bool converted;

    static StayPrice? fromJson(Object? raw) {
        if (raw is! Map<String, dynamic>) return null;
        num at(String key) => raw[key] as num? ?? 0;
        return StayPrice(
            currency: (raw['currency'] ?? 'USD').toString().toUpperCase(),
            subtotal: at('subtotal'),
            taxes: at('taxes'),
            total: at('total'),
            serviceFee: at('serviceFee'),
            chargedTotal: raw['chargedTotal'] as num? ?? at('total'),
            converted: raw['converted'] == true,
        );
    }
}

/// The price moved between the property page and the prebook. Said out loud, never charged
/// quietly.
class PriceChange {
    const PriceChange({
        required this.previous,
        required this.current,
        required this.currency,
        required this.up,
    });

    final num previous;
    final num current;
    final String currency;

    /// True when it went up. Down is worth saying too, and is not a problem.
    final bool up;

    static PriceChange? fromJson(Object? raw) {
        if (raw is! Map<String, dynamic>) return null;
        final previous = raw['previous'] as num?;
        final current = raw['current'] as num?;
        if (previous == null || current == null) return null;
        return PriceChange(
            previous: previous,
            current: current,
            currency: (raw['currency'] ?? 'USD').toString().toUpperCase(),
            up: (raw['direction'] ?? '').toString() == 'up',
        );
    }
}

/// A locked rate: what `create-payment` and `confirm` are made against.
class PrebookQuote {
    const PrebookQuote({
        required this.prebookId,
        this.display,
        this.board,
        this.priceChange,
        this.substitutedRoomName,
    });

    final String prebookId;

    /// What to charge, in the traveller's currency. Absent when api-v2 could not price the
    /// stay in it — and then there is nothing honest to charge, so payment does not start.
    final StayPrice? display;
    final String? board;
    final PriceChange? priceChange;

    /// The supplier gave a different room from the one that was picked. Said before paying.
    final String? substitutedRoomName;

    factory PrebookQuote.fromJson(Map<String, dynamic> json) {
        final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
        return PrebookQuote(
            prebookId: (data['prebookId'] ?? '').toString(),
            display: StayPrice.fromJson(data['display']),
            board: data['boardCode']?.toString(),
            priceChange: PriceChange.fromJson(data['priceChange']),
            substitutedRoomName:
                data['roomSubstituted'] == true ? data['substitutedRoomName']?.toString() : null,
        );
    }
}

/// The intent a card is charged against, from api-v2 rather than from Stripe directly: the
/// secret key stays server-side and the amount is set there, so a client cannot name its own
/// price.
class PaymentIntentHandle {
    const PaymentIntentHandle({
        required this.clientSecret,
        required this.paymentIntentId,
        this.reference,
        this.chargedTotal,
        this.serviceFee,
    });

    final String clientSecret;
    final String paymentIntentId;

    /// The booking's reference, issued here rather than at confirm, so a checkout that dies
    /// between paying and confirming still has something to ask about.
    final String? reference;
    final num? chargedTotal;
    final num? serviceFee;

    factory PaymentIntentHandle.fromJson(Map<String, dynamic> json) {
        final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
        final reference = data['bookingReference']?.toString();
        return PaymentIntentHandle(
            clientSecret: (data['clientSecret'] ?? '').toString(),
            paymentIntentId: (data['paymentIntentId'] ?? '').toString(),
            reference: reference == null || reference.isEmpty ? null : reference,
            chargedTotal: data['chargedTotal'] as num?,
            serviceFee: data['serviceFee'] as num?,
        );
    }
}

/// How a confirm turned out.
///
/// A mirror of app-v2's `classifyConfirmResponse`, for the same reason it exists there: these
/// four answers want four different things from the traveller, and telling them apart is not
/// something a screen should do by reading a message string.
enum ConfirmState {
    /// Booked. [ConfirmOutcome.reference] is what the guest quotes to the hotel.
    confirmed,

    /// Someone else is finishing this booking right now. Ask again; do not pay again.
    pending,

    /// The supplier may hold a room and the payment is being kept. A person decides.
    needsReview,

    /// No booking. [ConfirmOutcome.released] says whether the money was given back.
    failed,
}

class ConfirmOutcome {
    const ConfirmOutcome({
        required this.state,
        this.reference = '',
        this.status = '',
        this.message = '',
        this.released = false,
    });

    final ConfirmState state;

    /// The booking's reference, and what the receipt is fetched by.
    final String reference;
    final String status;
    final String message;

    /// Only true on a definitive no: api-v2 voided the authorisation and nobody was charged.
    /// A body that says nothing either way is not grounds to tell someone they are not out of
    /// pocket, so this stays false.
    final bool released;

    bool get isConfirmed => state == ConfirmState.confirmed;

    /// Paid, and a room may well be held — so never an invitation to try again.
    bool get moneyMayBeHeld => state == ConfirmState.pending ||
        state == ConfirmState.needsReview ||
        (state == ConfirmState.failed && !released);

    factory ConfirmOutcome.fromJson(Map<String, dynamic> json) {
        final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : null;
        final bookingId = data?['bookingId']?.toString() ?? '';
        final reference = json['reference']?.toString() ?? '';

        if (json['success'] == true && bookingId.isNotEmpty) {
            return ConfirmOutcome(
                state: ConfirmState.confirmed,
                reference: bookingId,
                status: data?['status']?.toString() ?? 'confirmed',
            );
        }

        final message = json['error']?.toString() ?? _fallback;

        if (json['pending'] == true) {
            return ConfirmOutcome(state: ConfirmState.pending, reference: reference, message: message);
        }
        if (json['needsReview'] == true) {
            return ConfirmOutcome(state: ConfirmState.needsReview, reference: reference, message: message);
        }
        // The supplier booked, above the price that was agreed to. The hold stands and nothing
        // was captured: a person settles this, and the traveller is not asked to retry.
        if (json['errorCode']?.toString() == 'price_changed') {
            return ConfirmOutcome(
                state: ConfirmState.needsReview,
                reference: reference,
                message: 'The price changed while we were booking. '
                    'Our team will confirm the final price with you.',
            );
        }

        return ConfirmOutcome(
            state: ConfirmState.failed,
            reference: reference,
            message: message,
            released: json['providerConfirmed'] == false,
        );
    }

    static const _fallback = 'Something went wrong. Please try again.';
}

class CheckoutApi {
    CheckoutApi({HttpClientAdapter? client}) : _client = client ?? HttpClientAdapter();

    final HttpClientAdapter _client;

    static const _open = HttpRequestOptions(useMobileApiKey: true, requiresAuth: false);
    static const _signedIn = HttpRequestOptions(useMobileApiKey: true, requiresAuth: true);

    /// Locks the rate.
    ///
    /// [currency] is what the traveller is shopping in, and the answer's `display` block is
    /// api-v2's own conversion into it. [expectedTotal] is what they were last shown, so the
    /// answer can say whether it moved.
    Future<PrebookQuote> prebook({
        required String offerId,
        required String currency,
        String? roomName,
        int? adults,
        int? children,
        num? expectedTotal,
    }) async {
        final res = await _client.post(
            '/api/v2/hotels/prebook',
            body: {
                'offerId': offerId,
                'currency': currency,
                'roomName': ?roomName,
                'adults': ?adults,
                'children': ?children,
                if (expectedTotal != null && expectedTotal > 0) 'expectedTotal': expectedTotal,
            },
            options: _open,
        );
        return PrebookQuote.fromJson(res as Map<String, dynamic>);
    }

    /// Asks for an intent for the quote's `display` figure. Signed in, as api-v2 requires: a
    /// booking belongs to an account.
    ///
    /// Who is staying travels with this call as well as with confirm. That is what lets api-v2
    /// finish the booking from Stripe's own event if this app is closed between paying and
    /// confirming.
    ///
    /// Throws when the quote has no `display`: charging a figure the client made up is exactly
    /// what this flow exists to stop.
    Future<PaymentIntentHandle> createPayment({
        required PrebookQuote quote,
        required String firstName,
        required String lastName,
        required String email,
        required DateTime checkIn,
        required DateTime checkOut,
        String? holderPhone,
        String? propertyName,
        String? propertyImage,
        String? roomName,
        int? adults,
        int? children,
        String? specialRequests,
    }) async {
        final display = quote.display;
        if (display == null) {
            throw Exception('We could not confirm the price in your currency just now. '
                'Please try again in a moment.');
        }

        final res = await _client.post(
            '/api/v2/hotels/create-payment',
            body: {
                'prebookId': quote.prebookId,
                'amount': display.total,
                'currency': display.currency,
                // What the summary showed, fee included — nothing is billed above it.
                'displayedTotal': display.chargedTotal,
                'holderEmail': email,
                ..._stay(
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    checkIn: checkIn,
                    checkOut: checkOut,
                    holderPhone: holderPhone,
                    propertyName: propertyName,
                    propertyImage: propertyImage,
                    roomName: roomName,
                    adults: adults,
                    children: children,
                    specialRequests: specialRequests,
                    board: quote.board,
                ),
            },
            options: _signedIn,
        );
        return PaymentIntentHandle.fromJson(res as Map<String, dynamic>);
    }

    /// Books it, once the card has been charged. api-v2 reserves with the supplier and sends
    /// the confirmation email from here, so nothing on the client has to.
    ///
    /// The answer is a [ConfirmOutcome], not a success: see its doc.
    Future<ConfirmOutcome> confirm({
        required String paymentIntentId,
        required PrebookQuote quote,
        required String firstName,
        required String lastName,
        required String email,
        required DateTime checkIn,
        required DateTime checkOut,
        String? holderPhone,
        String? propertyName,
        String? propertyImage,
        String? roomName,
        int? adults,
        int? children,
        String? specialRequests,
    }) async {
        final res = await _client.post(
            '/api/v2/hotels/confirm',
            body: {
                'paymentIntentId': paymentIntentId,
                'prebookId': quote.prebookId,
                'currency': ?quote.display?.currency,
                ..._stay(
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    checkIn: checkIn,
                    checkOut: checkOut,
                    holderPhone: holderPhone,
                    propertyName: propertyName,
                    propertyImage: propertyImage,
                    roomName: roomName,
                    adults: adults,
                    children: children,
                    specialRequests: specialRequests,
                    board: quote.board,
                ),
            },
            options: _signedIn,
        );
        return ConfirmOutcome.fromJson(res as Map<String, dynamic>);
    }

    /// What both create-payment and confirm carry about the stay and who is in it — one shape,
    /// in one place, because api-v2 completes a booking from whichever of the two it has.
    static Map<String, dynamic> _stay({
        required String firstName,
        required String lastName,
        required String email,
        required DateTime checkIn,
        required DateTime checkOut,
        String? holderPhone,
        String? propertyName,
        String? propertyImage,
        String? roomName,
        int? adults,
        int? children,
        String? specialRequests,
        String? board,
    }) {
        String day(DateTime at) =>
            '${at.year.toString().padLeft(4, '0')}-'
            '${at.month.toString().padLeft(2, '0')}-'
            '${at.day.toString().padLeft(2, '0')}';

        String? some(String? value) =>
            value == null || value.trim().isEmpty ? null : value.trim();

        return {
            'holder': {'firstName': firstName, 'lastName': lastName, 'email': email},
            'holderPhone': ?some(holderPhone),
            'propertyName': ?some(propertyName),
            'propertyImage': ?some(propertyImage),
            'roomName': ?some(roomName),
            'checkIn': day(checkIn),
            'checkOut': day(checkOut),
            'adults': ?adults,
            'children': ?children,
            'specialRequests': ?some(specialRequests),
            'board': ?some(board),
        };
    }

    /// The booking row's own id, found by the reference `confirm` answered with.
    ///
    /// Two different ids: `confirm` gives the **reference** a guest quotes to the hotel, while
    /// the receipt is addressed by the row's **UUID**, and nothing in the checkout carries it.
    /// The list is where the two meet. Null when the row is not there yet — api-v2 writes it
    /// as part of confirming, so this is a race rather than a failure, and the caller simply
    /// does not offer the download.
    Future<String?> findBookingId(String reference) async {
        try {
            final res = await _client.get('/api/v2/bookings?type=hotel', options: _signedIn);
            final rows = (res as Map<String, dynamic>)['data'];
            if (rows is! List) return null;
            for (final row in rows) {
                if (row is Map && row['booking_id']?.toString() == reference) {
                    final id = row['id']?.toString();
                    return id == null || id.isEmpty ? null : id;
                }
            }
        } catch (_) {
            // A receipt that cannot be offered is not a booking that failed, so this is quiet.
        }
        return null;
    }

    /// Where the receipt lives.
    ///
    /// api-v2 generates the PDF — the same document the confirmation email links to — and
    /// takes possession of the booking's id as the authorisation, so this opens whether or not
    /// the reader is signed in. Stripe's own receipt is not used: it knows a charge, not a
    /// stay, and a guest claiming expenses needs the property, the nights and the guest name.
    ///
    /// V2 prints its confirmation page instead, because a browser can. This is the better
    /// document: it is the one that was emailed, and it says the same thing on every device.
    static String receiptUrl(String bookingId) =>
        '/api/v2/invoices/$bookingId/pdf?type=hotel';
}

/// The app's instance. Replaced in tests.
CheckoutApi checkoutApi = CheckoutApi();

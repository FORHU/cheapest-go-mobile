/// The traveller's bookings, from api-v2. See ADR-0003.
///
/// Two calls, deliberately independent: `/bookings` answers with whole database rows for
/// hotels and flights together, `/golf/bookings` with a shape of its own. A golf outage costs
/// the golf rows and never the hotels and flights — V2 does the same, for the same reason.
///
/// The rows are the database's, so the field names are the database's: `snake_case`, numbers
/// that may arrive as strings from a `Decimal` column, and dates as ISO strings.
library;

import 'package:cheapest_go_mobile/features/trips/api/bookings_source.dart';
import 'package:cheapest_go_mobile/features/trips/lib/booking_search.dart';
import 'package:cheapest_go_mobile/features/trips/models/trip_booking.dart';
import 'package:cheapest_go_mobile/shared/lib/http.dart';

class ApiBookingsSource implements BookingsSource {
    ApiBookingsSource({HttpClientAdapter? client}) : _client = client ?? HttpClientAdapter();

    final HttpClientAdapter _client;

    static const _signedIn = HttpRequestOptions(useMobileApiKey: true, requiresAuth: true);

    @override
    Future<BookingsPage> myBookings() async {
        // Started together; a slow golf endpoint must not hold up the rest.
        final golfCall = _golf();
        final bookings = await _bookings();
        final golf = await golfCall;

        return BookingsPage(
            bookings: bookings,
            golf: golf ?? const [],
            golfFailed: golf == null,
        );
    }

    Future<List<TripBooking>> _bookings() async {
        final Object? res;
        try {
            res = await _client.get('/api/v2/bookings', options: _signedIn);
        } catch (error) {
            if (_isUnauthorised(error)) throw const NotSignedIn();
            rethrow;
        }

        final rows = _rowsOf(res);
        final out = <TripBooking>[];
        for (final row in rows) {
            if (row is! Map) continue;
            final map = row.cast<String, dynamic>();
            // The list endpoint marks each row, since the two tables are merged into one array.
            final parsed = map['type'] == 'flight' ? _flight(map) : _hotel(map);
            if (parsed != null) out.add(parsed);
        }
        return out;
    }

    /// Null when golf did not answer — distinct from an empty list, which means no bookings.
    Future<List<GolfTeeTimeBooking>?> _golf() async {
        try {
            final res = await _client.get('/api/v2/golf/bookings', options: _signedIn);
            return [
                for (final row in _rowsOf(res))
                    if (row is Map) ?_golfBooking(row.cast<String, dynamic>()),
            ];
        } catch (_) {
            return null;
        }
    }

    // ── Parsing ───────────────────────────────────────────────────────────────

    static List<Object?> _rowsOf(Object? res) {
        if (res is List) return res;
        if (res is Map) {
            for (final key in const ['data', 'bookings']) {
                final value = res[key];
                if (value is List) return value;
            }
        }
        // An empty list is a real answer; an unreadable one must not look like one.
        throw Exception('The bookings response was not understood. Please try again.');
    }

    static HotelStayBooking? _hotel(Map<String, dynamic> m) {
        final checkIn = _date(m['check_in']);
        final checkOut = _date(m['check_out']);
        if (checkIn == null || checkOut == null) return null;

        final metadata = m['provider_metadata'];
        final supplierRef = metadata is Map ? metadata['supplierRef']?.toString() : null;
        final reference = _text(m['booking_id']).isNotEmpty
            ? _text(m['booking_id'])
            : _text(m['booking_reference']);

        return HotelStayBooking(
            id: _text(m['id']).isNotEmpty ? _text(m['id']) : reference,
            reference: reference,
            status: _text(m['status'], 'confirmed'),
            propertyName: _text(m['property_name']),
            roomName: _text(m['room_name']),
            propertyImage: _textOrNull(m['property_image']),
            checkIn: checkIn,
            checkOut: checkOut,
            adults: _int(m['guests_adults']),
            children: _int(m['guests_children']),
            totalPaid: _num(m['total_price']),
            currency: _text(m['currency'], 'USD').toUpperCase(),
            holderFirstName: _text(m['holder_first_name']),
            holderLastName: _text(m['holder_last_name']),
            holderEmail: _text(m['holder_email']),
            specialRequests: _textOrNull(m['special_requests']),
            policyType: _textOrNull(m['policy_type']),
            cancellationPolicy: m['cancellation_policy'] is Map
                ? (m['cancellation_policy'] as Map).cast<String, dynamic>()
                : null,
            supplierReference: supplierRef ?? _textOrNull(m['voucher_code']),
            paymentIntentId: _textOrNull(m['payment_intent_id']),
            bookedAt: _date(m['created_at']),
            searchText: searchTextOf([
                _text(m['property_name']),
                _text(m['room_name']),
                _text(m['booking_reference']),
                _text(m['booking_id']),
                supplierRef,
                _textOrNull(m['voucher_code']),
                _text(m['holder_first_name']),
                _text(m['holder_last_name']),
            ]),
        );
    }

    static FlightTripBooking? _flight(Map<String, dynamic> m) {
        final segments = <FlightSegment>[
            for (final raw in (m['flight_segments'] as List? ?? const []))
                if (raw is Map) ?_segment(raw.cast<String, dynamic>()),
        ]..sort((a, b) => a.departure.compareTo(b.departure));

        final passengers = <FlightPassenger>[
            for (final raw in (m['passengers'] as List? ?? const []))
                if (raw is Map)
                    FlightPassenger(
                        firstName: _text(raw['first_name']),
                        lastName: _text(raw['last_name']),
                        type: _text(raw['type'], 'ADT').toUpperCase(),
                        ticketNumber: _textOrNull(raw['ticket_number']),
                        seatNumber: _textOrNull(raw['seat_number']),
                    ),
        ];

        final tickets = [
            for (final t in (m['ticket_numbers'] as List? ?? const []))
                if (_text(t).isNotEmpty) _text(t),
        ];

        final pnr = _text(m['pnr']);
        return FlightTripBooking(
            id: _text(m['id']),
            reference: _text(m['booking_reference']).isNotEmpty ? _text(m['booking_reference']) : pnr,
            pnr: pnr,
            status: _text(m['status'], 'booked'),
            totalPaid: _num(m['total_price']),
            currency: _text(m['currency'], 'USD').toUpperCase(),
            provider: _text(m['provider']),
            tripType: _textOrNull(m['trip_type']),
            segments: segments,
            passengers: passengers,
            ticketNumbers: tickets,
            ticketedAt: _date(m['ticketed_at']),
            bookedAt: _date(m['created_at']),
            searchText: searchTextOf([
                pnr,
                _text(m['booking_reference']),
                for (final s in segments) ...[
                    s.origin,
                    s.destination,
                    s.airline,
                    s.flightNumber,
                    // The number with its airline in front, as a traveller types it: PR468.
                    '${s.airline}${s.flightNumber}',
                ],
                for (final p in passengers) ...[p.firstName, p.lastName],
                ...tickets,
            ]),
        );
    }

    static FlightSegment? _segment(Map<String, dynamic> m) {
        final departure = _date(m['departure']);
        final arrival = _date(m['arrival']);
        if (departure == null || arrival == null) return null;
        return FlightSegment(
            airline: _text(m['airline']),
            flightNumber: _text(m['flight_number']),
            origin: _text(m['origin']),
            destination: _text(m['destination']),
            departure: departure,
            arrival: arrival,
            cabinClass: _text(m['cabin_class']),
            itineraryIndex: _int(m['itinerary_index']),
            originTerminal: _textOrNull(m['origin_terminal']),
            destinationTerminal: _textOrNull(m['destination_terminal']),
        );
    }

    static GolfTeeTimeBooking? _golfBooking(Map<String, dynamic> m) {
        final startsAt = _date(m['startsAt']);
        if (startsAt == null) return null;
        final course = m['course'] is Map
            ? (m['course'] as Map).cast<String, dynamic>()
            : const <String, dynamic>{};

        return GolfTeeTimeBooking(
            reference: _text(m['reference']),
            status: _text(m['status'], 'requested'),
            players: _int(m['players'], 1),
            leadName: _text(m['leadName']),
            contactEmail: _text(m['contactEmail']),
            totalPaid: _num(m['total']),
            currency: _text(m['currency'], 'USD').toUpperCase(),
            startsAt: startsAt,
            courseName: _text(course['name']),
            courseCity: _text(course['city']),
            courseCountry: _text(course['country']),
            courseImage: _textOrNull(course['imageUrl']),
            greenFee: _num(m['greenFee']),
            serviceFee: _num(m['serviceFee']),
            refundAmount: _num(m['refundAmount']),
            cancellable: m['cancellable'] == true,
            bookedAt: _date(m['createdAt']),
            searchText: searchTextOf([
                _text(course['name']),
                _text(course['city']),
                _text(course['country']),
                _text(m['reference']),
                _text(m['leadName']),
            ]),
        );
    }

    // ── Field readers ─────────────────────────────────────────────────────────
    //
    // Forgiving on purpose: these rows come straight from Postgres through Prisma, so a
    // `Decimal` arrives as a string, a nullable column as null, and a date as ISO text.

    static bool _isUnauthorised(Object error) {
        final text = error.toString();
        return text.contains('401') || text.toLowerCase().contains('unauthor');
    }

    static String _text(Object? value, [String fallback = '']) {
        if (value == null) return fallback;
        final text = value.toString();
        return text.isEmpty ? fallback : text;
    }

    static String? _textOrNull(Object? value) {
        final text = _text(value);
        return text.isEmpty ? null : text;
    }

    static num _num(Object? value) {
        if (value is num) return value;
        return num.tryParse(value?.toString() ?? '') ?? 0;
    }

    static int _int(Object? value, [int fallback = 0]) {
        if (value is int) return value;
        return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    static DateTime? _date(Object? value) {
        if (value is DateTime) return value;
        final text = value?.toString();
        if (text == null || text.isEmpty) return null;
        return DateTime.tryParse(text)?.toLocal();
    }
}

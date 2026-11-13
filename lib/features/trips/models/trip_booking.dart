/// What the traveller has actually booked. See #42 and ADR-0003.
///
/// Three kinds, from two endpoints: hotels and flights arrive together from `/bookings` as
/// whole database rows, golf separately from `/golf/bookings` in a shape of its own. They are
/// one list on screen, so they are one type here — and a sealed one, so a screen that learns
/// to draw two of them cannot quietly forget the third.
///
/// Every one of these exists because the server says so. Nothing on the device constructs one
/// from a checkout; that is the whole point of ADR-0003.
library;

/// A **Booking**, whichever kind.
sealed class TripBooking {
    const TripBooking();

    /// What the detail screen is addressed by. The row's id where there is one, because that
    /// is what a card links to; golf has no row id of its own and uses its reference.
    String get id;

    /// What the traveller quotes to a human. `CG-…` for hotels and golf, the PNR for flights.
    String get reference;

    /// The supplier's own word for where this booking stands, unchanged. Mapping it to
    /// something a person reads is the screen's job, not the model's.
    String get status;

    /// What orders this among the others: the newest booking first, as V2 lists them.
    DateTime? get bookedAt;

    /// What was paid, in [currency]. Never converted here — a charge is not an estimate.
    num get totalPaid;
    String get currency;

    /// Everything this booking can be found by, already folded. See `booking_search.dart`.
    String get searchText;
}

// ─── Hotels ───────────────────────────────────────────────────────────────────

class HotelStayBooking extends TripBooking {
    const HotelStayBooking({
        required this.id,
        required this.reference,
        required this.status,
        required this.propertyName,
        required this.roomName,
        required this.checkIn,
        required this.checkOut,
        required this.totalPaid,
        required this.currency,
        required this.searchText,
        this.propertyImage,
        this.adults = 0,
        this.children = 0,
        this.holderFirstName = '',
        this.holderLastName = '',
        this.holderEmail = '',
        this.specialRequests,
        this.policyType,
        this.cancellationPolicy,
        this.supplierReference,
        this.paymentIntentId,
        this.bookedAt,
    });

    @override
    final String id;
    @override
    final String reference;
    @override
    final String status;
    @override
    final num totalPaid;
    @override
    final String currency;
    @override
    final String searchText;
    @override
    final DateTime? bookedAt;

    final String propertyName;
    final String roomName;
    final String? propertyImage;
    final DateTime checkIn;
    final DateTime checkOut;
    final int adults;
    final int children;
    final String holderFirstName;
    final String holderLastName;
    final String holderEmail;
    final String? specialRequests;

    /// `free_cancellation` or `non_refundable`, as api-v2 stored it at booking time.
    final String? policyType;

    /// The policy as it was agreed, in api-v2's `cancelPolicyInfos` shape.
    final Map<String, dynamic>? cancellationPolicy;

    /// The reference the property's own system holds — see CONTEXT.md. Not the `CG-` one,
    /// which a front desk has never seen.
    final String? supplierReference;
    final String? paymentIntentId;

    String get holderName => '$holderFirstName $holderLastName'.trim();
    int get nights => checkOut.difference(checkIn).inDays.clamp(1, 1 << 20);
    bool get refundable => policyType == 'free_cancellation';
}

// ─── Flights ──────────────────────────────────────────────────────────────────

class FlightSegment {
    const FlightSegment({
        required this.airline,
        required this.flightNumber,
        required this.origin,
        required this.destination,
        required this.departure,
        required this.arrival,
        this.cabinClass = '',
        this.itineraryIndex = 0,
        this.originTerminal,
        this.destinationTerminal,
    });

    final String airline;
    final String flightNumber;
    final String origin;
    final String destination;
    final DateTime departure;
    final DateTime arrival;
    final String cabinClass;

    /// 0 is the outbound, 1 the return. What splits the itinerary into its two halves.
    final int itineraryIndex;
    final String? originTerminal;
    final String? destinationTerminal;
}

class FlightPassenger {
    const FlightPassenger({required this.firstName, required this.lastName, this.ticketNumber});

    final String firstName;
    final String lastName;
    final String? ticketNumber;

    String get name => '$firstName $lastName'.trim();
}

class FlightTripBooking extends TripBooking {
    const FlightTripBooking({
        required this.id,
        required this.reference,
        required this.pnr,
        required this.status,
        required this.totalPaid,
        required this.currency,
        required this.searchText,
        required this.segments,
        required this.passengers,
        this.provider = '',
        this.tripType,
        this.ticketNumbers = const [],
        this.ticketedAt,
        this.bookedAt,
    });

    @override
    final String id;
    @override
    final String reference;
    @override
    final String status;
    @override
    final num totalPaid;
    @override
    final String currency;
    @override
    final String searchText;
    @override
    final DateTime? bookedAt;

    final String pnr;
    final String provider;
    final String? tripType;
    final List<FlightSegment> segments;
    final List<FlightPassenger> passengers;
    final List<String> ticketNumbers;
    final DateTime? ticketedAt;

    List<FlightSegment> get outbound =>
        segments.where((s) => s.itineraryIndex == 0).toList();
    List<FlightSegment> get inbound =>
        segments.where((s) => s.itineraryIndex > 0).toList();

    FlightSegment? get first => segments.isEmpty ? null : segments.first;

    /// The last leg of the outbound, which is where the traveller actually arrives.
    FlightSegment? get lastOutbound {
        final legs = outbound;
        return legs.isEmpty ? first : legs.last;
    }

    bool get isRoundTrip => inbound.isNotEmpty;

    /// Stops on the way out. Two legs is one stop.
    int get stops => outbound.isEmpty ? 0 : outbound.length - 1;
}

// ─── Golf ─────────────────────────────────────────────────────────────────────

class GolfTeeTimeBooking extends TripBooking {
    const GolfTeeTimeBooking({
        required this.reference,
        required this.status,
        required this.players,
        required this.leadName,
        required this.contactEmail,
        required this.totalPaid,
        required this.currency,
        required this.searchText,
        required this.startsAt,
        required this.courseName,
        this.courseCity = '',
        this.courseCountry = '',
        this.courseImage,
        this.greenFee = 0,
        this.serviceFee = 0,
        this.refundAmount = 0,
        this.cancellable = false,
        this.bookedAt,
    });

    /// Golf is addressed by its reference everywhere — it is the only kind with a real
    /// by-reference endpoint, and no row id reaches the client.
    @override
    String get id => reference;

    @override
    final String reference;
    @override
    final String status;
    @override
    final num totalPaid;
    @override
    final String currency;
    @override
    final String searchText;
    @override
    final DateTime? bookedAt;

    final int players;
    final String leadName;
    final String contactEmail;
    final DateTime startsAt;
    final String courseName;
    final String courseCity;
    final String courseCountry;
    final String? courseImage;
    final num greenFee;
    final num serviceFee;

    /// What went back to the card, in [currency].
    final num refundAmount;

    /// api-v2 decides whether cancelling works right now, so no screen has to know the rule.
    final bool cancellable;

    String get where => [courseCity, courseCountry].where((p) => p.isNotEmpty).join(' · ');

    /// A cancelled hold was never charged; a cancelled booking may have been refunded.
    bool get wasCharged => status != 'held' && status != 'expired' && status != 'declined';
}

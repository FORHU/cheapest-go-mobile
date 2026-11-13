/// Bookings for a build with no server. See ADR-0003.
///
/// CI has no api-v2 and the demo APK is handed to people without an account, so `CATALOG=mock`
/// answers from here instead. These are fixtures, not a store: nothing a checkout does reaches
/// them, because in a mock build nothing a checkout does reaches a supplier either.
///
/// Between them they cover what the screen has to get right — each kind, a cancelled booking,
/// a round trip, an unticketed flight (receipt but no e-ticket), and a held tee time that was
/// never charged.
library;

import 'package:cheapest_go_mobile/features/trips/api/bookings_source.dart';
import 'package:cheapest_go_mobile/features/trips/lib/booking_search.dart';
import 'package:cheapest_go_mobile/features/trips/models/trip_booking.dart';

class MockBookingsSource implements BookingsSource {
    const MockBookingsSource();

    @override
    Future<BookingsPage> myBookings() async => BookingsPage(
        bookings: [...hotels, ...flights],
        golf: golf,
    );

    /// Fixed, not relative to today: a fixture that drifts makes a failing test unreadable
    /// a month later.
    static final _booked = DateTime(2026, 11, 13, 9, 30);

    static final hotels = <HotelStayBooking>[
        HotelStayBooking(
            id: 'b1f2c3d4-0000-4000-8000-000000000001',
            reference: 'CG-Y7YY3K',
            status: 'confirmed',
            propertyName: 'Bayside Grand Manila',
            roomName: 'Standard Double Room',
            checkIn: DateTime(2026, 11, 27),
            checkOut: DateTime(2026, 11, 28),
            adults: 2,
            totalPaid: 138,
            currency: 'USD',
            holderFirstName: 'Billy Dhen Clir',
            holderLastName: 'Busilan',
            holderEmail: 'guest@example.com',
            policyType: 'free_cancellation',
            supplierReference: 'OTV-55120934',
            bookedAt: _booked,
            searchText: searchTextOf([
                'Bayside Grand Manila', 'Standard Double Room', 'CG-Y7YY3K',
                'OTV-55120934', 'Billy Dhen Clir', 'Busilan',
            ]),
        ),
        HotelStayBooking(
            id: 'b1f2c3d4-0000-4000-8000-000000000002',
            reference: 'CG-DPY72X',
            status: 'cancelled_refunded',
            propertyName: 'Cebú Harbour Suites',
            roomName: 'Deluxe King',
            checkIn: DateTime(2026, 10, 2),
            checkOut: DateTime(2026, 10, 5),
            adults: 2,
            children: 1,
            totalPaid: 221.40,
            currency: 'USD',
            holderFirstName: 'Billy Dhen Clir',
            holderLastName: 'Busilan',
            holderEmail: 'guest@example.com',
            policyType: 'non_refundable',
            bookedAt: DateTime(2026, 9, 18, 14, 5),
            searchText: searchTextOf([
                'Cebú Harbour Suites', 'Deluxe King', 'CG-DPY72X',
                'Billy Dhen Clir', 'Busilan',
            ]),
        ),
    ];

    static final flights = <FlightTripBooking>[
        // Ticketed and returning: an e-ticket, a receipt, and two halves of itinerary.
        FlightTripBooking(
            id: 'f1f2c3d4-0000-4000-8000-000000000001',
            reference: '4SDPCA',
            pnr: '4SDPCA',
            status: 'ticketed',
            totalPaid: 224,
            currency: 'USD',
            provider: 'Duffel',
            tripType: 'round-trip',
            ticketNumbers: const ['0812345678901'],
            ticketedAt: DateTime(2026, 11, 11, 10, 2),
            bookedAt: DateTime(2026, 11, 11, 9, 58),
            segments: [
                FlightSegment(
                    airline: 'ZZ', flightNumber: '2036', origin: 'MNL', destination: 'ICN',
                    departure: DateTime(2026, 11, 26, 19, 21),
                    arrival: DateTime(2026, 11, 27, 0, 24),
                    cabinClass: 'economy',
                ),
                FlightSegment(
                    airline: 'ZZ', flightNumber: '2037', origin: 'ICN', destination: 'MNL',
                    departure: DateTime(2026, 11, 28, 20, 54),
                    arrival: DateTime(2026, 11, 28, 23, 57),
                    cabinClass: 'economy', itineraryIndex: 1,
                ),
            ],
            passengers: const [
                FlightPassenger(
                    firstName: 'Billy Dhen Clir', lastName: 'Busilan',
                    ticketNumber: '0812345678901',
                ),
            ],
            searchText: searchTextOf([
                '4SDPCA', 'MNL', 'ICN', 'ZZ', '2036', 'ZZ2036',
                'Billy Dhen Clir', 'Busilan', '0812345678901',
            ]),
        ),
        // Paid, not yet ticketed: a receipt, and a reason rather than an e-ticket button.
        FlightTripBooking(
            id: 'f1f2c3d4-0000-4000-8000-000000000002',
            reference: 'QP7T2M',
            pnr: 'QP7T2M',
            status: 'booked',
            totalPaid: 96.50,
            currency: 'USD',
            provider: 'Mystifly',
            tripType: 'one-way',
            bookedAt: DateTime(2026, 11, 12, 16, 40),
            segments: [
                FlightSegment(
                    airline: '5J', flightNumber: '561', origin: 'MNL', destination: 'CEB',
                    departure: DateTime(2026, 12, 3, 6, 15),
                    arrival: DateTime(2026, 12, 3, 7, 40),
                    cabinClass: 'economy',
                ),
            ],
            passengers: const [
                FlightPassenger(firstName: 'Billy Dhen Clir', lastName: 'Busilan'),
            ],
            searchText: searchTextOf([
                'QP7T2M', 'MNL', 'CEB', '5J', '561', '5J561',
                'Billy Dhen Clir', 'Busilan',
            ]),
        ),
    ];

    static final golf = <GolfTeeTimeBooking>[
        GolfTeeTimeBooking(
            reference: 'CG-AW92TH',
            status: 'cancelled',
            players: 1,
            leadName: 'Billy Dhen Clir Busilan',
            contactEmail: 'guest@example.com',
            totalPaid: 134.31,
            currency: 'USD',
            startsAt: DateTime(2026, 11, 26, 8),
            courseName: 'Hallasan Ridge Golf Club',
            courseCity: 'Jeju',
            courseCountry: 'South Korea',
            greenFee: 133.94,
            serviceFee: 0.37,
            bookedAt: DateTime(2026, 11, 9, 11, 20),
            searchText: searchTextOf([
                'Hallasan Ridge Golf Club', 'Jeju', 'South Korea',
                'CG-AW92TH', 'Billy Dhen Clir Busilan',
            ]),
        ),
    ];
}

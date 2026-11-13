/// Where **Bookings** come from. See ADR-0003.
///
/// A seam beside `TravelCatalog`, switched by the same `--dart-define=CATALOG=mock|api`, so
/// one switch still says where all the app's data comes from. Not *on* `TravelCatalog`,
/// because that is the **catalogue** — what is for sale, impersonal, readable signed out —
/// and a Booking belongs to one account. See CONTEXT.md.
library;

import 'package:cheapest_go_mobile/features/trips/api/api_bookings_source.dart';
import 'package:cheapest_go_mobile/features/trips/api/mock_bookings_source.dart';
import 'package:cheapest_go_mobile/features/trips/models/trip_booking.dart';

/// What came back, and whether all of it came back.
///
/// Hotels-and-flights and golf are fetched separately because they are separate endpoints,
/// and a golf outage costs the golf rows and nothing else. The screen needs to know that
/// happened — an empty Golf tab and a broken Golf tab are different answers.
class BookingsPage {
    const BookingsPage({this.bookings = const [], this.golf = const [], this.golfFailed = false});

    /// Hotels and flights, newest first.
    final List<TripBooking> bookings;
    final List<GolfTeeTimeBooking> golf;

    /// The golf endpoint did not answer. Its rows are missing, not absent.
    final bool golfFailed;

    List<TripBooking> get all => [...bookings, ...golf]
        ..sort((a, b) => (b.bookedAt ?? DateTime(0)).compareTo(a.bookedAt ?? DateTime(0)));
}

/// Raised when the traveller is not signed in. The screen sends them to sign in rather than
/// calling it a failure — there is nothing wrong, they simply have not said who they are.
class NotSignedIn implements Exception {
    const NotSignedIn();
}

abstract class BookingsSource {
    /// Everything this traveller has booked. Throws [NotSignedIn] on a 401.
    Future<BookingsPage> myBookings();
}

BookingsSource? _delegate;

/// The app's source. Replaced in tests.
BookingsSource get bookingsSource => _delegate ??= _createDefault();
set bookingsSource(BookingsSource source) => _delegate = source;

BookingsSource _createDefault() {
    const mode = String.fromEnvironment('CATALOG', defaultValue: 'mock');
    return mode == 'api' ? ApiBookingsSource() : const MockBookingsSource();
}

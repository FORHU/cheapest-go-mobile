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
import 'package:cheapest_go_mobile/shared/lib/env.dart';

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

/// One of this traveller's bookings, by row id or by reference — both are in circulation.
///
/// Found in the list rather than fetched on its own, as V2's pages do: `GET /bookings/:id`
/// answers with a hotel-only summary in another shape. A traveller's own bookings are a
/// short list.
Future<TripBooking?> findMyBooking(String idOrReference) async {
    final page = await bookingsSource.myBookings();
    for (final booking in page.all) {
        if (booking.id == idOrReference || booking.reference == idOrReference) return booking;
    }
    return null;
}

BookingsSource? _delegate;

/// The app's source. Replaced in tests.
BookingsSource get bookingsSource => _delegate ??= _createDefault();
set bookingsSource(BookingsSource source) => _delegate = source;

BookingsSource _createDefault() {
    // One reading of the flag, shared with kMockAuth so the two cannot disagree about
    // whether this build talks to a server.
    return kCatalogMode == 'api'
        ? ApiBookingsSource()
        : const MockBookingsSource();
}

/// The two things a traveller can change about a booking from here. See #42.
///
/// Cancelling is deliberately not among them: it reaches the live supplier and a refund path
/// that is not yet trusted, so #42 shows the policy and stops there.
///
/// **The two calls are addressed differently**, which is easy to get wrong and silent when you
/// do: `amend` is looked up by the booking's *reference* (`booking_id`), `share` by the row's
/// *id*. Both are on [HotelStayBooking]; passing the other one 404s.
library;

import 'package:cheapest_go_mobile/features/trips/models/trip_booking.dart';
import 'package:cheapest_go_mobile/shared/lib/http.dart';

class BookingActions {
    BookingActions({HttpClientAdapter? client}) : _client = client ?? HttpClientAdapter();

    final HttpClientAdapter _client;

    static const _signedIn = HttpRequestOptions(useMobileApiKey: true, requiresAuth: true);

    /// Special requests and contact details.
    ///
    /// api-v2 keeps these against the booking and does **not** forward them to the supplier,
    /// so the screen must not promise the property has seen them.
    ///
    /// The whole contact block goes with every call because api-v2 validates all of it: a
    /// remark saved on its own would be rejected for a missing name.
    Future<void> saveRequests(HotelStayBooking booking, String requests) async {
        await _client.post(
            '/api/v2/bookings/amend',
            body: {
                'bookingId': booking.reference,
                'firstName': booking.holderFirstName,
                'lastName': booking.holderLastName,
                'email': booking.holderEmail,
                'remarks': requests.trim(),
            },
            options: _signedIn,
        );
    }

    /// Sends the confirmation to somebody. Addressed by the row id, not the reference.
    Future<void> share(HotelStayBooking booking, String email) async {
        await _client.post(
            '/api/v2/bookings/${booking.id}/share',
            body: {'email': email.trim()},
            options: _signedIn,
        );
    }
}

/// The app's instance. Replaced in tests.
BookingActions bookingActions = BookingActions();

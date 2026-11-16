/// Which **travel documents** a booking has earned. V2's `documents.ts`.
///
/// Three documents, because they evidence three different things and they do not become true
/// at the same moment: a **Payment Receipt** says money was taken, an **E-ticket** says an
/// airline issued a ticket, a **Hotel Voucher** says a property is holding a room. See
/// CONTEXT.md.
///
/// This is the half of the feature that can mislead somebody at a desk, so the rules live here
/// rather than inside a widget: a button offered too early promises a document that does not
/// exist, and silence where one is pending reads as a fault.
library;

import 'package:cheapest_go_mobile/features/trips/models/trip_booking.dart';

enum TravelDocument { eticket, voucher, receipt }

/// Why a document is not there yet, when the booking is paid but has nothing to show.
enum DocumentPending { awaitingTicket, awaitingConfirmation }

/// Statuses where money has been taken and not un-taken.
///
/// **A deliberate difference from V2**, which lists exactly `confirmed, ticketed, booked,
/// completed, cancelled, refunded`. Its own hotel status map also has `cancelled_refunded`
/// and `cancelled_refund_failed`, and neither is in that set — so a refunded stay loses its
/// receipt, which contradicts the rule V2 states one line below it: *paid is paid, even
/// afterwards*. The evidence of what was charged is most wanted exactly when money has come
/// back, or failed to. Mirrored here as the intent rather than as the oversight; V2's set
/// wants the same two entries.
const _paid = {
    'confirmed', 'ticketed', 'booked', 'completed',
    'cancelled', 'refunded', 'cancelled_refunded', 'cancelled_refund_failed',
};

/// A ticket exists only once the airline says so.
///
/// Never the PNR: Duffel and Mystifly both hand one back before issuing, and a booking can
/// carry a record locator for hours with no ticket behind it.
bool isTicketed(FlightTripBooking b) =>
    b.ticketedAt != null || b.ticketNumbers.isNotEmpty || b.status == 'ticketed';

/// The ticket numbers to print, from either shape api-v2 returns them in.
List<String> ticketNumbers(FlightTripBooking b) {
    if (b.ticketNumbers.isNotEmpty) return b.ticketNumbers;
    return [
        for (final p in b.passengers)
            if (p.ticketNumber != null && p.ticketNumber!.isNotEmpty) p.ticketNumber!,
    ];
}

bool isCancelled(TripBooking b) =>
    b.status.startsWith('cancel') || b.status == 'refunded' || b.status == 'declined';

List<TravelDocument> availableDocuments(TripBooking b) {
    final docs = <TravelDocument>[];

    // Paid is paid, even afterwards: a refund is a second entry on the record, not a reason
    // to withdraw the first.
    if (_paid.contains(b.status)) docs.add(TravelDocument.receipt);

    if (isCancelled(b)) return docs;

    switch (b) {
        case FlightTripBooking() when isTicketed(b):
            docs.add(TravelDocument.eticket);
        case HotelStayBooking() when b.status == 'confirmed':
            docs.add(TravelDocument.voucher);
        case GolfTeeTimeBooking():
        case FlightTripBooking():
        case HotelStayBooking():
            break;
    }

    return docs;
}

/// Why a travel document is missing, when the booking is paid but has nothing to show.
/// Null when nothing is owed.
DocumentPending? pendingReason(TripBooking b) {
    if (isCancelled(b)) return null;
    return switch (b) {
        FlightTripBooking() when !isTicketed(b) => DocumentPending.awaitingTicket,
        HotelStayBooking() when b.status != 'confirmed' => DocumentPending.awaitingConfirmation,
        _ => null,
    };
}

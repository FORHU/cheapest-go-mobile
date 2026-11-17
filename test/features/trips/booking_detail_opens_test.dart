import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/features/trips/api/bookings_source.dart';
import 'package:cheapest_go_mobile/features/trips/api/mock_bookings_source.dart';
import 'package:cheapest_go_mobile/features/trips/views/booking_detail_view.dart';

import '../../test_helpers.dart';

/// Opening a booking from My Bookings. See #42.
///
/// This screen went down with a red error the moment it opened, on a device, on a real
/// confirmed flight: `setState(() => _load = _find())`. An arrow body returns the value of
/// the assignment — a `Future` — and Flutter refuses a `setState` callback that returns one.
/// It was also called from `initState`, before there was anything on screen to rebuild.
///
/// Nothing caught it because nothing had ever pumped this screen.
void main() {
  setUp(() => bookingsSource = MockBookingsSource());

  testWidgets('opens without throwing', (tester) async {
    await pumpScreen(tester, const BookingDetailView(bookingId: 'does-not-matter'));

    // The assertion that matters: the framework raised nothing while building it. Before the
    // fix this failed here, whatever the id, because the throw happened in initState.
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the booking it was asked for', (tester) async {
    final page = await MockBookingsSource().myBookings();
    final first = page.all.first;

    await pumpScreen(tester, BookingDetailView(bookingId: first.id));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Found and rendered, rather than left on the not-found state.
    expect(find.textContaining(first.reference), findsWidgets);
  });

  testWidgets('a booking that is not there is a state, not a crash', (tester) async {
    await pumpScreen(tester, const BookingDetailView(bookingId: 'no-such-booking'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

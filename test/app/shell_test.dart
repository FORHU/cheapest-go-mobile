import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cheapest_go_mobile/app/router/app_header.dart';
import 'package:cheapest_go_mobile/app/router/v2_bottom_nav.dart';
import 'package:cheapest_go_mobile/features/trips/api/bookings_source.dart';
import 'package:cheapest_go_mobile/features/trips/api/mock_bookings_source.dart';
import 'package:cheapest_go_mobile/shared/stores/app_refresh.dart';
import 'package:cheapest_go_mobile/shared/stores/bookings_store.dart';
import '../test_helpers.dart';

void main() {
  group('Shared header', () {
    for (final (location, label) in [('/', 'Home'), ('/stay', 'Stay & Play'), ('/flights', 'Flights'), ('/trips', 'Trips')]) {
      testWidgets('shows on $label', (tester) async {
        await pumpApp(tester, location: location);
        expect(find.byType(AppHeader), findsOneWidget);

        // On the landing the header floats over the showcase and offers Sign in, as V2's
        // does; everywhere else it is the bar with the profile button (#38).
        if (location == '/') {
          expect(find.text('Sign in'), findsOneWidget);
          expect(find.byTooltip('Profile and account'), findsNothing);
        } else {
          expect(find.byTooltip('Profile and account'), findsOneWidget);
        }
      });
    }

    testWidgets('shows on the map too', (tester) async {
      await pumpApp(tester, location: '/map');
      expect(find.byType(AppHeader), findsOneWidget);
    });

    testWidgets('profile button opens the profile', (tester) async {
      await pumpApp(tester, location: '/trips');
      await tester.tap(find.byTooltip('Profile and account'));
      await tester.pumpAndSettle();
      expect(find.byType(AppHeader), findsNothing);
      expect(find.text('App Theme'), findsOneWidget);
      expect(find.text('Display Currency'), findsNothing, reason: 'prices are always in pesos');
    });
  });

  testWidgets('Profile › Reset demo data asks first, then clears test bookings', (tester) async {
    SharedPreferences.setMockInitialValues({});
    bookingsStore.addStay(
      airportCode: 'CEB', hotelName: 'Test Stay', roomName: 'Twin', checkIn: DateTime(2099), checkOut: DateTime(2099, 1, 3),
      adults: 2, total: 1000,
    );
    await pumpApp(tester, location: '/profile');
    await tester.scrollUntilVisible(find.text('Reset demo data'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Reset demo data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(bookingsStore.all.any((b) => b.title == 'Test Stay'), isTrue);

    await tester.tap(find.text('Reset demo data'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pumpAndSettle();
    expect(bookingsStore.all.any((b) => b.title == 'Test Stay'), isFalse);
    expect(find.text('Demo data reset'), findsOneWidget);
  });

  /// What replaced pull to refresh in #36.
  ///
  /// V2 has no pull gesture and does not refetch on focus; a screen reloads when you navigate
  /// to it and its data is over a minute old. Mobile matches that, so this drives the same
  /// journey a traveller would: leave Trips, come back a while later, see it asked again.
  ///
  /// Was "reloads bookings saved on the device", which wrote a row into SharedPreferences
  /// because that is what the screen read. #42 pointed My Bookings at api-v2 (ADR-0003), so
  /// the policy is now proved against the source the screen actually uses.
  testWidgets('arriving back on Trips refetches once the data has gone stale', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final source = _CountingBookingsSource();
    bookingsSource = source;
    addTearDown(() => bookingsSource = const MockBookingsSource());

    await pumpApp(tester, location: '/trips');
    await tester.pumpAndSettle();
    expect(source.calls, 1);

    // The pull gesture is gone, and within the stale window nothing reloads — that is the
    // policy, not an oversight.
    await tester.fling(find.byType(Scrollable).first, const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(source.calls, 1, reason: 'no pull to refresh, and the data is still fresh');

    // An hour later, leave and come back the way the bar does it.
    final realClock = refreshClock;
    addTearDown(() => refreshClock = realClock);
    refreshClock = () => DateTime.now().add(const Duration(hours: 1));

    final bar = find.byType(V2BottomNav);
    await tester.tap(find.descendant(of: bar, matching: find.bySemanticsLabel('Home')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: bar, matching: find.bySemanticsLabel('Trips')));
    await tester.pumpAndSettle();

    expect(source.calls, greaterThan(1));
  });
}

/// Counts how many times the screen asked. The answer never changes; whether it asks again
/// is the whole subject.
class _CountingBookingsSource implements BookingsSource {
  int calls = 0;

  @override
  Future<BookingsPage> myBookings() async {
    calls++;
    return const MockBookingsSource().myBookings();
  }
}

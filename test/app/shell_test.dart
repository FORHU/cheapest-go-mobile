import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cheapest_go_mobile/app/router/v2_bottom_nav.dart';
import 'package:cheapest_go_mobile/features/trips/api/bookings_source.dart';
import 'package:cheapest_go_mobile/features/trips/api/mock_bookings_source.dart';
import 'package:cheapest_go_mobile/shared/stores/app_refresh.dart';
import 'package:cheapest_go_mobile/shared/stores/bookings_store.dart';
import '../test_helpers.dart';

void main() {
  // Was "Shared header", asserting one on every tab. There is no header now, on any screen:
  // the wordmark told somebody who had already opened the app whose app it was, and Sign in
  // and the profile button both led where the bar's Settings slot leads. The landing's also
  // covered the top of the photograph its stage is built around. See **Already Here** in
  // CONTEXT.md.
  group('No app header', () {
    for (final (location, label) in [('/', 'the landing'), ('/stay', 'Stay & Play'), ('/flights', 'Flights'), ('/trips', 'Trips'), ('/map', 'the map')]) {
      testWidgets('none on $label', (tester) async {
        await pumpApp(tester, location: location);
        expect(find.byTooltip('Profile and account'), findsNothing);
        expect(find.text('Sign in'), findsNothing);
      });
    }

    // The inset used to be spent on the header and stripped from the page below it. With no
    // header, the page has to keep it — otherwise the heading sits under the status bar,
    // which is the overlap #61 reports.
    testWidgets('a page heading clears the status bar', (tester) async {
      // `pumpApp` runs the phone viewport at a device pixel ratio of 3, so the inset is
      // given in physical pixels and read back in logical ones.
      const inset = 40.0;
      tester.view.padding = const FakeViewPadding(top: inset * 3);
      addTearDown(tester.view.reset);

      await pumpApp(tester, location: '/trips');
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.text('My Bookings')).dy,
        greaterThanOrEqualTo(inset),
        reason: 'the heading is below the status bar, not under it',
      );
    });

    // Was "profile button opens the profile", through a button in the header. That button is
    // gone: it went to the same screen the bar's Settings slot opens, so the account is now
    // reached one way instead of two.
    testWidgets('the bar’s Settings slot opens the account', (tester) async {
      await pumpApp(tester, location: '/trips');
      await tester.tap(find.descendant(
        of: find.byType(V2BottomNav),
        matching: find.bySemanticsLabel('Settings'),
      ));
      await tester.pumpAndSettle();
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

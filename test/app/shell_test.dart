import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cheapest_go_mobile/app/router/app_header.dart';
import 'package:cheapest_go_mobile/shared/stores/bookings_store.dart';
import '../test_helpers.dart';

void main() {
  group('Shared header', () {
    for (final (location, label) in [('/', 'Home'), ('/stay', 'Stay & Play'), ('/flights', 'Flights'), ('/trips', 'Trips')]) {
      testWidgets('shows on $label', (tester) async {
        await pumpApp(tester, location: location);
        expect(find.byType(AppHeader), findsOneWidget);
        expect(find.byTooltip('Profile and account'), findsOneWidget);
      });
    }

    testWidgets('is not on the map, which stays full screen', (tester) async {
      await pumpApp(tester, location: '/map');
      expect(find.byType(AppHeader), findsNothing);
    });

    testWidgets('profile button opens the profile', (tester) async {
      await pumpApp(tester, location: '/trips');
      await tester.tap(find.byTooltip('Profile and account'));
      await tester.pumpAndSettle();
      expect(find.byType(AppHeader), findsNothing);
      expect(find.textContaining('Map View Mode'), findsOneWidget);
    });
  });

  testWidgets('pull to refresh on Trips reloads bookings saved on the device', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpApp(tester, location: '/trips');

    // Another session saved a booking this one hasn't loaded yet.
    final saved = Booking(
      reference: 'CG-PULL1',
      kind: BookingKind.stay,
      airportCode: 'CEB',
      title: 'Refreshed Bay Hotel',
      start: DateTime(2099),
      when: 'Later',
      detail: 'Deluxe King · 2 adults',
      total: 9000,
    );
    SharedPreferences.setMockInitialValues({
      'cheapestgo_bookings_v1': jsonEncode([...bookingsStore.all.map((b) => b.toJson()), saved.toJson()]),
    });
    expect(find.text('Refreshed Bay Hotel'), findsNothing);

    await tester.fling(find.byType(Scrollable).first, const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Refreshed Bay Hotel'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Refreshed Bay Hotel'), findsOneWidget);
  });
}

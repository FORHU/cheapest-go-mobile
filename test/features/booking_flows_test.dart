import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cheapest_go_mobile/app/router/v2_bottom_nav.dart';
import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/shared/stores/bookings_store.dart';
import 'package:cheapest_go_mobile/shared/stores/trip_search_store.dart';

import '../test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tripSearchStore
      ..setAirport('MNL')
      ..setMode(SearchMode.stays);
  });

  testWidgets('search → airport hub → hotel → checkout → trips', (tester) async {
    final before = bookingsStore.all.length;
    await pumpApp(tester);

    await tester.tap(find.text('Search near MNL'));
    await tester.pumpAndSettle();
    expect(find.text('MNL'), findsWidgets);
    expect(find.text('Stays nearby · 10'), findsOneWidget);

    await tester.tap(find.text('Terminal 3 Garden Hotel'));
    await tester.pumpAndSettle();
    expect(find.textContaining('CHOOSE A ROOM'), findsOneWidget);
    await tester.tap(find.text('Twin Room'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reserve'));
    await tester.pumpAndSettle();

    expect(find.text('Review and pay'), findsOneWidget);
    final pay = find.textContaining('Pay ₱');
    await tester.tap(pay);
    await tester.pumpAndSettle();
    expect(find.text('Enter the lead guest’s name'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Full name'), 'Juan Dela Cruz');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email for confirmation'), 'juan@example.com');
    await tester.tap(pay);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(bookingsStore.all.length, before + 1);
    final booking = bookingsStore.all.last;
    expect(booking.kind, BookingKind.stay);
    expect(booking.detail, startsWith('Twin Room'));
    expect(find.text('Trips'), findsWidgets);
    expect(find.text(booking.reference), findsOneWidget);
  });

  testWidgets('golf: pick a tee time and book it for three players', (tester) async {
    final before = bookingsStore.all.length;
    await pumpApp(tester, location: '/golf');

    expect(find.text('Bayshore Links'), findsOneWidget);
    await tester.tap(find.text('6:40 AM'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More players'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Book tee time · ₱18,600'));
    await tester.pumpAndSettle();

    expect(bookingsStore.all.length, before + 1);
    final booking = bookingsStore.all.last;
    expect(booking.kind, BookingKind.teeTime);
    expect(booking.total, 18600);
    expect(booking.when, endsWith('6:40 AM'));
  });

  // Opened directly rather than through the bar: #36 adopted V2's three slots, and V2 reaches
  // flight search from its landing page, not from a tab. Mobile's landing gains that entry
  // point with #38 — until then this journey starts at the route.
  testWidgets('flights: SIN → MNL, pick the cheapest non-stop, pay', (tester) async {
    final before = bookingsStore.all.length;
    await pumpApp(tester, location: '/flights');
    await tester.pumpAndSettle();
    expect(find.text('FROM'), findsOneWidget);
    expect(find.text('SIN'), findsWidgets);

    await tester.tap(find.text('Non-stop').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('1 stop'), findsNothing);

    await tester.tap(find.text('Cheapest').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Full name (as on passport)'), 'Juan Dela Cruz');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email for e-ticket'), 'juan@example.com');
    await tester.tap(find.textContaining('Pay ₱'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(bookingsStore.all.length, before + 1);
    final booking = bookingsStore.all.last;
    expect(booking.kind, BookingKind.flight);
    expect(booking.detail, startsWith('SIN → MNL · Non-stop'));
    expect(find.text(booking.reference), findsOneWidget);
  });

  // Reached from Home rather than a tab since #36; Home still links here.
  testWidgets('Stay & Play switches between hotels and golf', (tester) async {
    await pumpApp(tester, location: '/stay');
    await tester.pumpAndSettle();
    expect(find.text('Terminal 3 Garden Hotel'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);

    await tester.tap(find.text('Golf'));
    await tester.pumpAndSettle();
    expect(find.text('Bayshore Links'), findsOneWidget);
  });

  testWidgets('hotel results filter by free shuttle', (tester) async {
    await pumpApp(tester, location: '/hotels');
    // Nearest first: the pod hotel (no shuttle) leads the MNL list.
    expect(find.text('Transit Pods NAIA'), findsOneWidget);

    await tester.ensureVisible(find.text('Free shuttle'));
    await tester.tap(find.text('Free shuttle'));
    await tester.pumpAndSettle();
    expect(find.text('Transit Pods NAIA'), findsNothing);
    expect(find.text('Terminal 3 Garden Hotel'), findsOneWidget);
  });

  testWidgets('saving a hotel lists it under Trips › Saved, in dark mode', (tester) async {
    await pumpApp(tester, location: '/hotels', theme: AppTheme.dark);
    await tester.tap(find.byTooltip('Save hotel').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    // The bar shows icons only now, so the slot is found by the name it carries for screen
    // readers rather than by a visible label.
    await tester.tap(find.descendant(
      of: find.byType(V2BottomNav),
      matching: find.bySemanticsLabel('Trips'),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('Transit Pods NAIA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

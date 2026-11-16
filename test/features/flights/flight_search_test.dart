import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cheapest_go_mobile/features/flights/api/flights_api.dart';
import 'package:cheapest_go_mobile/features/flights/components/flight_card.dart';
import 'package:cheapest_go_mobile/features/flights/views/flight_checkout_view.dart';
import 'package:cheapest_go_mobile/features/flights/views/flight_search_view.dart';
import 'package:cheapest_go_mobile/shared/stores/trip_search_store.dart';

import '../../test_helpers.dart';
import 'fixtures.dart';

/// V2's `/flights/search` and the step into checkout (#47), driven through the app's router.
/// The fares are fixtures in api-v2's exact shape; nothing here reaches the catalogue's
/// invented flights.
void main() {
  late FakeFlightsApi api;
  final original = flightsApi;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = FakeFlightsApi();
    flightsApi = api;
  });
  tearDown(() => flightsApi = original);

  const search =
      '/flights/search?origin=Manila%20(MNL)&destination=Singapore%20(SIN)&depart=2099-12-03&adults=1&cabin=economy';

  Future<void> open(WidgetTester tester, [String location = search]) async {
    await pumpApp(tester, location: location);
    // The page holds its skeletons for at least a second and a half, as V2 does.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  testWidgets('asks api-v2 for the route the link names, and lists what comes back', (tester) async {
    await open(tester);

    expect(api.searches.single, {
      'origin': 'MNL',
      'destination': 'SIN',
      'departureDate': '2099-12-03',
      'returnDate': null,
      'adults': 1,
      'cabinClass': 'economy',
      'tripType': 'one-way',
    });
    expect(find.text('Flights to Singapore'), findsOneWidget);
    expect(find.text('3 flights found'), findsOneWidget);
    expect(find.byType(FlightCard), findsNWidgets(3));
    expect(find.text('Duffel Airways'), findsOneWidget);
    expect(find.text('Philippine Airlines'), findsOneWidget);

    // V2's phone card: the badges, the chips, the price per person and Select.
    expect(find.text('CHEAPEST'), findsOneWidget);
    expect(find.text('FASTEST'), findsOneWidget);
    expect(find.text('1 carry-on · 1 checked'), findsWidgets);
    expect(find.text('Non-refundable'), findsOneWidget);
    expect(find.text(r'$116'), findsOneWidget);
    expect(find.text('Select'), findsNWidgets(3));
  });

  testWidgets('cheapest first: the cards come in V2\'s default order', (tester) async {
    await open(tester);
    final airlines = tester.widgetList<FlightCard>(find.byType(FlightCard)).map((c) => c.offer.offerId).toList();
    expect(airlines, ['off_duffel', 'off_sq', 'off_pal']);
  });

  testWidgets('Flight details opens the itinerary, flight by flight', (tester) async {
    await open(tester);
    await tester.tap(find.text('Flight details').at(1)); // the connection through KUL
    await tester.pumpAndSettle();

    expect(find.text('LAYOVER'), findsOneWidget);
    expect(find.text('1h 10m at KUL Airport'), findsOneWidget);
    expect(find.text('DEPART FROM'), findsNWidgets(2));
  });

  testWidgets('a date that has gone is replaced, and the page says it picked one', (tester) async {
    await open(tester, '/flights/search?origin=MNL&destination=SIN&depart=2001-01-01');
    expect(find.text('We picked this date — change it to see other fares.'), findsOneWidget);
    expect(api.searches.single['departureDate'], isNot('2001-01-01'));
  });

  testWidgets('an outage is an error with a way out, not "no flights on this route"', (tester) async {
    api.providersFailed = true;
    await open(tester);
    expect(find.text('Search Error'), findsOneWidget);
    expect(find.textContaining('We could not reach the airlines'), findsOneWidget);
    expect(find.text('No flights found'), findsNothing);
  });

  testWidgets('a route nobody can resolve is refused before the airline is asked', (tester) async {
    await open(tester, '/flights/search?origin=Atlantis&destination=SIN&depart=2099-12-03');
    expect(api.searches, isEmpty);
    expect(find.text('Tell us where you are flying from and to, and we will find the fares.'), findsOneWidget);
  });

  testWidgets('filters: Direct narrows the list, and the bar shows it is on', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();

    // V2's sections, in V2's order.
    expect(find.text('SORT BY'), findsOneWidget);
    expect(find.text('Cheapest First'), findsOneWidget);
    expect(find.text('AIRLINES'), findsOneWidget);
    expect(find.text('Select all airlines'), findsOneWidget);

    final drawer = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(find.text('Direct'), 120, scrollable: drawer);
    await tester.tap(find.text('Direct'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Show 2 flights'), 300, scrollable: drawer);
    await tester.tap(find.text('Show 2 flights'));
    await tester.pumpAndSettle();

    expect(find.text('2 flights found'), findsOneWidget);
    expect(find.byType(FlightCard), findsNWidgets(2));
  });

  testWidgets('Select checks the fare with the airline, then opens checkout for that offer', (tester) async {
    await open(tester);
    await tester.tap(find.text('Select').first);
    await tester.pumpAndSettle();

    expect(api.revalidated, ['off_duffel']);
    final checkout = tester.widget<FlightCheckoutView>(find.byType(FlightCheckoutView));
    expect(checkout.params['offerId'], 'off_duffel');
    expect(checkout.params['fareCurrency'], 'USD');
    expect(checkout.params['totalAmount'], '116.17');
    expect(checkout.params['origin'], 'MNL');
    expect(checkout.params['destination'], 'SIN');
    expect(checkout.params['departureDate'], '2026-12-03');
    expect(checkout.params['adults'], '1');
    expect(Uri.splitQueryString(checkout.params['search']!)['origin'], 'Manila (MNL)');
  });

  testWidgets('a fare that has gone searches again here, and says why', (tester) async {
    api.revalidateResult = const RevalidateResult(priceChanged: false, offerExpired: true);
    await open(tester);
    await tester.tap(find.text('Select').first);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(FlightCheckoutView), findsNothing);
    expect(api.searches, hasLength(2));
    expect(find.text('That fare is no longer available'), findsOneWidget);
  });

  testWidgets('a fare that went up is a question, not a surprise at payment', (tester) async {
    api.revalidateResult = const RevalidateResult(priceChanged: true, newPrice: 130, offerExpired: false);
    await open(tester);
    await tester.tap(find.text('Select').first);
    await tester.pumpAndSettle();

    expect(find.textContaining(r'has changed to $130'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(tester.widget<FlightCheckoutView>(find.byType(FlightCheckoutView)).params['totalAmount'], '130.0');
  });

  testWidgets('/flights opens the search for the trip being planned', (tester) async {
    tripSearchStore
      ..setOrigin('SIN')
      ..setAirport('MNL');
    await pumpApp(tester, location: '/flights');
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(FlightSearchView), findsOneWidget);
    expect(api.searches.single['origin'], 'SIN');
    expect(api.searches.single['destination'], 'MNL');
  });

  testWidgets('V2\'s /flights/book hands a chosen offer to checkout', (tester) async {
    await pumpApp(tester, location: '/flights/book?offerId=off_duffel&origin=MNL&destination=SIN');
    expect(tester.widget<FlightCheckoutView>(find.byType(FlightCheckoutView)).params['offerId'], 'off_duffel');
  });
}

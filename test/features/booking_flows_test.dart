import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/features/auth/stores/auth_store.dart';
import 'package:cheapest_go_mobile/features/hotels/api/checkout_api.dart';
import 'package:cheapest_go_mobile/shared/payments/payment_gateway.dart';
import 'package:cheapest_go_mobile/shared/lib/http.dart';
import 'package:cheapest_go_mobile/shared/saved/saved_trips_store.dart';
import 'package:cheapest_go_mobile/shared/stores/bookings_store.dart';
import 'package:cheapest_go_mobile/shared/stores/trip_search_store.dart';

import '../test_helpers.dart';
import 'checkout_fakes.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tripSearchStore
      ..setAirport('MNL')
      ..setMode(SearchMode.stays);
  });

  // api-v2 ties a booking to an account, so every checkout journey starts signed in. The one
  // test about being signed out signs out for itself.
  setUp(() async {
    await authStore.signInDemo();
  });

  // The real api-v2 and the real Stripe sheet are out of a widget test's reach, so each test
  // installs its own and the app's own are put back after.
  tearDown(() {
    checkoutApi = CheckoutApi();
    paymentGateway = const StripePaymentGateway();
  });

  // Opened at the hub rather than reached from Home. V2 has no airport hub, so #38's landing
  // does not link to one and the surface is dormant — kept, with its tests, per ADR-0001.
  testWidgets('airport hub → hotel → checkout → trips', (tester) async {
    final before = bookingsStore.all.length;
    final api = FakeCheckoutApi();
    final gateway = FakePaymentGateway();
    checkoutApi = api;
    paymentGateway = gateway;
    await pumpApp(tester, location: '/airport/MNL');

    expect(find.text('MNL'), findsWidgets);
    expect(find.text('Stays nearby · 10'), findsOneWidget);

    await tester.tap(find.text('Terminal 3 Garden Hotel'));
    await tester.pumpAndSettle();
    // V2's own heading, from the mirrored copy — the old screen shouted "CHOOSE A ROOM".
    expect(find.textContaining('Available Rooms'), findsOneWidget);
    // The checkout bar floats over the foot of the page, so the card is scrolled clear of it
    // before it is tapped — on a handset a thumb does the same thing.
    await tester.ensureVisible(find.text('Twin Room'));
    await tester.pumpAndSettle();
    // A room is a card and its offers are the rows inside it, so this picks the room by
    // name and then takes the terms it is headlined with. ADR-0007 in the web repo.
    await tester.tap(find.text('Twin Room'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reserve'));
    await tester.pumpAndSettle();

    // Details, the first of V2's three steps. Nothing is reserved yet and no rate is locked.
    expect(find.text('Complete your booking'), findsOneWidget);
    // Prefilled from the signed-in account, as V2 does.
    expect(find.text('Juan'), findsWidgets);

    // A hole in the form does not prebook, so nothing is asked of api-v2 or of the supplier.
    await tester.enterText(find.widgetWithText(TextFormField, 'e.g. johndoe@gmail.com'), '');
    await tester.tap(find.text('Continue to payment'));
    await tester.pumpAndSettle();
    expect(find.text('Payment Details'), findsNothing);
    expect(api.calls, isEmpty);

    await _fillGuest(tester);

    // Payment. The figure on the card is api-v2's own, fee included.
    expect(find.text('Payment Details'), findsOneWidget);
    expect(find.text('₱13,200'), findsWidgets);
    await tester.tap(find.text('Pay ₱13,200'));
    await tester.pumpAndSettle();

    // Prebooked, charged, then booked — and in that order: a room is never reserved before
    // the money has moved, and never charged before the rate is locked.
    expect(api.calls, ['prebook:twin', 'createPayment:pre_1', 'confirm:pi_1']);
    expect(gateway.presented, isTrue);
    // The figure on the card is api-v2's, fee included, and the stay total under it.
    expect(api.sent['createPayment']!['amount'], 12000);
    expect(api.sent['createPayment']!['displayedTotal'], 13200);
    // The guest travels with create-payment too, so api-v2 can finish the booking from
    // Stripe's event alone if this app dies between paying and confirming.
    expect(api.sent['createPayment']!['name'], 'Juan Dela Cruz');
    expect(api.sent['confirm']!['email'], 'juan@example.com');
    expect(api.sent['confirm']!['prebookId'], 'pre_1');

    // V2's confirmation, element for element: the stamp, the reference, the receipt card.
    expect(find.text('BOOKED'), findsOneWidget);
    expect(find.text("You're all set!"), findsOneWidget);
    expect(find.text('Booking Reference'), findsOneWidget);
    expect(find.text('CG-ABC12'), findsOneWidget);
    expect(find.text('Terminal 3 Garden Hotel'), findsWidgets);
    expect(find.text('Price breakdown'), findsOneWidget);
    expect(find.text('Service fee'), findsOneWidget);
    // What Stripe took, from the intent — not a figure this screen worked out.
    expect(find.text('Total paid'), findsOneWidget);
    expect(find.text('₱13,200'), findsWidgets);
    expect(find.text('Plan another trip'), findsOneWidget);

    // #41 wrote the stay into the local store here so Trips would show it. #42 pointed Trips
    // at api-v2, which already has this booking, so that row would only be a duplicate — see
    // ADR-0003. Nothing local is written, and that is the assertion.
    expect(bookingsStore.all.length, before);

    await tester.ensureVisible(find.text('View My Trips'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View My Trips'));
    await tester.pumpAndSettle();
    // Trips now answers from the source, not from what checkout just did.
    expect(find.text('My Bookings'), findsOneWidget);
  });

  testWidgets('shutting the card sheet charges nothing and keeps the checkout open', (tester) async {
    final before = bookingsStore.all.length;
    final api = FakeCheckoutApi();
    final gateway = FakePaymentGateway(cancel: true);
    checkoutApi = api;
    paymentGateway = gateway;

    await pumpApp(tester, location: '/checkout?hotel=mnl-t3-garden&room=twin');
    await tester.enterText(find.widgetWithText(TextFormField, 'e.g. John'), 'Juan');
    await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Doe'), 'Dela Cruz');
    await tester.enterText(find.widgetWithText(TextFormField, 'e.g. johndoe@gmail.com'), 'juan@example.com');
    await tester.tap(find.text('Continue to payment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pay ₱13,200'));
    await tester.pumpAndSettle();

    // No confirm, no booking, and no error shouted at someone who simply changed their mind.
    expect(api.calls, ['prebook:twin', 'createPayment:pre_1']);
    expect(bookingsStore.all.length, before);
    expect(find.text('Payment Details'), findsOneWidget);
    expect(find.text('Pay ₱13,200'), findsOneWidget);
  });

  testWidgets('a confirm that did not confirm never invites a second payment', (tester) async {
    final before = bookingsStore.all.length;
    // api-v2's own shape for it: 200, with a meaning rather than an error.
    checkoutApi = FakeCheckoutApi(confirm: {
      'success': false,
      'needsReview': true,
      'providerConfirmed': true,
      'reference': 'CG-REV99',
      'error': 'We are confirming this booking with the hotel.',
    });
    paymentGateway = FakePaymentGateway();

    await pumpApp(tester, location: '/checkout?hotel=mnl-t3-garden&room=twin');
    await _fillGuest(tester);
    await tester.tap(find.text('Pay ₱13,200'));
    await tester.pump();
    await tester.pump();

    // The card was charged and a room may be held, so the checkout hands over to the
    // confirmation screen (#50), which asks after the reference until it settles. There is no
    // Pay button to press again and nothing calls this confirmed.
    expect(find.text("We're confirming this with the hotel"), findsOneWidget);
    expect(find.textContaining("Please don't pay again"), findsOneWidget);
    expect(find.textContaining('CG-REV99', findRichText: true), findsOneWidget);
    expect(find.textContaining('Pay ₱'), findsNothing);
    expect((checkoutApi as FakeCheckoutApi).calls.last, 'status:CG-REV99');
    // Not booked, so nothing goes into Trips claiming it was.
    expect(bookingsStore.all.length, before);
  });

  testWidgets('the confirmation screen turns "confirming" into "booked" by itself', (tester) async {
    final api = FakeCheckoutApi(confirm: {'success': false, 'pending': true, 'reference': 'CG-PEN01'})
      ..statuses = [
        {'status': 'SUPPLIER_BOOKING', 'bookingStatus': 'pending'},
        {'status': 'CONFIRMED', 'bookingStatus': 'confirmed'},
      ];
    checkoutApi = api;
    paymentGateway = FakePaymentGateway();

    await pumpApp(tester, location: '/checkout?hotel=mnl-t3-garden&room=twin');
    await _fillGuest(tester);
    await tester.tap(find.text('Pay ₱13,200'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Confirming your booking'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('BOOKED'), findsOneWidget);
    expect(api.calls.where((c) => c.startsWith('status:')), hasLength(2));
  });

  testWidgets('an unsettled confirm with no reference stays on the checkout, still never asking twice', (tester) async {
    checkoutApi = FakeCheckoutApi(confirm: {
      'success': false,
      'needsReview': true,
      'error': 'We are confirming this booking with the hotel.',
    });
    paymentGateway = FakePaymentGateway();

    await pumpApp(tester, location: '/checkout?hotel=mnl-t3-garden&room=twin');
    await _fillGuest(tester);
    await tester.tap(find.text('Pay ₱13,200'));
    await tester.pumpAndSettle();

    // Nothing to ask after, so nothing to hand over to.
    expect(find.text('Your payment went through'), findsOneWidget);
    expect(find.textContaining('Do not pay again'), findsOneWidget);
    expect(find.textContaining('Pay ₱'), findsNothing);
  });

  testWidgets('a quote api-v2 could not price is never charged', (tester) async {
    final api = FakeCheckoutApi(prebook: prebookBody(withDisplay: false));
    final gateway = FakePaymentGateway();
    checkoutApi = api;
    paymentGateway = gateway;

    await pumpApp(tester, location: '/checkout?hotel=mnl-t3-garden&room=twin');
    await _fillGuest(tester);

    // No figure from the server means no figure at all. The bar names no price and does
    // nothing when pressed: no intent is asked for and no sheet opens.
    expect(find.text('Confirming the final price…'), findsNWidgets(2));
    expect(find.textContaining('Pay ₱'), findsNothing);
    await tester.tap(find.text('Confirming the final price…').last);
    await tester.pumpAndSettle();
    expect(api.calls, ['prebook:twin']);
    expect(gateway.presented, isFalse);
  });

  testWidgets('signed out, checkout asks for sign-in before it locks a rate', (tester) async {
    await authStore.logout();
    final api = FakeCheckoutApi();
    checkoutApi = api;
    paymentGateway = FakePaymentGateway();

    await pumpApp(tester, location: '/checkout?hotel=mnl-t3-garden&room=twin');
    expect(find.text('Sign in to complete your booking'), findsOneWidget);
    await _fillGuest(tester);

    // create-payment and confirm both need an account, so the form stops here rather than
    // letting someone reach for a card and meet a 401.
    expect(api.calls, isEmpty);
    expect(find.text('Payment Details'), findsNothing);
  });

  testWidgets('a declined card is reported and books nothing', (tester) async {
    final before = bookingsStore.all.length;
    checkoutApi = FakeCheckoutApi();
    paymentGateway = FakePaymentGateway(declineWith: 'Your card was declined.');

    await pumpApp(tester, location: '/checkout?hotel=mnl-t3-garden&room=twin');
    await tester.enterText(find.widgetWithText(TextFormField, 'e.g. John'), 'Juan');
    await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Doe'), 'Dela Cruz');
    await tester.enterText(find.widgetWithText(TextFormField, 'e.g. johndoe@gmail.com'), 'juan@example.com');
    await tester.tap(find.text('Continue to payment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pay ₱13,200'));
    await tester.pumpAndSettle();

    expect(find.text('Your card was declined.'), findsOneWidget);
    expect(bookingsStore.all.length, before);
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

  // Reached from Home rather than a tab since #36; Home still links here.
  testWidgets('Stay & Play switches between hotels and golf', (tester) async {
    await pumpApp(tester, location: '/stay');
    await tester.pumpAndSettle();
    // Read from the list. Mock stays carry no coordinates, so there is no map to draw and
    // the screen falls back to the list — which is also what a live search does when the
    // supplier answers with stays we hold no content for. The count plate belongs to the
    // map and goes with it.
    expect(find.text('Transit Pods NAIA'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);

    await tester.tap(find.text('Golf'));
    await tester.pumpAndSettle();
    expect(find.text('Bayshore Links'), findsOneWidget);
  });

  testWidgets('a result card opens that property', (tester) async {
    // The link was `/hotels/<id>` while the route is `/hotel/:id`, so every card on the
    // results screen landed on the router's not-found page. Nothing caught it: the tests
    // reached the property from the airport hub and from Trips, never from a search result.
    await pumpApp(tester, location: '/hotels');

    // Read from the list rather than the map. The strip of cards along the bottom is gone on
    // mobile (the client asked for it), and the mock catalogue gives its stays no
    // coordinates, so the map has no pins to press here. `stay_map_card_test.dart` covers the
    // pin and the card it opens, with stays that do carry coordinates.
    await tester.tap(find.byTooltip('List View'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Book Now').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Page not found'), findsNothing);
    expect(find.textContaining('Available Rooms'), findsOneWidget);
  });

  testWidgets('hotel results narrow by star rating', (tester) async {
    await pumpApp(tester, location: '/hotels');
    // The list, because mock stays carry no coordinates and a map with nothing to place on
    // it falls back to one. All ten are there to start with.
    expect(find.text('Transit Pods NAIA'), findsOneWidget);

    // What this replaced: a "Free shuttle" pill. V2 offers no such filter — its set is the
    // sort, the star categories and the price — so #39 narrows by stars instead. Of the ten
    // stays near MNL two score below eight, which is four stars to the others' five.
    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4 stars'));
    await tester.pumpAndSettle();
    // The sheet's button names what the choice leaves, and recounts as it changes.
    await tester.tap(find.text('2 Stays'));
    await tester.pumpAndSettle();

    // Which two, read off the list.
    expect(find.text('Transit Pods NAIA'), findsOneWidget);
  });

  testWidgets('hearting a stay saves it to the account, in dark mode', (tester) async {
    final saved = _RecordingSaves();
    savedTripsStore = SavedTripsStore(client: saved);
    addTearDown(() => savedTripsStore = SavedTripsStore());

    await pumpApp(tester, location: '/hotels', theme: AppTheme.dark);
    // The bookmark is on the list card, where V2 puts it: the map's rail card carries the
    // picture, the price and View, and nothing else.
    await tester.tap(find.byTooltip('List View'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Save this stay').first);
    await tester.pumpAndSettle();

    // The heart now writes to the account (#43), so what it sent is what this checks —
    // the row the web's account page will draw, carrying the stay's own details.
    final sent = saved.posted.single;
    expect(sent['type'], 'hotel');
    expect(sent['title'], 'Transit Pods NAIA');
    expect(sent['snapshot'], isA<Map>().having((s) => s['hotelId'], 'hotelId', isNotEmpty));
    // V2's path, not mobile's: the account page on the web links through this field.
    expect(sent['deepLink'], startsWith('/property/'));
    expect(tester.takeException(), isNull);
  });
}


/// The details step, filled in. Every checkout test passes through it, and none of them is
/// about typing.
Future<void> _fillGuest(WidgetTester tester) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'e.g. John'), 'Juan');
  await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Doe'), 'Dela Cruz');
  await tester.enterText(
    find.widgetWithText(TextFormField, 'e.g. johndoe@gmail.com'),
    'juan@example.com',
  );
  await tester.tap(find.text('Continue to payment'));
  await tester.pumpAndSettle();
}

/// api-v2's saved-trips endpoint, remembering what the heart sent it.
class _RecordingSaves implements HttpClientAdapter {
  final posted = <Map<String, dynamic>>[];

  @override
  Future<dynamic> get(String url, {HttpRequestOptions? options}) async => {'trips': <dynamic>[]};

  @override
  Future<dynamic> post(String url, {Object? body, HttpRequestOptions? options}) async {
    final sent = (body as Map).cast<String, dynamic>();
    posted.add(sent);
    return {
      'success': true,
      'data': {
        'id': 'row-1',
        'type': sent['type'],
        'title': sent['title'],
        'deep_link': sent['deepLink'],
        'snapshot': sent['snapshot'],
      },
    };
  }

  @override
  Future<dynamic> delete(String url, {Object? body, HttpRequestOptions? options}) async =>
      {'success': true};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

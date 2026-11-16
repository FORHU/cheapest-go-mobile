import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/features/flights/views/flight_checkout_view.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/errors/api_error.dart';

import '../../test_helpers.dart';
import '../checkout_fakes.dart' show FakePaymentGateway;
import 'fixtures.dart';

/// The booking flow's steps and validation, as V2's flight checkout has them (#47).
void main() {
  const params = {
    'offerId': 'off_duffel',
    'totalAmount': '116.17',
    'currency': 'PHP',
    'fareCurrency': 'USD',
    'origin': 'MNL',
    'destination': 'SIN',
    'departureDate': '2026-12-03',
    'cabin': 'economy',
    'adults': '1',
    'search': 'origin=Manila+%28MNL%29&destination=SIN&depart=2026-12-03',
  };

  late FakeFlightsApi api;
  late FakePaymentGateway gateway;
  late bool signedIn;
  late int signInAsked;
  late List<String> went;

  Future<void> pump(WidgetTester tester) async {
    usePhoneViewport(tester);
    final router = GoRouter(
      initialLocation: '/flight-checkout',
      routes: [
        GoRoute(
          path: '/flight-checkout',
          builder: (_, _) => FlightCheckoutView(
            params: params,
            api: api,
            gateway: gateway,
            now: DateTime(2026, 11, 12),
            isSignedIn: () => signedIn,
            onSignIn: () => signInAsked++,
          ),
        ),
        GoRoute(
          path: '/trips',
          builder: (_, _) => const Scaffold(body: Text('trips page')),
        ),
        GoRoute(
          path: '/flights/search',
          builder: (_, state) {
            went.add(state.uri.toString());
            return const Scaffold(body: Text('search page'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    api = FakeFlightsApi();
    gateway = FakePaymentGateway();
    signedIn = true;
    signInAsked = 0;
    went = [];
  });

  Future<void> enter(WidgetTester tester, String label, String text) async {
    final field = find.descendant(
      of: find.ancestor(of: find.text(label, findRichText: true), matching: find.byType(Column)).first,
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(field.first);
    await tester.enterText(field.first, text);
  }

  Future<void> pickDate(WidgetTester tester, String label) async {
    // A focused text field scrolls itself back into view; let go of it first, or it moves the
    // list out from under the tap.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final field = find.text('Select date').first;
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.tap(field);
    await tester.pumpAndSettle();
    // The picker opens on a likely date inside the airline's bounds; take it.
    if (find.text('OK').evaluate().isEmpty) {
      // A birthday opens on the years first: choose the highlighted one.
      await tester.tap(find.byType(TextButton).last);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  Future<void> fillLead(WidgetTester tester) async {
    await enter(tester, 'First name *', 'Juan');
    await enter(tester, 'Last name *', 'Dela Cruz');
    await enter(tester, 'Email *', 'juan@example.com');
    await enter(tester, 'Passport number *', 'P1234567A');
    await tester.enterText(find.byType(TextField).at(3), '9123456789'); // the phone number beside its dial code
    await pickDate(tester, 'Date of birth');
    await pickDate(tester, 'Passport expiry');

    await tester.ensureVisible(find.text('Select gender'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select gender'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Male').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Select country'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select country'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Philippines (PH)'));
    await tester.pumpAndSettle();
  }

  testWidgets('three steps, the first being who is flying; the fare is the server\'s quote', (tester) async {
    await pump(tester);

    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Payment'), findsOneWidget);
    expect(find.text('Verification'), findsOneWidget);
    expect(find.text('Complete your booking'), findsOneWidget);
    expect(find.text("Who's flying?"), findsOneWidget);
    expect(find.text('ADULT 1'), findsOneWidget);
    expect(find.text('MNL → SIN'), findsOneWidget);
    expect(find.text('PHP 8,108.79'), findsOneWidget);

    // The folded summary opens to the itinerary and the fare breakdown.
    await tester.tap(find.text('MNL → SIN'));
    await tester.pumpAndSettle();
    expect(find.text('Fare · 1 passenger'), findsOneWidget);
    expect(find.text('Ninoy Aquino International Airport (MNL)'), findsOneWidget);
  });

  testWidgets('nothing is sent until every field V2 requires is filled', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Continue to payment'));
    await tester.pumpAndSettle();

    expect(find.text('Required'), findsWidgets);
    expect(find.text('2-letter country code'), findsOneWidget);
    expect(api.books, isEmpty);
  });

  testWidgets('a traveller who is not signed in is sent to sign in, not booked', (tester) async {
    signedIn = false;
    await pump(tester);
    expect(find.text('Sign in to complete your booking'), findsOneWidget);

    await fillLead(tester);
    await tester.tap(find.text('Continue to payment'));
    await tester.pumpAndSettle();

    expect(signInAsked, 1);
    expect(api.books, isEmpty);
  });

  Future<void> toPayment(WidgetTester tester) async {
    await pump(tester);
    await fillLead(tester);
    await tester.tap(find.text('Continue to payment'));
    await tester.pumpAndSettle();
  }

  testWidgets("details → /flights/book → Stripe's sheet → /flights/confirm → the PNR", (tester) async {
    await toPayment(tester);

    final booked = api.books.single;
    expect(booked['offerId'], 'off_duffel');
    expect(booked['displayCurrency'], 'PHP');
    expect(booked['phoneCode'], '+63');
    final pax = (booked['passengers'] as List).single as Map;
    expect(pax['firstName'], 'Juan');
    expect(pax['email'], 'juan@example.com');
    expect(pax['nationality'], 'PH');
    expect(pax['gender'], 'M');
    expect(pax['type'], 'ADT');

    // The card is typed into Stripe's own sheet: there is no card field in the app.
    expect(find.text('Payment Details'), findsOneWidget);
    expect(find.text('Card number *'), findsNothing);
    expect(gateway.presented, isFalse);

    await tester.tap(find.text('Pay PHP 8,108.79'));
    await tester.pumpAndSettle();

    expect(gateway.presented, isTrue);
    expect(api.confirms.single, {'paymentIntentId': 'pi_1', 'sessionId': 'sess_1'});
    expect(find.text('You’re all set'), findsOneWidget);
    expect(find.text('QZX7PA'), findsOneWidget);
    expect(find.text('PHP 8,108.79'), findsOneWidget);

    // Paid: back leaves for the trips, never to a payment form that could charge again.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('trips page'), findsOneWidget);
  });

  testWidgets("closing Stripe's sheet is not a failure: nothing is confirmed, the page stays", (tester) async {
    gateway = FakePaymentGateway(cancel: true);
    await toPayment(tester);
    await tester.tap(find.text('Pay PHP 8,108.79'));
    await tester.pumpAndSettle();

    expect(api.confirms, isEmpty);
    expect(find.text('Payment Details'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    // Android's back gesture — the one Platform Obligation — does what the page's own back does
    // from payment: returns to the details, not out of checkout.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Complete your booking'), findsOneWidget);
  });

  testWidgets("a declined card says so, in Stripe's words, and asks the airline nothing", (tester) async {
    gateway = FakePaymentGateway(declineWith: 'Your card was declined.');
    await toPayment(tester);
    await tester.tap(find.text('Pay PHP 8,108.79'));
    await tester.pumpAndSettle();

    expect(find.text("Your payment didn't go through"), findsOneWidget);
    expect(find.text('Your card was declined.'), findsOneWidget);
    expect(api.confirms, isEmpty);
  });

  testWidgets('an airline still deciding is an outcome, never "try again"', (tester) async {
    api.confirmError = ApiError('processing', code: 'BOOKING_PROCESSING', status: 409, body: {'needsReview': false});
    await toPayment(tester);
    await tester.tap(find.text('Pay PHP 8,108.79'));
    await tester.pumpAndSettle();

    expect(find.text('Confirming your booking'), findsOneWidget);
    expect(find.text("Please don't pay again — you won't be charged twice."), findsOneWidget);
    expect(find.textContaining('Pay PHP'), findsNothing);
  });

  testWidgets('a fare that rose before the airline confirmed releases the hold and says by how much', (tester) async {
    api.confirmError = ApiError(
      'changed',
      code: 'PRICE_CHANGED',
      status: 409,
      body: {'oldPrice': 8108.79, 'newPrice': 9020.5, 'currency': 'PHP'},
    );
    await toPayment(tester);
    await tester.tap(find.text('Pay PHP 8,108.79'));
    await tester.pumpAndSettle();

    expect(find.text('The fare changed'), findsOneWidget);
    expect(find.textContaining('PHP 9,020.50'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Complete your booking'), findsOneWidget);
  });

  testWidgets('a fare the airline stopped selling sends the traveller back to a fresh search', (tester) async {
    api.bookError = ApiError('This fare is no longer available.', code: 'OFFER_EXPIRED', status: 410);
    await pump(tester);
    await fillLead(tester);
    await tester.tap(find.text('Continue to payment'));
    await tester.pumpAndSettle();

    expect(find.text('search page'), findsOneWidget);
    final q = Uri.parse(went.single).queryParameters;
    expect(q['origin'], 'Manila (MNL)');
    expect(q['fareGone'], '1');
  });

  testWidgets('the same-day warning is a dialog naming the clash', (tester) async {
    api.bookError = ApiError(
      'dup',
      code: 'DUPLICATE_BOOKING',
      status: 409,
      body: {'route': 'MNL → SIN', 'departureDate': '2026-12-03'},
    );
    await pump(tester);
    await fillLead(tester);
    await tester.tap(find.text('Continue to payment'));
    await tester.pumpAndSettle();

    expect(find.text('You already have a flight that day'), findsOneWidget);
    expect(find.text('Your booking departing MNL → SIN on 2026-12-03 is still active.'), findsOneWidget);
  });

  testWidgets('opened on an offer that has already gone, it goes straight back to the search', (tester) async {
    api.offerGone = true;
    await pump(tester);
    expect(find.text('search page'), findsOneWidget);
    expect(Uri.parse(went.single).queryParameters['fareGone'], '1');
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/features/hotels/views/hotel_checkout_view.dart';
import 'package:cheapest_go_mobile/features/flights/views/flight_checkout_view.dart';
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

  Widget wrap(Widget child) => MaterialApp(
        theme: AppTheme.light,
        home: child,
      );

  group('HotelCheckoutView (Mock rate lock & price shift)', () {
    testWidgets('renders rate hold countdown timer', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(
        wrap(
          const HotelCheckoutView(
            hotelId: 'mnl-t3-garden',
            roomId: 'king',
            initialHoldSeconds: 900,
            autoStartTimer: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Rate locked for 15:00'), findsOneWidget);
      expect(find.textContaining('Price and room guaranteed'), findsOneWidget);
      expect(find.text('Review and pay'), findsOneWidget);
    });

    testWidgets('rate hold counts down when timer is active', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(
        wrap(
          const HotelCheckoutView(
            hotelId: 'mnl-t3-garden',
            roomId: 'king',
            initialHoldSeconds: 900,
            autoStartTimer: true,
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Rate locked for 15:00'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      expect(find.textContaining('Rate locked for 14:58'), findsOneWidget);
    });

    testWidgets('expired rate hold displays warning and allows refresh', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(
        wrap(
          const HotelCheckoutView(
            hotelId: 'mnl-t3-garden',
            roomId: 'king',
            initialHoldSeconds: 0,
            autoStartTimer: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Rate hold expired'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);

      await tester.tap(find.text('Refresh'));
      await tester.pump();

      expect(find.textContaining('Rate locked for 15:00'), findsOneWidget);
    });

    testWidgets('displays room cancellation policy and instant confirmation', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(
        wrap(
          const HotelCheckoutView(
            hotelId: 'mnl-t3-garden',
            roomId: 'king',
            autoStartTimer: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Free cancellation'), findsOneWidget);
    });

    testWidgets('fill demo guest button pre-populates name and email', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(
        wrap(
          const HotelCheckoutView(
            hotelId: 'mnl-t3-garden',
            roomId: 'king',
            autoStartTimer: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Fill demo'), findsOneWidget);
      await tester.tap(find.text('Fill demo'));
      await tester.pump();

      expect(find.text('Juan Dela Cruz'), findsOneWidget);
      expect(find.text('juan.delacruz@cheapestgo.dev'), findsOneWidget);
    });

    testWidgets('simulated price shift triggers warning banner and acceptance flow', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(
        wrap(
          const HotelCheckoutView(
            hotelId: 'mnl-t3-garden',
            roomId: 'king',
            simulatedPriceShift: 350,
            autoStartTimer: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Rate updated by supplier'), findsOneWidget);
      expect(find.textContaining('+₱350'), findsOneWidget);
      expect(find.text('Accept new rate'), findsOneWidget);
      expect(find.textContaining('Review updated rate'), findsOneWidget);

      await tester.tap(find.text('Accept new rate'));
      await tester.pump();

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();

      expect(find.text('Supplier adjustment'), findsOneWidget);
      expect(find.textContaining('+₱350'), findsWidgets);
      expect(find.textContaining('Pay ₱'), findsOneWidget);
    });

    testWidgets('completes booking and records stay to bookingsStore', (tester) async {
      final before = bookingsStore.all.length;
      await pumpApp(tester, location: '/checkout?hotel=mnl-t3-garden&room=king');

      expect(find.text('Review and pay'), findsOneWidget);
      await tester.tap(find.text('Fill demo'));
      await tester.pump();

      await tester.tap(find.textContaining('Pay ₱'));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(bookingsStore.all.length, before + 1);
      final booking = bookingsStore.all.last;
      expect(booking.kind, BookingKind.stay);
      expect(booking.title, 'Terminal 3 Garden Hotel');
      expect(booking.detail, contains('Deluxe King'));
      expect(find.text('Trips'), findsWidgets);
    });
  });

  group('FlightCheckoutView (Mock fare revalidation & baggage rules)', () {
    testWidgets('renders fare hold timer and revalidation status badge', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(
        wrap(
          const FlightCheckoutView(
            offerId: 'SIN-MNL-0',
            initialHoldSeconds: 900,
            autoStartTimer: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Fare locked for 15:00'), findsOneWidget);
      expect(find.text('Fare verified · Price guaranteed'), findsOneWidget);
      expect(find.textContaining('Baggage: 7 kg carry-on'), findsOneWidget);
      expect(find.textContaining('Policy: Non-refundable'), findsOneWidget);
    });

    testWidgets('fill demo passenger pre-populates fields', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(
        wrap(
          const FlightCheckoutView(
            offerId: 'SIN-MNL-0',
            autoStartTimer: false,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Fill demo'));
      await tester.pump();

      expect(find.text('Juan Dela Cruz'), findsOneWidget);
      expect(find.text('juan.delacruz@cheapestgo.dev'), findsOneWidget);
    });

    testWidgets('flight price shift prompts for acceptance', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(
        wrap(
          const FlightCheckoutView(
            offerId: 'SIN-MNL-0',
            simulatedPriceShift: 250,
            autoStartTimer: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Fare updated by carrier'), findsOneWidget);
      expect(find.textContaining('+₱250'), findsOneWidget);

      await tester.tap(find.text('Accept new fare'));
      await tester.pump();

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();

      expect(find.text('Supplier adjustment'), findsOneWidget);
    });

    testWidgets('completes flight booking and records to bookingsStore', (tester) async {
      final before = bookingsStore.all.length;
      await pumpApp(tester, location: '/flight-checkout?offer=SIN-MNL-0');

      expect(find.text('Review and pay'), findsOneWidget);
      await tester.tap(find.text('Fill demo'));
      await tester.pump();

      await tester.tap(find.textContaining('Pay ₱'));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(bookingsStore.all.length, before + 1);
      final booking = bookingsStore.all.last;
      expect(booking.kind, BookingKind.flight);
      expect(booking.title, contains('BY'));
      expect(find.text('Trips'), findsWidgets);
    });
  });
}

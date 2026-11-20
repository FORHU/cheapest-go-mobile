import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/features/hotels/api/checkout_api.dart';
import 'package:cheapest_go_mobile/features/hotels/lib/booking_status.dart';
import 'package:cheapest_go_mobile/features/hotels/views/booking_status_view.dart';
import 'package:cheapest_go_mobile/features/trips/api/bookings_source.dart';
import 'package:cheapest_go_mobile/features/trips/models/trip_booking.dart';
import 'package:cheapest_go_mobile/features/trips/views/booking_detail_view.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/errors/api_error.dart';

/// The booking confirmation screen (#50): V2's `/booking/[reference]`, at phone width.
///
/// What matters most is what it says about money: a booking still settling is never offered a
/// second payment, and "you have not been charged" appears only when the server said so.
final _t = lookupAppLocalizations(const Locale('en'));

const _confirmed = ConfirmOutcome(state: ConfirmState.confirmed, reference: 'CG-ABC123', status: 'confirmed');
const _pending = ConfirmOutcome(state: ConfirmState.pending, reference: 'CG-ABC123', message: 'm');
const _review = ConfirmOutcome(state: ConfirmState.needsReview, reference: 'CG-ABC123', message: 'm');

/// Answers in turn, repeating the last; an [Exception] in the list is thrown instead.
class _Server {
    _Server(this.answers);

    final List<Object> answers;
    final asked = <String>[];

    Future<ConfirmOutcome> call(String reference) async {
        asked.add(reference);
        final answer = answers[(asked.length - 1).clamp(0, answers.length - 1)];
        if (answer is Exception) throw answer;
        return answer as ConfirmOutcome;
    }
}

final _notFound = ApiError('Booking not found', status: 404, code: 'BOOKING_NOT_FOUND');
final _down = ApiError('Bad gateway', status: 502);

void _smallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
}

/// The screen inside a router, so its links can be followed and seen to land.
Future<GoRouter> _pump(WidgetTester tester, _Server server, {ThemeData? theme, String reference = 'CG-ABC123'}) async {
    _smallPhone(tester);
    final router = GoRouter(
        initialLocation: '/booking/$reference',
        routes: [
            GoRoute(path: '/', builder: (_, _) => const Text('home')),
            GoRoute(path: '/trips', builder: (_, _) => const Text('trips')),
            GoRoute(
                path: '/booking/:reference',
                builder: (_, state) => BookingStatusView(
                    reference: state.pathParameters['reference']!,
                    fetch: server.call,
                    pollInterval: const Duration(seconds: 3),
                ),
            ),
        ],
    );
    await tester.pumpWidget(MaterialApp.router(
        theme: theme ?? AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        routerConfig: router,
    ));
    await tester.pump();
    return router;
}

/// Disposes [poller] inside the test body, then lets time pass to show nothing more is asked.
///
/// Inside the body because `testWidgets` checks for pending timers before any `addTearDown`
/// runs, so a poller still waiting to ask again fails the test however it is torn down after.
Future<void> _disposeAndCheck(WidgetTester tester, BookingStatusPoller poller, _Server server) async {
    final asked = server.asked.length;
    poller.dispose();
    await tester.pump(const Duration(minutes: 5));
    expect(server.asked, hasLength(asked), reason: 'a disposed poller asked again');
}

void main() {
    group('ConfirmOutcome.fromStatus — V2 outcomeFromStatus', () {
        ConfirmOutcome read(String? status, {String? bookingStatus, Map<String, dynamic>? failure}) =>
            ConfirmOutcome.fromStatus({
                'reference': 'CG-ABC123',
                'status': status,
                'bookingStatus': bookingStatus,
                'failure': failure,
            });

        test('a booking made, and since cancelled or refunded, is still a booking made', () {
            for (final s in ['CONFIRMED', 'CANCEL_REQUESTED', 'CANCELLED', 'REFUND_PENDING', 'REFUNDED', 'REFUND_FAILED']) {
                final o = read(s, bookingStatus: 'confirmed');
                expect(o.state, ConfirmState.confirmed, reason: s);
                expect(o.reference, 'CG-ABC123');
            }
        });

        test('failed and expired say the hold was released, with the server message', () {
            final o = read('FAILED', failure: {'code': 'X', 'message': 'Room is gone'});
            expect(o.state, ConfirmState.failed);
            expect(o.released, isTrue);
            expect(o.message, 'Room is gone');
            expect(read('EXPIRED').released, isTrue);
        });

        test('needs review is its own state', () {
            expect(read('NEEDS_REVIEW').state, ConfirmState.needsReview);
        });

        test('before the lifecycle, the sale status decides', () {
            expect(read(null, bookingStatus: 'confirmed').state, ConfirmState.confirmed);
            expect(read(null, bookingStatus: 'pending').state, ConfirmState.pending);
        });

        test('anything still moving is pending', () {
            for (final s in ['PAYMENT_PENDING', 'PAYMENT_AUTHORIZED', 'SUPPLIER_BOOKING']) {
                expect(read(s).state, ConfirmState.pending, reason: s);
            }
        });
    });

    group('BookingStatusPoller — V2 useBookingStatus', () {
        testWidgets('keeps asking until the booking settles, then stops', (tester) async {
            final server = _Server([_pending, _pending, _confirmed]);
            final poller = BookingStatusPoller(reference: 'CG-ABC123', fetch: server.call)..start();
            addTearDown(poller.dispose); // a backstop if the body throws; see _disposeAndCheck

            await tester.pump();
            expect(poller.load, BookingLoad.ready);
            expect(poller.outcome!.state, ConfirmState.pending);

            await tester.pump(const Duration(seconds: 3));
            await tester.pump(const Duration(seconds: 3));
            expect(poller.outcome!.state, ConfirmState.confirmed);

            await tester.pump(const Duration(seconds: 30));
            expect(server.asked, hasLength(3));
            await _disposeAndCheck(tester, poller, server);
        });

        testWidgets('gives up after its budget and says so; refresh starts a fresh one', (tester) async {
            final server = _Server([_review]);
            final poller = BookingStatusPoller(reference: 'CG-ABC123', fetch: server.call, maxPolls: 3)..start();
            addTearDown(poller.dispose); // a backstop if the body throws; see _disposeAndCheck

            await tester.pump();
            await tester.pump(const Duration(seconds: 3));
            await tester.pump(const Duration(seconds: 3));
            expect(poller.exhausted, isTrue);
            await tester.pump(const Duration(seconds: 30));
            expect(server.asked, hasLength(3));

            await poller.refresh();
            await tester.pump();
            expect(poller.exhausted, isFalse);
            expect(server.asked, hasLength(4));
            await _disposeAndCheck(tester, poller, server);
        });

        testWidgets('a 404 is "not found", and is not asked again', (tester) async {
            final server = _Server([_notFound]);
            final poller = BookingStatusPoller(reference: 'CG-ABC123', fetch: server.call)..start();
            addTearDown(poller.dispose); // a backstop if the body throws; see _disposeAndCheck

            await tester.pump();
            await tester.pump(const Duration(seconds: 30));
            expect(poller.load, BookingLoad.notFound);
            expect(server.asked, hasLength(1));
            await _disposeAndCheck(tester, poller, server);
        });

        testWidgets('a first answer that fails is an error, and waits for refresh', (tester) async {
            final server = _Server([_down]);
            final poller = BookingStatusPoller(reference: 'CG-ABC123', fetch: server.call)..start();
            addTearDown(poller.dispose); // a backstop if the body throws; see _disposeAndCheck

            await tester.pump();
            await tester.pump(const Duration(seconds: 30));
            expect(poller.load, BookingLoad.error);
            expect(server.asked, hasLength(1));
            await _disposeAndCheck(tester, poller, server);
        });

        testWidgets('a later failure keeps what is already shown', (tester) async {
            final server = _Server([_pending, _down]);
            final poller = BookingStatusPoller(reference: 'CG-ABC123', fetch: server.call)..start();
            addTearDown(poller.dispose); // a backstop if the body throws; see _disposeAndCheck

            await tester.pump();
            await tester.pump(const Duration(seconds: 3));
            expect(poller.load, BookingLoad.ready);
            expect(poller.outcome!.state, ConfirmState.pending);
            await _disposeAndCheck(tester, poller, server);
        });

        test('no reference is not found, and nothing is asked', () {
            final server = _Server([_confirmed]);
            final poller = BookingStatusPoller(reference: '', fetch: server.call)..start();
            expect(poller.load, BookingLoad.notFound);
            expect(server.asked, isEmpty);
            poller.dispose();
        });
    });

    group('BookingStatusView', () {
        testWidgets('asks about the reference in the address, and no other', (tester) async {
            final server = _Server([_confirmed]);
            await _pump(tester, server, reference: 'CG-XYZ999');
            expect(server.asked, ['CG-XYZ999']);
        });

        testWidgets('says it is checking while the first answer is out', (tester) async {
            _smallPhone(tester);
            await tester.pumpWidget(MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: const Locale('en'),
                home: BookingStatusView(
                    reference: 'CG-ABC123',
                    fetch: (_) => Future.delayed(const Duration(seconds: 1), () => _confirmed),
                ),
            ));
            expect(find.text(_t.checkout_bookingPage_loading), findsOneWidget);
            await tester.pump(const Duration(seconds: 1));
            expect(find.text(_t.checkout_booked), findsOneWidget);
        });

        testWidgets('shows a confirmed booking with its reference and a way to trips', (tester) async {
            await _pump(tester, _Server([_confirmed]));

            expect(find.text(_t.checkout_booked), findsOneWidget);
            expect(find.text(_t.checkout_success_hotelSuccess), findsOneWidget);
            expect(find.textContaining('CG-ABC123', findRichText: true), findsOneWidget);
            expect(tester.takeException(), isNull);

            await tester.tap(find.text(_t.checkout_success_viewMyTrips));
            await tester.pumpAndSettle();
            expect(find.text('trips'), findsOneWidget);
        });

        testWidgets('a booking in progress says so, never asks for payment, and turns into booked', (tester) async {
            await _pump(tester, _Server([_pending, _confirmed]));

            expect(find.text(_t.checkout_settling_title), findsOneWidget);
            expect(find.text(_t.checkout_settling_doNotPayAgain), findsOneWidget);
            expect(find.text(_t.checkout_bookingPage_stillWorking), findsOneWidget);
            expect(find.textContaining('CG-ABC123', findRichText: true), findsOneWidget);
            expect(tester.takeException(), isNull);

            await tester.pump(const Duration(seconds: 3));
            expect(find.text(_t.checkout_booked), findsOneWidget);
            expect(find.text(_t.checkout_settling_title), findsNothing);
        });

        testWidgets('needs review uses its own words, and offers refresh once polling gives up', (tester) async {
            final server = _Server([_review]);
            await _pump(tester, server);
            expect(find.text(_t.checkout_needsReview_title), findsOneWidget);
            expect(find.text(_t.checkout_needsReview_description), findsOneWidget);
            expect(find.text(_t.checkout_bookingPage_refresh), findsNothing);

            for (var i = 0; i < 40; i++) {
                await tester.pump(const Duration(seconds: 3));
            }
            expect(find.text(_t.checkout_bookingPage_stillWorking), findsNothing);
            final asked = server.asked.length;
            await tester.tap(find.text(_t.checkout_bookingPage_refresh));
            await tester.pump();
            expect(server.asked.length, asked + 1);
        });

        testWidgets('says "not charged" only when the hold was released', (tester) async {
            await _pump(tester, _Server([
                const ConfirmOutcome(state: ConfirmState.failed, message: 'Room is gone', released: true),
            ]));
            expect(find.text(_t.checkout_failed_title), findsOneWidget);
            expect(find.text('Room is gone'), findsOneWidget);
            expect(find.text(_t.checkout_failed_released), findsOneWidget);
            expect(find.text(_t.checkout_failed_unknown), findsNothing);
            expect(tester.takeException(), isNull);

            await tester.tap(find.text(_t.checkout_failed_tryAgain));
            await tester.pumpAndSettle();
            expect(find.text('home'), findsOneWidget);
        });

        testWidgets('a failure the server did not vouch for says it does not know', (tester) async {
            await _pump(tester, _Server([
                const ConfirmOutcome(state: ConfirmState.failed, message: 'Something went wrong'),
            ]));
            expect(find.text(_t.checkout_failed_unknown), findsOneWidget);
            expect(find.text(_t.checkout_failed_released), findsNothing);
        });

        testWidgets('says a booking is not found', (tester) async {
            await _pump(tester, _Server([_notFound]));
            expect(find.text(_t.checkout_bookingPage_notFound), findsOneWidget);
            expect(find.text(_t.checkout_bookingPage_notFoundDescription), findsOneWidget);
        });

        testWidgets('lets a failed load be tried again', (tester) async {
            final server = _Server([_down, _confirmed]);
            await _pump(tester, server);
            expect(find.text(_t.checkout_supplierDown_description), findsOneWidget);

            await tester.tap(find.text(_t.checkout_bookingPage_refresh));
            await tester.pump();
            expect(find.text(_t.checkout_booked), findsOneWidget);
        });

        testWidgets('lays out at 360px in the dark theme too', (tester) async {
            await _pump(tester, _Server([_review]), theme: AppTheme.dark);
            expect(tester.takeException(), isNull);
            for (var i = 0; i < 40; i++) {
                await tester.pump(const Duration(seconds: 3));
            }
            expect(tester.takeException(), isNull);
        });
    });

    group('Reached from a trip', () {
        late BookingsSource saved;
        setUp(() => saved = bookingsSource);
        tearDown(() => bookingsSource = saved);

        Future<void> open(WidgetTester tester, TripBooking booking) async {
            _smallPhone(tester);
            bookingsSource = _Source([booking]);
            final router = GoRouter(
                initialLocation: '/trips/${booking.id}',
                routes: [
                    GoRoute(path: '/trips/:id', builder: (_, state) => BookingDetailView(bookingId: state.pathParameters['id']!)),
                    GoRoute(path: '/booking/:reference', builder: (_, state) => Text('status ${state.pathParameters['reference']}')),
                ],
            );
            await tester.pumpWidget(MaterialApp.router(
                theme: AppTheme.light,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: const Locale('en'),
                routerConfig: router,
            ));
            await tester.pumpAndSettle();
        }

        testWidgets('a stay links to its confirmation screen by its reference', (tester) async {
            await open(tester, _stay());
            await tester.tap(find.text(_t.mobile_trips_bookingStatus));
            await tester.pumpAndSettle();
            expect(find.text('status TGX-998877'), findsOneWidget);
        });

        testWidgets('a flight does not — the status screen is the hotel one', (tester) async {
            await open(tester, _flight());
            expect(find.text(_t.mobile_trips_bookingStatus), findsNothing);
        });
    });
}

class _Source implements BookingsSource {
    _Source(this.bookings);
    final List<TripBooking> bookings;

    @override
    Future<BookingsPage> myBookings() async => BookingsPage(bookings: bookings);
}

HotelStayBooking _stay() => HotelStayBooking(
    id: 'h1a2b3c4-0000-4000-8000-000000000002',
    reference: 'TGX-998877',
    bookingReference: 'CG-HT5678',
    status: 'pending',
    propertyName: 'Lotte Hotel World Seoul',
    roomName: 'Deluxe Twin',
    checkIn: DateTime(2026, 12, 1),
    checkOut: DateTime(2026, 12, 4),
    adults: 2,
    children: 0,
    holderFirstName: 'Maria',
    holderLastName: 'Santos',
    holderEmail: 'maria@example.com',
    totalPaid: 18450.5,
    currency: 'PHP',
    searchText: '',
    bookedAt: DateTime.utc(2026, 11, 10),
);

FlightTripBooking _flight() => FlightTripBooking(
    id: 'f1a2b3c4-0000-4000-8000-000000000001',
    reference: 'CG-FL1234',
    pnr: '3XXNT3',
    status: 'confirmed',
    totalPaid: 5120,
    currency: 'PHP',
    searchText: '',
    tripType: 'one-way',
    passengers: const [],
    bookedAt: DateTime.utc(2026, 11, 18, 5, 22),
    segments: [
        FlightSegment(
            airline: '7C',
            flightNumber: '7C2104',
            origin: 'MNL',
            destination: 'ICN',
            departure: DateTime.utc(2026, 12, 1, 1),
            arrival: DateTime.utc(2026, 12, 1, 5),
        ),
    ],
);

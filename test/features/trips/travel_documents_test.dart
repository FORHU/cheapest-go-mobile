import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/features/trips/api/bookings_source.dart';
import 'package:cheapest_go_mobile/features/trips/components/document_actions.dart';
import 'package:cheapest_go_mobile/features/trips/lib/travel_documents.dart';
import 'package:cheapest_go_mobile/features/trips/models/trip_booking.dart';
import 'package:cheapest_go_mobile/features/trips/views/booking_detail_view.dart';
import 'package:cheapest_go_mobile/features/trips/views/invoice_view.dart';
import 'package:cheapest_go_mobile/features/trips/views/travel_document_view.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';

/// The trip documents and the invoice (#49): V2's `/trips/document/[id]` and
/// `/trips/invoice/[id]`, at phone width.
///
/// The rules that matter at a check-in desk are the ones tested hardest: a ticket number is
/// never printed before the airline issues one, and a document the booking has not earned is
/// replaced by the reason it is not there yet.
class _Source implements BookingsSource {
    _Source(this.bookings);
    final List<TripBooking> bookings;

    @override
    Future<BookingsPage> myBookings() async => BookingsPage(bookings: bookings);
}

final _t = lookupAppLocalizations(const Locale('en'));

FlightTripBooking _flight({bool ticketed = false, String status = 'confirmed'}) => FlightTripBooking(
    id: 'f1a2b3c4-0000-4000-8000-000000000001',
    reference: 'CG-FL1234',
    bookingReference: 'CG-FL1234',
    pnr: '3XXNT3',
    status: ticketed ? 'ticketed' : status,
    totalPaid: 5120,
    chargedPrice: 5120,
    currency: 'PHP',
    searchText: '',
    tripType: 'round-trip',
    ticketedAt: ticketed ? DateTime.utc(2026, 11, 18, 6) : null,
    bookedAt: DateTime.utc(2026, 11, 18, 5, 22),
    farePolicy: const FarePolicy(isRefundable: true, isChangeable: false, refundPenaltyAmount: 1500),
    segments: [
        FlightSegment(
            airline: '7C',
            flightNumber: '7C2104',
            origin: 'MNL',
            destination: 'ICN',
            departure: DateTime.utc(2026, 12, 1, 1),
            arrival: DateTime.utc(2026, 12, 1, 5),
            cabinClass: 'premium_economy',
            originTerminal: '3',
        ),
        FlightSegment(
            airline: '7C',
            flightNumber: '2105',
            origin: 'ICN',
            destination: 'MNL',
            departure: DateTime.utc(2026, 12, 8, 7),
            arrival: DateTime.utc(2026, 12, 8, 11),
            itineraryIndex: 1,
            segmentIndex: 1,
        ),
    ],
    passengers: [
        FlightPassenger(
            firstName: 'Juan',
            lastName: 'Dela Cruz',
            ticketNumber: ticketed ? '0012345678901' : null,
        ),
    ],
);

HotelStayBooking _hotel({String status = 'confirmed'}) => HotelStayBooking(
    id: 'h1a2b3c4-0000-4000-8000-000000000002',
    reference: 'TGX-998877',
    bookingReference: 'CG-HT5678',
    status: status,
    propertyName: 'Lotte Hotel World Seoul, a very long property name to wrap on a phone',
    roomName: 'Deluxe Twin, City View',
    checkIn: DateTime(2026, 12, 1),
    checkOut: DateTime(2026, 12, 4),
    adults: 2,
    children: 1,
    holderFirstName: 'Maria',
    holderLastName: 'Santos',
    holderEmail: 'maria@example.com',
    specialRequests: 'High floor, away from the lift',
    supplierReference: 'LTW-4411-22',
    board: 'Breakfast included',
    totalPaid: 18450.5,
    currency: 'PHP',
    searchText: '',
    bookedAt: DateTime.utc(2026, 11, 10),
);

/// A small phone: what "renders legibly at phone width" is held to.
void _smallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
}

Future<void> _pump(WidgetTester tester, Widget screen, {ThemeData? theme}) async {
    _smallPhone(tester);
    await tester.pumpWidget(MaterialApp(
        theme: theme ?? AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: screen,
    ));
    await tester.pumpAndSettle();
}

/// Scrolls the whole document past, so every part of it is built and laid out once.
Future<void> _scrollThrough(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
    }
}

void main() {
    group('how the documents print things', () {
        test('ticket numbers are split as airlines print them', () {
            expect(formatTicketNumber('0012345678901'), '001 2345678901');
            expect(formatTicketNumber('001 2345678901'), '001 2345678901');
            expect(formatTicketNumber('ABC'), 'ABC');
        });

        test('names read surname first, as a check-in desk reads them', () {
            expect(formatTravellerName('Juan', 'Dela Cruz'), 'DELA CRUZ/JUAN');
            expect(formatTravellerName(null, null), '—');
        });

        test('flight numbers come out the same whichever way the supplier sent them', () {
            expect(formatFlightNumber('7C', '7C2104'), '7C 2104');
            expect(formatFlightNumber('7C', '2104'), '7C 2104');
            expect(formatFlightNumber(null, null), '—');
        });

        test('cabins and file names', () {
            expect(formatCabin('premium_economy'), 'Premium economy');
            expect(formatCabin(''), '—');
            expect(pdfFilename('Receipt', 'CG-FL1234'), 'Receipt_CG-FL1234.pdf');
            expect(pdfFilename('E-Ticket', 'a/b c'), 'E-Ticket_abc.pdf');
            expect(pdfFilename('Voucher', null), 'Voucher_booking.pdf');
        });
    });

    group('the receipt', () {
        testWidgets('prints no ticket number before the airline issues one', (tester) async {
            bookingsSource = _Source([_flight()]);
            await _pump(tester, TravelDocumentView(bookingId: _flight().id, kind: 'receipt'));

            expect(find.text(_t.documents_receipt_titleItinerary), findsOneWidget);
            expect(find.text(_t.documents_receipt_ticketPending), findsOneWidget);
            expect(find.textContaining('2345678901'), findsNothing);
            await _scrollThrough(tester);
            expect(find.text(_t.documents_receipt_pending), findsOneWidget);
        });

        testWidgets('prints the ticket, names and flights the airline way once issued', (tester) async {
            bookingsSource = _Source([_flight(ticketed: true)]);
            await _pump(tester, TravelDocumentView(bookingId: _flight().id, kind: 'receipt'));
            await _scrollThrough(tester);

            expect(find.text('001 2345678901'), findsOneWidget);
            expect(find.text('DELA CRUZ/JUAN'), findsWidgets);
            expect(find.text('7C 2104'), findsOneWidget);
            expect(find.text('7C 2105'), findsOneWidget);
            // Two directions, so the legs are headed Outbound and Return.
            expect(find.text(_t.documents_receipt_outbound), findsOneWidget);
            expect(find.text(_t.documents_receipt_return), findsOneWidget);
        });

        testWidgets('a stay\'s receipt fits a small phone, in the dark too', (tester) async {
            bookingsSource = _Source([_hotel()]);
            await _pump(
                tester,
                TravelDocumentView(bookingId: _hotel().id, kind: 'receipt'),
                theme: AppTheme.dark,
            );
            expect(find.text(_t.documents_receipt_title), findsOneWidget);
            await _scrollThrough(tester);
            expect(find.text('CG-HT5678'), findsOneWidget);
        });
    });

    group('documents the booking has not earned', () {
        testWidgets('an e-ticket asked for before issuance says what is awaited', (tester) async {
            bookingsSource = _Source([_flight()]);
            await _pump(tester, TravelDocumentView(bookingId: _flight().id, kind: 'eticket'));

            expect(find.text(_t.documents_eticket_title), findsNothing);
            expect(find.text(_t.documents_pending_awaitingTicket), findsOneWidget);
            expect(find.text(_t.trips_invoice_downloadPdf), findsNothing);
        });

        testWidgets('a voucher for a stay not yet confirmed says so', (tester) async {
            bookingsSource = _Source([_hotel(status: 'pending')]);
            await _pump(tester, TravelDocumentView(bookingId: _hotel().id, kind: 'voucher'));

            expect(find.text(_t.documents_voucher_title), findsNothing);
            expect(find.text(_t.documents_pending_awaitingConfirmation), findsOneWidget);
        });

        testWidgets('a booking that is not there is a state, not a crash', (tester) async {
            bookingsSource = _Source(const []);
            await _pump(tester, const TravelDocumentView(bookingId: 'nope', kind: 'receipt'));

            expect(tester.takeException(), isNull);
            expect(find.text(_t.trips_invoice_loadError), findsOneWidget);
        });
    });

    group('the e-ticket and the voucher', () {
        testWidgets('the e-ticket leads with the PNR and the issued ticket', (tester) async {
            bookingsSource = _Source([_flight(ticketed: true)]);
            await _pump(tester, TravelDocumentView(bookingId: _flight().id, kind: 'eticket'));

            expect(find.text(_t.documents_eticket_title), findsOneWidget);
            expect(find.text('0012345678901'), findsOneWidget);
            expect(find.text(_t.trips_invoice_print), findsOneWidget);
            expect(find.text(_t.trips_invoice_downloadPdf), findsOneWidget);
            await _scrollThrough(tester);
        });

        testWidgets('the voucher leads with the property\'s own reference', (tester) async {
            bookingsSource = _Source([_hotel()]);
            await _pump(tester, TravelDocumentView(bookingId: _hotel().id, kind: 'voucher'));

            expect(find.text(_t.documents_voucher_title), findsOneWidget);
            expect(find.text('LTW-4411-22'), findsWidgets);
            await _scrollThrough(tester);
            expect(find.text('Breakfast included'), findsOneWidget);
            expect(find.text('High floor, away from the lift'), findsOneWidget);
        });
    });

    testWidgets('the invoice renders at phone width', (tester) async {
        bookingsSource = _Source([_hotel()]);
        await _pump(tester, InvoiceView(bookingId: _hotel().id, type: 'hotel'));

        expect(tester.takeException(), isNull);
        expect(find.text(_t.invoice_receipt), findsOneWidget);
        expect(find.text('INV-H1A2B3C4'), findsOneWidget);
        await _scrollThrough(tester);
    });

    group('from the booking', () {
        testWidgets('a ticketed flight offers its e-ticket and receipt, nothing more', (tester) async {
            bookingsSource = _Source([_flight(ticketed: true)]);
            await _pump(tester, BookingDetailView(bookingId: _flight().id));
            await _scrollThrough(tester);

            expect(find.text(_t.documents_actions_eticket), findsOneWidget);
            expect(find.text(_t.documents_actions_receipt), findsOneWidget);
            expect(find.text(_t.documents_actions_voucher), findsNothing);
        });

        testWidgets('a flight awaiting its ticket offers the receipt and says why there is no e-ticket', (tester) async {
            bookingsSource = _Source([_flight()]);
            await _pump(tester, BookingDetailView(bookingId: _flight().id));
            await _scrollThrough(tester);

            expect(find.text(_t.documents_actions_eticket), findsNothing);
            expect(find.text(_t.documents_actions_receipt), findsOneWidget);
            expect(find.text(_t.documents_pending_awaitingTicket), findsOneWidget);
        });
    });

    testWidgets('Download makes a PDF of the document as drawn, light even in the dark theme', (tester) async {
        bookingsSource = _Source([_flight(ticketed: true)]);
        await _pump(
            tester,
            TravelDocumentView(bookingId: _flight().id, kind: 'receipt'),
            theme: AppTheme.dark,
        );

        final document = tester.state<PrintableDocumentState>(find.byType(PrintableDocument));
        final pdf = await tester.runAsync(() async {
            final made = document.toPdf();
            // The light frame it is painted from has to be drawn before it is read.
            await tester.pump();
            return made;
        });

        expect(pdf, isNotNull);
        expect(String.fromCharCodes(pdf!.take(5)), '%PDF-');
        // A tall document runs onto more than one A4 page rather than being squeezed onto one.
        expect(RegExp(r'/Type\s*/Page[^s]').allMatches(String.fromCharCodes(pdf)).length, greaterThan(1));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
    });
}

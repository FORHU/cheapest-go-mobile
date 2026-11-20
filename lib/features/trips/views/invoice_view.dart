/// A booking's invoice. V2's `/trips/invoice/[id]` (`invoice-view.tsx`).
///
/// Not linked from any screen — V2 does not link it either. It is where the hotel
/// confirmation email's "receipt" link lands, so it exists for whoever arrives by that route.
///
/// Download is the API's laid-out PDF, as on V2, not a picture of this screen: it is the file
/// someone attaches to an expense claim. Print sends what is on screen.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:cheapest_go_mobile/features/trips/api/bookings_source.dart';
import 'package:cheapest_go_mobile/features/trips/components/document_actions.dart';
import 'package:cheapest_go_mobile/features/trips/lib/travel_documents.dart';
import 'package:cheapest_go_mobile/features/trips/models/trip_booking.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/lib/env.dart';
import 'package:cheapest_go_mobile/shared/lib/http.dart';
import 'package:cheapest_go_mobile/shared/lib/receipt_url.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_palette.dart';
import 'package:cheapest_go_mobile/shared/utils/money.dart';

class InvoiceView extends StatefulWidget {
    const InvoiceView({required this.bookingId, this.type, this.customerEmail = '', super.key});

    final String bookingId;

    /// `hotel` or `flight`, as the link said. A hint for which receipt the API renders; the
    /// booking itself is found whichever it is.
    final String? type;

    /// The signed-in traveller's address — V2 bills a flight to the account's email.
    final String customerEmail;

    @override
    State<InvoiceView> createState() => _InvoiceViewState();
}

class _InvoiceViewState extends State<InvoiceView> {
    late final Future<TripBooking?> _load = findMyBooking(widget.bookingId);
    final _document = GlobalKey<PrintableDocumentState>();

    bool get _isHotel => (widget.type ?? 'hotel') == 'hotel';

    Future<Uint8List> _apiPdf() async {
        final uri = bookingReceiptUri(
            apiUrl: env.webApiUrl,
            bookingId: widget.bookingId,
            type: _isHotel ? ReceiptType.hotel : ReceiptType.flight,
        );
        final bytes = await HttpClientAdapter().getBytes(
            uri.toString(),
            options: const HttpRequestOptions(useMobileApiKey: true, requiresAuth: true),
        );
        return Uint8List.fromList(bytes);
    }

    @override
    Widget build(BuildContext context) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        final t = AppLocalizations.of(context)!;
        return Scaffold(
            // V2's own ground for this page: slate-100, slate-950 in the dark.
            backgroundColor: dark ? TwPalette.slate950 : TwPalette.slate100,
            body: SafeArea(
                child: FutureBuilder<TripBooking?>(
                    future: _load,
                    builder: (context, snapshot) {
                        final Widget body;
                        if (snapshot.connectionState == ConnectionState.waiting) {
                            body = const _InvoiceCard(height: 384);
                        } else if (snapshot.hasError || snapshot.data == null || snapshot.data is GolfTeeTimeBooking) {
                            body = _InvoiceCard(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                                child: Column(
                                    children: [
                                        Text(
                                            t.trips_invoice_loadError,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: dark ? Colors.white : TwPalette.slate800,
                                            ),
                                        ),
                                        if (snapshot.error != null) ...[
                                            const SizedBox(height: 12),
                                            Text(
                                                '${snapshot.error}',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(fontSize: 14, color: TwPalette.slate500),
                                            ),
                                        ],
                                    ],
                                ),
                            );
                        } else {
                            body = PrintableDocument(
                                key: _document,
                                child: _InvoiceReceipt(
                                    booking: snapshot.data!,
                                    isHotel: _isHotel,
                                    customerEmail: widget.customerEmail,
                                ),
                            );
                        }
                        return ListView(
                            padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
                            children: [
                                DocumentActions(
                                    filename: pdfFilename('Receipt', 'INV-${shortId(widget.bookingId)}'),
                                    makePdf: () => _document.currentState!.toPdf(),
                                    downloadPdf: _apiPdf,
                                ),
                                body,
                            ],
                        );
                    },
                ),
            ),
        );
    }
}

class _InvoiceCard extends StatelessWidget {
    const _InvoiceCard({this.height, this.padding, this.child});

    final double? height;
    final EdgeInsets? padding;
    final Widget? child;

    @override
    Widget build(BuildContext context) => Container(
        height: height,
        padding: padding,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? TwPalette.slate900 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
                BoxShadow(color: Color(0x1A000000), blurRadius: 15, offset: Offset(0, 10), spreadRadius: -3),
                BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 4), spreadRadius: -4),
            ],
        ),
        child: child,
    );
}

String _fmtDate(DateTime d) => DateFormat('MMM d, y', 'en_US').format(d.isUtc ? d.toLocal() : d);

class _InvoiceReceipt extends StatelessWidget {
    const _InvoiceReceipt({required this.booking, required this.isHotel, required this.customerEmail});

    final TripBooking booking;
    final bool isHotel;
    final String customerEmail;

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;
        final dark = Theme.of(context).brightness == Brightness.dark;
        final strong = dark ? Colors.white : TwPalette.slate800;
        final body = dark ? TwPalette.slate300 : TwPalette.slate600;
        final rule = dark ? TwPalette.slate800 : TwPalette.slate100;
        final hotel = booking is HotelStayBooking ? booking as HotelStayBooking : null;
        final flight = booking is FlightTripBooking ? booking as FlightTripBooking : null;
        final currency = booking.currency.isEmpty ? 'PHP' : booking.currency;
        final total = flight?.chargedPrice ?? booking.totalPaid;
        final bookedAt = booking.bookedAt;

        const caps = TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: TwPalette.slate400);
        const small = TextStyle(fontSize: 12, color: TwPalette.slate500);
        BoxDecoration ruled() => BoxDecoration(border: Border(bottom: BorderSide(color: rule)));

        Widget block({required Widget child, EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 20)}) =>
            Container(width: double.infinity, padding: padding, decoration: ruled(), child: child);

        Widget meta(String label, String value) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(label.toUpperCase(), style: caps),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 12, color: dark ? TwPalette.slate300 : TwPalette.slate700)),
            ],
        );

        final leadPassenger = flight == null || flight.passengers.isEmpty ? null : flight.passengers.first;
        final guests = hotel == null
            ? ''
            : [
                '${hotel.adults} adult${hotel.adults != 1 ? 's' : ''}',
                if (hotel.children > 0) '${hotel.children} child${hotel.children != 1 ? 'ren' : ''}',
            ].join(', ');

        return _InvoiceCard(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    // Header
                    block(
                        padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            const Text(
                                                brandName,
                                                style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: -0.6,
                                                    color: TwPalette.indigo600,
                                                ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(t.invoice_yourTravelPartner, style: const TextStyle(fontSize: 12, color: TwPalette.slate400)),
                                        ],
                                    ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                        Text(t.invoice_receipt, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: strong)),
                                        const SizedBox(height: 2),
                                        Text('INV-${shortId(booking.id)}', style: const TextStyle(fontSize: 12, color: TwPalette.slate400)),
                                        if (bookedAt != null)
                                            Text(
                                                t.invoice_issued(DateFormat('MMMM d, y', 'en_US').format(bookedAt)),
                                                style: const TextStyle(fontSize: 12, color: TwPalette.slate400),
                                            ),
                                    ],
                                ),
                            ],
                        ),
                    ),

                    // Billed to
                    block(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(t.invoice_billedTo.toUpperCase(), style: caps),
                                const SizedBox(height: 4),
                                Text(
                                    isHotel && hotel != null
                                        ? hotel.holderName
                                        : (leadPassenger?.name ?? ''),
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: strong),
                                ),
                                Text(isHotel && hotel != null ? hotel.holderEmail : customerEmail, style: small),
                            ],
                        ),
                    ),

                    // Booking details
                    block(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                                Text(t.invoice_bookingDetails.toUpperCase(), style: caps),
                                const SizedBox(height: 12),
                                if (isHotel && hotel != null) ...[
                                    Container(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        decoration: ruled(),
                                        child: Row(
                                            children: [
                                                Expanded(child: Text(t.invoice_description.toUpperCase(), style: caps)),
                                                Text(t.invoice_amount.toUpperCase(), style: caps),
                                            ],
                                        ),
                                    ),
                                    Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                Expanded(
                                                    child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                            Text(hotel.propertyName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: strong)),
                                                            if (hotel.roomName.isNotEmpty) Text(hotel.roomName, style: small),
                                                            Text(
                                                                '${_fmtDate(hotel.checkIn)} → ${_fmtDate(hotel.checkOut)} · ${hotel.nights} nights',
                                                                style: small,
                                                            ),
                                                            Text(guests, style: small),
                                                        ],
                                                    ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                    formatMoney(total, currency),
                                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: strong),
                                                ),
                                            ],
                                        ),
                                    ),
                                ] else ...[
                                    Container(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        decoration: ruled(),
                                        child: Row(
                                            children: [
                                                Expanded(child: Text(t.invoice_flight.toUpperCase(), style: caps)),
                                                Expanded(child: Text(t.invoice_route.toUpperCase(), style: caps)),
                                                Expanded(child: Text(t.invoice_date.toUpperCase(), style: caps)),
                                            ],
                                        ),
                                    ),
                                    for (final seg in flight?.segments ?? const <FlightSegment>[])
                                        Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            child: Row(
                                                children: [
                                                    Expanded(
                                                        child: Text(
                                                            '${seg.airline} ${seg.flightNumber}',
                                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: body),
                                                        ),
                                                    ),
                                                    Expanded(
                                                        child: Text('${seg.origin} → ${seg.destination}', style: TextStyle(fontSize: 12, color: body)),
                                                    ),
                                                    Expanded(child: Text(_fmtDate(seg.departure), style: small)),
                                                ],
                                            ),
                                        ),
                                ],
                                if (!isHotel && flight != null && flight.passengers.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Text(t.trips_sections_passengers.toUpperCase(), style: caps),
                                    const SizedBox(height: 6),
                                    for (final p in flight.passengers)
                                        Padding(
                                            padding: const EdgeInsets.only(bottom: 4),
                                            child: Row(
                                                children: [
                                                    Expanded(
                                                        child: Text.rich(
                                                            TextSpan(
                                                                children: [
                                                                    TextSpan(text: '${p.name} '),
                                                                    if (p.type.isNotEmpty)
                                                                        TextSpan(
                                                                            text: '(${p.type})',
                                                                            style: const TextStyle(color: TwPalette.slate400),
                                                                        ),
                                                                ],
                                                            ),
                                                            style: TextStyle(fontSize: 12, color: body),
                                                        ),
                                                    ),
                                                    if (p.ticketNumber != null)
                                                        Text(
                                                            'E-TKT: ${p.ticketNumber}',
                                                            style: TextStyle(
                                                                fontFamily: 'JetBrains Mono',
                                                                fontSize: 10,
                                                                color: dark ? TwPalette.emerald400 : TwPalette.emerald600,
                                                            ),
                                                        ),
                                                ],
                                            ),
                                        ),
                                ],
                            ],
                        ),
                    ),

                    // Booking reference
                    block(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        child: Wrap(
                            spacing: 24,
                            runSpacing: 12,
                            children: [
                                meta(
                                    t.invoice_bookingRef,
                                    isHotel ? (hotel?.reference ?? shortId(booking.id)) : (flight?.pnr ?? ''),
                                ),
                                meta(
                                    t.invoice_type,
                                    isHotel ? 'Hotel' : 'Flight · ${flight?.tripType ?? 'one-way'}',
                                ),
                                meta(
                                    t.trips_labels_provider,
                                    isHotel ? 'Hotel Partner' : ((flight?.provider.isNotEmpty ?? false) ? flight!.provider : '—'),
                                ),
                                meta(t.trips_sections_payment, t.invoice_paymentMethod),
                            ],
                        ),
                    ),

                    // Total
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        child: Row(
                            children: [
                                Expanded(
                                    child: Text(
                                        t.invoice_totalPaid,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: TwPalette.slate500),
                                    ),
                                ),
                                Text(
                                    formatMoney(total, currency),
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: dark ? Colors.white : TwPalette.slate900,
                                    ),
                                ),
                            ],
                        ),
                    ),

                    // Footer
                    Padding(
                        padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                        child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                                color: dark ? TwPalette.slate800 : TwPalette.slate50,
                                borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text.rich(
                                TextSpan(
                                    children: [
                                        TextSpan(text: 'Thank you for booking with $brandName. For support, contact '),
                                        const TextSpan(text: 'crm@myfarebox.com', style: TextStyle(color: TwPalette.indigo500)),
                                    ],
                                ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12, color: TwPalette.slate400),
                            ),
                        ),
                    ),
                ],
            ),
        );
    }
}

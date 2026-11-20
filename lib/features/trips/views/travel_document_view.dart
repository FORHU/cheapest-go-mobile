/// A booking's document — e-ticket, voucher or receipt. V2's `/trips/document/[id]`.
///
/// One route for all three, because they load the same booking the same way and differ only
/// in what they are allowed to show.
///
/// The kind asked for is checked against `availableDocuments` rather than trusted: a route is
/// a guess, and `kind=eticket` on a booking the airline has not ticketed must not produce a
/// document that says it has.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:cheapest_go_mobile/features/trips/api/bookings_source.dart';
import 'package:cheapest_go_mobile/features/trips/components/document_actions.dart';
import 'package:cheapest_go_mobile/features/trips/components/travel_documents.dart';
import 'package:cheapest_go_mobile/features/trips/lib/travel_documents.dart';
import 'package:cheapest_go_mobile/features/trips/models/trip_booking.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/lib/http.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_palette.dart';

class TravelDocumentView extends StatefulWidget {
    const TravelDocumentView({required this.bookingId, this.kind, super.key});

    final String bookingId;

    /// `eticket`, `voucher` or `receipt`, as the link asked. Anything else is a receipt.
    final String? kind;

    @override
    State<TravelDocumentView> createState() => _TravelDocumentViewState();
}

class _TravelDocumentViewState extends State<TravelDocumentView> {
    late final Future<TripBooking?> _load = findMyBooking(widget.bookingId);
    final _document = GlobalKey<PrintableDocumentState>();
    VoucherProperty? _property;
    bool _askedProperty = false;

    TravelDocument get _kind => TravelDocument.values.firstWhere(
        (k) => k.name == widget.kind,
        orElse: () => TravelDocument.receipt,
    );

    /// The property's address, phone and hours, read when the voucher is opened.
    ///
    /// Best-effort: a voucher without a phone number is still a valid voucher, so a lookup
    /// that fails must not take the document down with it.
    Future<void> _lookUpProperty(HotelStayBooking booking) async {
        final code = booking.hotelCode;
        if (_askedProperty || _kind != TravelDocument.voucher || code == null || code.isEmpty) return;
        _askedProperty = true;
        try {
            final res = await HttpClientAdapter().get(
                '/api/v2/hotels/property/${Uri.encodeComponent(code)}',
                options: const HttpRequestOptions(useMobileApiKey: true, requiresAuth: false),
            );
            final content = res is Map ? res['content'] : null;
            if (content is! Map || !mounted) return;
            String? text(Object? v) => v == null || '$v'.isEmpty ? null : '$v';
            // Suppliers often end the street address with the city already, so appending it
            // blindly prints "…Songpa-gu, Seoul, Seoul, KR".
            final parts = <String>[];
            for (final part in [text(content['address']), text(content['city']), text(content['country'])]) {
                if (part == null) continue;
                if (parts.any((prev) => prev.toLowerCase().contains(part.toLowerCase()))) continue;
                parts.add(part);
            }
            final contact = content['contact_info'];
            setState(() {
                _property = VoucherProperty(
                    address: parts.isEmpty ? null : parts.join(', '),
                    phone: contact is Map ? text(contact['phone']) : null,
                    checkInTime: text(content['check_in_time']),
                    checkOutTime: text(content['check_out_time']),
                );
            });
        } catch (_) {
            // The voucher stands without it.
        }
    }

    @override
    Widget build(BuildContext context) {
        final c = context.colors;
        return Scaffold(
            backgroundColor: c.background,
            body: SafeArea(
                child: FutureBuilder<TripBooking?>(
                    future: _load,
                    builder: (context, snapshot) {
                        final Widget body;
                        if (snapshot.connectionState == ConnectionState.waiting) {
                            body = const _Plate(height: 384);
                        } else if (snapshot.hasError || snapshot.data == null) {
                            body = _Message(error: snapshot.error?.toString());
                        } else {
                            body = _documentFor(context, snapshot.data!);
                        }
                        return ListView(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                            children: [
                                _BackToBooking(bookingId: widget.bookingId),
                                body,
                            ],
                        );
                    },
                ),
            ),
        );
    }

    Widget _documentFor(BuildContext context, TripBooking booking) {
        final kind = _kind;
        // The URL asked; the booking decides. A link that asks for more than the booking has
        // earned gets the pending notice, not a document claiming something that has not
        // happened. Golf has no documents here, as it has none on V2.
        if (booking is GolfTeeTimeBooking || !availableDocuments(booking).contains(kind)) {
            final why = booking is GolfTeeTimeBooking ? null : pendingReason(booking);
            return why != null ? _Pending(reason: why) : const _Message();
        }
        if (booking is HotelStayBooking) _lookUpProperty(booking);

        final document = switch (kind) {
            TravelDocument.eticket => FlightETicket(booking: booking as FlightTripBooking),
            TravelDocument.voucher => HotelVoucher(booking: booking as HotelStayBooking, property: _property),
            TravelDocument.receipt => PaymentReceipt(booking: booking),
        };

        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                DocumentActions(
                    filename: pdfFilename(documentFilePrefix(kind), documentReference(booking)),
                    makePdf: () => _document.currentState!.toPdf(),
                ),
                PrintableDocument(key: _document, child: document),
            ],
        );
    }
}

/// Back to the booking the document belongs to — the trips pages' own back link.
class _BackToBooking extends StatelessWidget {
    const _BackToBooking({required this.bookingId});

    final String bookingId;

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;
        final muted = context.colors.textMuted;
        return Align(
            alignment: Alignment.centerLeft,
            child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => context.canPop() ? context.pop() : context.go('/trips/$bookingId'),
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                Icon(LucideIcons.arrowLeft, size: 15, color: muted),
                                const SizedBox(width: 6),
                                Text(t.trips_bookingDetails, style: TextStyle(fontSize: 14, color: muted)),
                            ],
                        ),
                    ),
                ),
            ),
        );
    }
}

/// The panel's material, empty — what the document stands on while it loads.
class _Plate extends StatelessWidget {
    const _Plate({this.height, this.child});

    final double? height;
    final Widget? child;

    @override
    Widget build(BuildContext context) => Container(
        height: height,
        padding: child == null ? null : const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? TwPalette.slate900 : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1))],
        ),
        child: child,
    );
}

/// Paid, but the thing being waited on has not happened. Said plainly, not left blank.
class _Pending extends StatelessWidget {
    const _Pending({required this.reason});

    final DocumentPending reason;

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;
        return _Plate(
            child: Column(
                children: [
                    const Icon(LucideIcons.clock, size: 28, color: TwPalette.amber500),
                    const SizedBox(height: 12),
                    Text(
                        reason == DocumentPending.awaitingTicket
                            ? t.documents_pending_awaitingTicket
                            : t.documents_pending_awaitingConfirmation,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).brightness == Brightness.dark ? TwPalette.slate100 : TwPalette.slate700,
                        ),
                    ),
                ],
            ),
        );
    }
}

class _Message extends StatelessWidget {
    const _Message({this.error});

    final String? error;

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;
        return _Plate(
            child: Column(
                children: [
                    Text(
                        t.trips_invoice_loadError,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
                    ),
                    if (error != null) ...[
                        const SizedBox(height: 8),
                        Text(error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: context.colors.textMuted)),
                    ],
                ],
            ),
        );
    }
}

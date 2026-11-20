/// The three documents a traveller actually needs, drawn as one family. V2's
/// `travel-documents.tsx`, at its phone width.
///
/// They share one shell — the booking detail page's card, section heads and label-and-value
/// rows — because they are printed together and read together. What differs is what each one
/// is allowed to claim:
///
///   - the **E-ticket** claims an airline issued a ticket, so it is gated on issuance and
///     never on the PNR;
///   - the **Hotel Voucher** claims a property is holding a room, and leads with the
///     reference that property can actually find;
///   - the **Payment Receipt** claims only that money moved.
///
/// Deliberately absent: a boarding pass. One is issued by the airline at check-in and carries
/// their barcode; anything this app drew would be a picture of a boarding pass, which is worse
/// than none at all.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:cheapest_go_mobile/features/trips/lib/travel_documents.dart';
import 'package:cheapest_go_mobile/features/trips/models/trip_booking.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/lib/env.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_palette.dart';
import 'package:cheapest_go_mobile/shared/utils/money.dart';

// ─── Shared shell ─────────────────────────────────────────────────────────────
//
// The booking detail page's materials, so a document opened from a booking reads as part of
// it: the panel's white card and 20px corners, its icon-and-title section heads, its
// label-and-value rows split by a hairline, and the brand's one blue-to-cyan gradient.

const double _pad = 20;
const String _mono = 'JetBrains Mono';

bool _dark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

/// V2's `TITLE`, `TEXT`, `MUTED`, `HAIRLINE` and `SOFT`, as the theme states them.
Color _title(BuildContext c) => c.colors.textPrimary;
Color _text(BuildContext c) => _dark(c) ? TwPalette.slate100 : TwPalette.slate700;
Color _muted(BuildContext c) => c.colors.textMuted;
Color _hairline(BuildContext c) => _dark(c) ? const Color(0x1AFFFFFF) : TwPalette.slate200;
Color _soft(BuildContext c) => _dark(c) ? const Color(0x14FFFFFF) : TwPalette.slate100;

DateTime _local(DateTime d) => d.isUtc ? d.toLocal() : d;

/// `Nov 20, 2026` — V2 prints a document's dates in en-US whatever the language.
String _date(DateTime d) => DateFormat('MMM d, y', 'en_US').format(_local(d));
String _dateTime(DateTime d) => DateFormat('MMM d, y, h:mm a', 'en_US').format(_local(d));

/// `Thu, Nov 26, 2026` — a booking's day, in the reader's language (`formatBookingDate`).
String _bookingDay(DateTime d) => DateFormat.yMMMEd(Intl.defaultLocale).format(_local(d));

/// `7:21 PM` (`formatBookingTime`).
String _bookingTime(DateTime d) => DateFormat('h:mm a', 'en_US').format(_local(d));

/// The booking card's status colours (`BookingStatusBadge`), one per meaning.
enum StatusTone { green, amber, slate }

class _Tone {
    const _Tone(this.background, this.foreground);
    final Color background;
    final Color foreground;
}

_Tone _tone(BuildContext context, StatusTone tone) {
    final dark = _dark(context);
    return switch (tone) {
        StatusTone.green => dark
            ? _Tone(TwPalette.emerald500.withValues(alpha: 0.15), TwPalette.emerald300)
            : const _Tone(TwPalette.emerald50, TwPalette.emerald700),
        StatusTone.amber => dark
            ? _Tone(TwPalette.amber500.withValues(alpha: 0.15), TwPalette.amber300)
            : const _Tone(TwPalette.amber50, TwPalette.amber700),
        StatusTone.slate => dark
            ? const _Tone(Color(0x1AFFFFFF), TwPalette.slate300)
            : const _Tone(TwPalette.slate100, TwPalette.slate600),
    };
}

/// The brand's wordmark as V2 draws it: the head light, the tail bold in the accent.
class DocumentWordmark extends StatelessWidget {
    const DocumentWordmark({super.key, this.height = 22});

    final double height;

    @override
    Widget build(BuildContext context) {
        // `CheapestGo` → `cheapest` + `Go`: the tail starts at the last capital.
        final split = brandName.lastIndexOf(RegExp('[A-Z]'));
        final head = split > 0 ? brandName.substring(0, split) : brandName;
        final tail = split > 0 ? brandName.substring(split) : '';
        final dark = _dark(context);
        final size = height * 22 / 24;
        return Semantics(
            label: brandName,
            child: ExcludeSemantics(
                child: Text.rich(
                    TextSpan(
                        children: [
                            TextSpan(
                                text: head.toLowerCase(),
                                style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.3,
                                    color: dark ? const Color(0xFFF1F5F9) : TwPalette.slate900,
                                ),
                            ),
                            TextSpan(
                                text: tail,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                    color: dark ? TwPalette.blue400 : TwPalette.alabasterAccent,
                                ),
                            ),
                        ],
                    ),
                    style: TextStyle(fontSize: size, height: 1),
                ),
            ),
        );
    }
}

class _StatusBadge extends StatelessWidget {
    const _StatusBadge({required this.label, required this.tone});

    final String label;
    final StatusTone tone;

    @override
    Widget build(BuildContext context) {
        final t = _tone(context, tone);
        return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: t.background, borderRadius: BorderRadius.circular(999)),
            child: Text(
                label,
                maxLines: 1,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.foreground),
            ),
        );
    }
}

/// The masthead — who issued it, what it is, and how to find it again — over the document.
class DocumentShell extends StatelessWidget {
    const DocumentShell({
        required this.title,
        required this.icon,
        required this.status,
        required this.statusTone,
        required this.children,
        this.reference,
        this.issued,
        super.key,
    });

    final String title;
    final IconData icon;
    final String status;
    final StatusTone statusTone;
    final String? reference;

    /// The document's own date line beside the reference, already worded.
    final String? issued;
    final List<Widget> children;

    @override
    Widget build(BuildContext context) {
        final hasLine = (reference?.isNotEmpty ?? false) || (issued?.isNotEmpty ?? false);
        return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
                color: _dark(context) ? TwPalette.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1))],
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    Padding(
                        padding: const EdgeInsets.fromLTRB(_pad, 24, _pad, 20),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Row(
                                    children: [
                                        const Expanded(
                                            child: Align(alignment: Alignment.centerLeft, child: DocumentWordmark()),
                                        ),
                                        const SizedBox(width: 16),
                                        _StatusBadge(label: status, tone: statusTone),
                                    ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: ExcludeSemantics(
                                                child: Icon(
                                                    icon,
                                                    size: 20,
                                                    color: _dark(context) ? TwPalette.blue400 : TwPalette.blue600,
                                                ),
                                            ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            child: Semantics(
                                                header: true,
                                                child: Text(
                                                    title,
                                                    style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.w700,
                                                        height: 1.25,
                                                        color: _title(context),
                                                    ),
                                                ),
                                            ),
                                        ),
                                    ],
                                ),
                                if (hasLine) ...[
                                    const SizedBox(height: 6),
                                    Text.rich(
                                        TextSpan(
                                            children: [
                                                if (reference?.isNotEmpty ?? false)
                                                    TextSpan(
                                                        text: reference,
                                                        style: TextStyle(
                                                            fontFamily: _mono,
                                                            fontWeight: FontWeight.w600,
                                                            letterSpacing: 1.1,
                                                            color: _text(context),
                                                        ),
                                                    ),
                                                if ((reference?.isNotEmpty ?? false) && (issued?.isNotEmpty ?? false))
                                                    const TextSpan(text: ' · '),
                                                if (issued?.isNotEmpty ?? false) TextSpan(text: issued),
                                            ],
                                        ),
                                        style: TextStyle(fontSize: 13, color: _muted(context)),
                                    ),
                                ],
                            ],
                        ),
                    ),
                    Container(height: 3, decoration: const BoxDecoration(gradient: kBrandGradient)),
                    ...children,
                ],
            ),
        );
    }
}

/// A section's head, as the detail page's panels set theirs: an icon, then the title.
class _Band extends StatelessWidget {
    const _Band({required this.icon, required this.label});

    final IconData icon;
    final String label;

    @override
    Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(_pad, 24, _pad, 4),
        child: Row(
            children: [
                ExcludeSemantics(
                    child: Icon(icon, size: 17, color: _dark(context) ? Colors.white : TwPalette.slate700),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Semantics(
                        header: true,
                        child: Text(label, style: TextStyle(fontSize: 17, color: _title(context))),
                    ),
                ),
            ],
        ),
    );
}

/// A block of the document, ruled off from the next by a hairline.
class _Section extends StatelessWidget {
    const _Section({required this.child, this.last = false});

    final Widget child;
    final bool last;

    @override
    Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: _pad, vertical: 20),
        decoration: BoxDecoration(
            border: last ? null : Border(bottom: BorderSide(color: _hairline(context))),
        ),
        child: child,
    );
}

/// Label-and-value rows (`DetailRow`), one column at phone width.
class _Facts extends StatelessWidget {
    const _Facts({required this.children});

    final List<Widget> children;

    @override
    Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(_pad, 0, _pad, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
}

class _Fact extends StatelessWidget {
    const _Fact(this.label, this.value);

    final String label;
    final Widget value;

    @override
    Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _hairline(context)))),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Up to half the row, then it wraps — a long label in another language must not
                // push the value off the page.
                Flexible(child: Text(label, style: TextStyle(fontSize: 14, color: _muted(context)))),
                const SizedBox(width: 16),
                Expanded(
                    child: DefaultTextStyle.merge(
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _text(context)),
                        child: Align(alignment: Alignment.topRight, child: value),
                    ),
                ),
            ],
        ),
    );
}

/// A label above its value, the unit the e-ticket and voucher are built from.
class _Field extends StatelessWidget {
    const _Field(this.label, this.value);

    final String label;
    final Widget value;

    @override
    Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(label, style: TextStyle(fontSize: 12, color: _muted(context))),
            const SizedBox(height: 2),
            DefaultTextStyle.merge(
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _text(context)),
                child: value,
            ),
        ],
    );
}

/// Children two to a row, as V2's `grid-cols-2` lays them at phone width.
class _Grid extends StatelessWidget {
    const _Grid({required this.children, this.gap = 16, this.runGap = 16});

    final List<Widget> children;
    final double gap;
    final double runGap;

    @override
    Widget build(BuildContext context) {
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += 2) {
            if (rows.isNotEmpty) rows.add(SizedBox(height: runGap));
            rows.add(
                Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Expanded(child: children[i]),
                        SizedBox(width: gap),
                        Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox.shrink()),
                    ],
                ),
            );
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
    }
}

/// A value under its own, smaller second line — a time under a date, an airport under a code.
class _TwoLines extends StatelessWidget {
    const _TwoLines(this.first, this.second, {this.mono = false});

    final String first;
    final String? second;
    final bool mono;

    @override
    Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(first, style: mono ? const TextStyle(fontFamily: _mono) : null),
            if (second != null && second!.isNotEmpty)
                Text(
                    second!,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: _muted(context)),
                ),
        ],
    );
}

class _Footer extends StatelessWidget {
    const _Footer(this.text);

    final String text;

    @override
    Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: _pad, vertical: 20),
        child: Text(text, style: TextStyle(fontSize: 12, color: _muted(context))),
    );
}

Text _monoText(String s) => Text(s, style: const TextStyle(fontFamily: _mono));

// ─── Flight e-ticket ──────────────────────────────────────────────────────────

class FlightETicket extends StatelessWidget {
    const FlightETicket({required this.booking, super.key});

    final FlightTripBooking booking;

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;
        final tickets = ticketNumbers(booking);
        final lead = booking.passengers.isEmpty ? null : booking.passengers.first;
        final policy = booking.farePolicy;
        final seat = (lead?.seatNumber?.isNotEmpty ?? false) ? lead!.seatNumber! : t.documents_eticket_atCheckIn;

        return DocumentShell(
            title: t.documents_eticket_title,
            icon: LucideIcons.plane,
            reference: booking.pnr,
            status: t.documents_status_ticketed,
            statusTone: StatusTone.green,
            children: [
                _Section(
                    child: _Grid(
                        children: [
                            _Field(
                                t.documents_eticket_passenger,
                                Text(lead == null ? '—' : lead.name.toUpperCase()),
                            ),
                            _Field(t.documents_eticket_pnr, _monoText(booking.pnr.isEmpty ? '—' : booking.pnr)),
                            // Only ever printed once the airline has issued — the whole reason
                            // this document is gated rather than drawn from the PNR.
                            _Field(t.documents_eticket_ticketNumber, _monoText(tickets.isEmpty ? '—' : tickets.first)),
                        ],
                    ),
                ),
                for (final s in booking.segments)
                    _Section(
                        child: _Grid(
                            children: [
                                _Field(
                                    t.documents_eticket_flight,
                                    Text([s.airline, s.flightNumber].where((p) => p.isNotEmpty).join(' ').ifEmpty('—')),
                                ),
                                _Field(t.documents_eticket_from, _TwoLines(s.origin, _dateTime(s.departure), mono: true)),
                                _Field(t.documents_eticket_to, _TwoLines(s.destination, _dateTime(s.arrival), mono: true)),
                                _Field(t.documents_eticket_seat, Text(seat)),
                            ],
                        ),
                    ),
                _Section(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(t.documents_eticket_fareConditions, style: TextStyle(fontSize: 12, color: _muted(context))),
                            const SizedBox(height: 4),
                            Text(
                                [
                                    (policy?.isRefundable ?? false)
                                        ? t.documents_eticket_refundable
                                        : t.documents_eticket_nonRefundable,
                                    if (policy?.isChangeable == false) t.documents_eticket_nonChangeable,
                                ].join(' · '),
                                style: TextStyle(fontSize: 14, color: _dark(context) ? TwPalette.slate300 : TwPalette.slate600),
                            ),
                        ],
                    ),
                ),
                // No boarding pass here, and no barcode. Check-in belongs to the airline, and a
                // barcode this app invented would scan as nothing at a gate.
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _pad, vertical: 20),
                    child: Text(t.documents_eticket_checkInHint, style: TextStyle(fontSize: 12, color: _muted(context))),
                ),
                _Footer(t.documents_eticket_footer),
            ],
        );
    }
}

// ─── Hotel voucher ────────────────────────────────────────────────────────────

/// The property as it is today — address, phone and house hours — read when the voucher is
/// opened rather than stored with the booking. A guest arriving today wants today's number.
class VoucherProperty {
    const VoucherProperty({this.address, this.phone, this.checkInTime, this.checkOutTime});

    final String? address;
    final String? phone;
    final String? checkInTime;
    final String? checkOutTime;
}

class HotelVoucher extends StatelessWidget {
    const HotelVoucher({required this.booking, this.property, super.key});

    final HotelStayBooking booking;
    final VoucherProperty? property;

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;
        final supplierRef = booking.supplierReference;
        final muted = TextStyle(fontSize: 12, color: _muted(context));
        // Snapshot first, then the property's current hours. A check-in hour is a house rule
        // rather than part of the rate, so reading it live is right — but if the booking ever
        // captured one, that is what the guest agreed to.
        final checkInTime = booking.checkInTime ?? property?.checkInTime;
        final checkOutTime = booking.checkOutTime ?? property?.checkOutTime;
        final requests = booking.specialRequests;

        return DocumentShell(
            title: t.documents_voucher_title,
            icon: LucideIcons.hotel,
            reference: supplierRef,
            status: t.documents_status_confirmed,
            statusTone: StatusTone.green,
            children: [
                _Section(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(
                                booking.propertyName,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _title(context)),
                            ),
                            if (property?.address?.isNotEmpty ?? false) Text(property!.address!, style: muted),
                            if (property?.phone?.isNotEmpty ?? false) Text(property!.phone!, style: muted),
                        ],
                    ),
                ),
                // The headline number is the supplier's, because that is the one the property's
                // own system holds. Ours is shown too — it is what support will ask for — but it
                // would not find the reservation at a front desk.
                _Section(
                    child: _Grid(
                        children: [
                            _Field(t.documents_voucher_confirmationNumber, _monoText(supplierRef ?? '—')),
                            _Field(
                                t.documents_voucher_ourReference,
                                Text(
                                    booking.bookingReference ?? shortId(booking.id),
                                    style: TextStyle(fontFamily: _mono, color: _muted(context)),
                                ),
                            ),
                        ],
                    ),
                ),
                _Section(
                    child: _Grid(
                        children: [
                            _Field(
                                t.documents_voucher_checkIn,
                                _TwoLines(
                                    _date(booking.checkIn),
                                    checkInTime == null ? null : t.documents_voucher_fromTime(checkInTime),
                                ),
                            ),
                            _Field(
                                t.documents_voucher_checkOut,
                                _TwoLines(
                                    _date(booking.checkOut),
                                    checkOutTime == null ? null : t.documents_voucher_untilTime(checkOutTime),
                                ),
                            ),
                            _Field(t.documents_voucher_stay, Text(t.search_nights(booking.nights))),
                            _Field(
                                t.documents_voucher_guests,
                                Text(t.documents_voucher_occupancy(
                                    booking.adults == 0 ? 1 : booking.adults,
                                    booking.children,
                                )),
                            ),
                        ],
                    ),
                ),
                _Section(
                    child: _Grid(
                        children: [
                            _Field(
                                t.documents_voucher_leadGuest,
                                Text(booking.holderName.isEmpty ? '—' : booking.holderName.toUpperCase()),
                            ),
                            _Field(t.documents_voucher_room, Text(booking.roomName.ifEmpty('—'))),
                            // Only when it was snapshotted at booking. An unknown meal plan is
                            // left out rather than guessed.
                            if (booking.board?.isNotEmpty ?? false)
                                _Field(t.documents_voucher_mealPlan, Text(booking.board!)),
                        ],
                    ),
                ),
                _Section(
                    child: _Grid(
                        children: [
                            _Field(t.documents_voucher_paymentStatus, Text(t.documents_voucher_paidOnline)),
                            _Field(t.documents_voucher_payAtProperty, Text(formatMoney(0, booking.currency))),
                        ],
                    ),
                ),
                if (requests != null && requests.isNotEmpty)
                    _Section(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(t.documents_voucher_specialRequests, style: muted),
                                const SizedBox(height: 4),
                                Text(
                                    requests,
                                    style: TextStyle(fontSize: 14, color: _dark(context) ? TwPalette.slate300 : TwPalette.slate600),
                                ),
                                const SizedBox(height: 4),
                                Text(t.documents_voucher_requestsNotGuaranteed, style: muted),
                            ],
                        ),
                    ),
                _Section(last: true, child: Text(t.documents_voucher_footer, style: muted)),
            ],
        );
    }
}

// ─── Payment receipt ──────────────────────────────────────────────────────────
//
// Laid out the way an airline's "e-ticket receipt & itinerary" is — passenger and booking
// facts, then the flights, then the fare and the notices — because that is the document people
// already know how to read and file. What it does not borrow is the claim: this one proves a
// payment, and a ticket number appears only once the airline has issued one.

class PaymentReceipt extends StatelessWidget {
    const PaymentReceipt({required this.booking, this.cardLast4, super.key});

    /// A flight or a stay. Golf has no receipt here, as it has none on V2.
    final TripBooking booking;

    /// Masked, always. Nothing here ever holds a full number, an expiry or a CVC.
    final String? cardLast4;

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;
        final number = receiptNumber(booking);
        final refunded = booking.status == 'refunded';
        final flight = booking is FlightTripBooking ? booking as FlightTripBooking : null;
        final hotel = booking is HotelStayBooking ? booking as HotelStayBooking : null;
        final issuedOn = booking.bookedAt;

        return DocumentShell(
            title: flight != null ? t.documents_receipt_titleItinerary : t.documents_receipt_title,
            icon: LucideIcons.receipt,
            reference: number,
            issued: issuedOn == null ? null : t.documents_receipt_issuedOn(_date(issuedOn)),
            status: isCancelled(booking)
                ? (refunded ? t.documents_receipt_refunded : t.documents_receipt_cancelled)
                : t.documents_receipt_paid,
            statusTone: isCancelled(booking) ? StatusTone.slate : StatusTone.green,
            children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(_pad, 20, _pad, 0),
                    child: Text(
                        flight != null ? t.documents_receipt_introFlight : t.documents_receipt_introHotel,
                        style: TextStyle(fontSize: 13, height: 1.6, color: _muted(context)),
                    ),
                ),
                if (flight != null) ..._flightBody(context, t, flight, number),
                if (hotel != null) ..._hotelBody(context, t, hotel, number),
                ..._fareAndPayment(context, t),
                if (flight != null) ..._notices(context, t),
                // A receipt proves a payment and nothing else. Saying so on the document is what
                // stops it being carried to a desk as if it were a ticket.
                _Footer(t.documents_receipt_footer),
            ],
        );
    }

    List<Widget> _flightBody(BuildContext context, AppLocalizations t, FlightTripBooking b, String number) {
        final ticketed = isTicketed(b);
        final tickets = ticketNumbers(b);
        final lead = b.passengers.isEmpty ? null : b.passengers.first;
        final segments = [...b.segments]..sort((x, y) {
            final byDirection = x.segmentIndex.compareTo(y.segmentIndex);
            return byDirection != 0 ? byDirection : x.departure.compareTo(y.departure);
        });
        final directions = segments.map((s) => s.segmentIndex).toSet();
        final trip = tripType(b.tripType);
        final segmentStatus = isCancelled(b) ? t.documents_receipt_segCancelled : t.documents_receipt_segConfirmed;
        final ticketedAt = b.ticketedAt;

        return [
            _Band(icon: LucideIcons.userRound, label: t.documents_receipt_sections_passengerBooking),
            _Facts(
                children: [
                    _Fact(t.documents_receipt_leadPassenger, Text(formatTravellerName(lead?.firstName, lead?.lastName))),
                    _Fact(t.documents_receipt_bookingReference, _monoText(documentReference(b))),
                    _Fact(t.documents_receipt_airlineReference, _monoText(b.pnr.ifEmpty('—'))),
                    _Fact(t.documents_receipt_receiptNumber, _monoText(number)),
                    if (b.bookedAt != null) _Fact(t.documents_receipt_paymentDate, Text(_date(b.bookedAt!))),
                    _Fact(
                        t.documents_receipt_ticketStatus,
                        ticketed
                            ? Text(ticketedAt != null
                                ? t.documents_receipt_ticketIssuedOn(_date(ticketedAt))
                                : t.documents_status_ticketed)
                            : Text(
                                t.documents_receipt_ticketPending,
                                style: TextStyle(color: _dark(context) ? TwPalette.amber400 : TwPalette.amber600),
                            ),
                    ),
                    if (trip != null)
                        _Fact(t.documents_receipt_tripType, Text(switch (trip) {
                            TripType.oneWay => t.documents_receipt_tripTypes_oneWay,
                            TripType.roundTrip => t.documents_receipt_tripTypes_roundTrip,
                            TripType.multiCity => t.documents_receipt_tripTypes_multiCity,
                        })),
                ],
            ),
            if (b.passengers.isNotEmpty) ...[
                _Band(icon: LucideIcons.users, label: t.documents_receipt_sections_passengers),
                for (var i = 0; i < b.passengers.length; i++)
                    _passengerRow(context, t, b.passengers[i], ticketed ? (b.passengers[i].ticketNumber ?? (i < tickets.length ? tickets[i] : null)) : null),
            ],
            if (segments.isNotEmpty) ...[
                _Band(icon: LucideIcons.plane, label: t.documents_receipt_sections_travel),
                for (var i = 0; i < segments.length; i++) ...[
                    if (directions.length > 1 && (i == 0 || segments[i - 1].segmentIndex != segments[i].segmentIndex))
                        Padding(
                            padding: const EdgeInsets.fromLTRB(_pad, 16, _pad, 0),
                            child: Text(
                                segments[i].segmentIndex == 0 ? t.documents_receipt_outbound : t.documents_receipt_return,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _dark(context) ? TwPalette.blue400 : TwPalette.blue600,
                                ),
                            ),
                        ),
                    _segmentRow(context, t, segments[i], segmentStatus),
                ],
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _pad, vertical: 8),
                    child: Text(t.documents_receipt_localTimes, style: TextStyle(fontSize: 12, color: _muted(context))),
                ),
            ],
        ];
    }

    /// A table row, its column names above each value as V2 sets them at phone width.
    Widget _row(BuildContext context, List<_Cell> cells) => Container(
        padding: const EdgeInsets.symmetric(horizontal: _pad, vertical: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _hairline(context)))),
        child: DefaultTextStyle.merge(
            style: TextStyle(fontSize: 14, color: _text(context)),
            child: _Grid(gap: 16, runGap: 12, children: cells),
        ),
    );

    Widget _passengerRow(BuildContext context, AppLocalizations t, FlightPassenger p, String? ticket) {
        final type = passengerType(p.type);
        final secondary = TextStyle(color: _dark(context) ? TwPalette.slate300 : TwPalette.slate600);
        return _row(context, [
            _Cell(
                t.documents_receipt_name,
                Text(formatTravellerName(p.firstName, p.lastName), style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            _Cell(
                t.documents_receipt_paxType,
                Text(
                    switch (type) {
                        PassengerType.adult => t.documents_receipt_paxTypes_adult,
                        PassengerType.child => t.documents_receipt_paxTypes_child,
                        PassengerType.infant => t.documents_receipt_paxTypes_infant,
                        null => p.type.ifEmpty('—'),
                    },
                    style: secondary,
                ),
            ),
            // Never before issuance: a number on a receipt reads as a ticket at a desk.
            _Cell(
                t.documents_receipt_eticketNumber,
                ticket != null
                    ? _monoText(formatTicketNumber(ticket))
                    : Text(t.documents_receipt_pending, style: const TextStyle(color: TwPalette.slate400)),
            ),
            _Cell(
                t.documents_receipt_seat,
                Text((p.seatNumber?.isNotEmpty ?? false) ? p.seatNumber! : t.documents_eticket_atCheckIn, style: secondary),
            ),
        ]);
    }

    Widget _segmentRow(BuildContext context, AppLocalizations t, FlightSegment s, String status) {
        final muted = TextStyle(color: _muted(context));
        String terminal(String? x) => (x?.isNotEmpty ?? false) ? ' · ${t.documents_receipt_terminal(x!)}' : '';
        return _row(context, [
            _Cell(
                t.documents_receipt_flight,
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(
                            formatFlightNumber(s.airline, s.flightNumber),
                            style: const TextStyle(fontFamily: _mono, fontWeight: FontWeight.w600),
                        ),
                        Text(
                            status,
                            style: TextStyle(
                                fontSize: 12,
                                color: _dark(context) ? TwPalette.emerald400 : TwPalette.emerald600,
                            ),
                        ),
                    ],
                ),
            ),
            _Cell(
                t.documents_receipt_departArrive,
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text('${_bookingDay(s.departure)} ${_bookingTime(s.departure)}'),
                        Text('${_bookingDay(s.arrival)} ${_bookingTime(s.arrival)}', style: muted),
                    ],
                ),
            ),
            _Cell(
                t.documents_receipt_airportTerminal,
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text.rich(TextSpan(children: [
                            TextSpan(text: s.origin, style: const TextStyle(fontFamily: _mono, fontWeight: FontWeight.w600)),
                            TextSpan(text: terminal(s.originTerminal), style: muted),
                        ])),
                        Text.rich(TextSpan(children: [
                            TextSpan(text: s.destination, style: const TextStyle(fontFamily: _mono, fontWeight: FontWeight.w600)),
                            TextSpan(text: terminal(s.destinationTerminal), style: muted),
                        ])),
                    ],
                ),
            ),
            _Cell(
                t.documents_receipt_cabin,
                Text(
                    formatCabin(s.cabinClass),
                    style: TextStyle(color: _dark(context) ? TwPalette.slate300 : TwPalette.slate600),
                ),
            ),
        ]);
    }

    List<Widget> _hotelBody(BuildContext context, AppLocalizations t, HotelStayBooking b, String number) => [
        _Band(icon: LucideIcons.hotel, label: t.documents_receipt_sections_stay),
        Padding(
            padding: const EdgeInsets.fromLTRB(_pad, 16, _pad, 0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(b.propertyName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _title(context))),
                    if (b.roomName.isNotEmpty)
                        Text(b.roomName, style: TextStyle(fontSize: 12, color: _muted(context))),
                ],
            ),
        ),
        _Facts(
            children: [
                _Fact(t.documents_receipt_bookingReference, _monoText(documentReference(b))),
                _Fact(t.documents_receipt_receiptNumber, _monoText(number)),
                _Fact(t.documents_voucher_leadGuest, Text(formatTravellerName(b.holderFirstName, b.holderLastName))),
                if (b.bookedAt != null) _Fact(t.documents_receipt_paymentDate, Text(_date(b.bookedAt!))),
                _Fact(t.documents_voucher_checkIn, Text(_date(b.checkIn))),
                _Fact(t.documents_voucher_checkOut, Text(_date(b.checkOut))),
                _Fact(t.documents_voucher_stay, Text(t.search_nights(b.nights))),
                _Fact(
                    t.documents_voucher_guests,
                    Text(t.documents_voucher_occupancy(b.adults == 0 ? 1 : b.adults, b.children)),
                ),
            ],
        ),
    ];

    List<Widget> _fareAndPayment(BuildContext context, AppLocalizations t) {
        final b = booking;
        final currency = b.currency.ifEmpty('PHP');
        final flight = b is FlightTripBooking ? b : null;
        final total = flight?.chargedPrice ?? b.totalPaid;
        final policy = flight?.farePolicy;
        final refund = flight != null && flight.refundAmount > 0
            ? formatMoney(flight.refundAmount, flight.refundCurrency ?? currency)
            : null;
        final penalty = policy?.refundPenaltyAmount;

        return [
            _Band(icon: LucideIcons.creditCard, label: t.documents_receipt_sections_farePayment),
            _Facts(
                children: [
                    _Fact(
                        t.documents_receipt_paymentMethod,
                        Text(cardLast4 != null ? '${t.documents_receipt_card} •••• $cardLast4' : t.documents_receipt_card),
                    ),
                    _Fact(t.documents_receipt_currency, Text(currency)),
                    if (policy != null)
                        _Fact(
                            t.documents_eticket_fareConditions,
                            _TwoLines(
                                [
                                    policy.isRefundable ? t.documents_eticket_refundable : t.documents_eticket_nonRefundable,
                                    if (policy.isChangeable == false) t.documents_eticket_nonChangeable,
                                ].join(' · '),
                                policy.isRefundable && penalty != null && penalty > 0
                                    ? t.documents_receipt_cancellationFee(
                                        formatMoney(penalty, policy.refundPenaltyCurrency ?? currency),
                                    )
                                    : null,
                            ),
                        ),
                    if (refund != null) _Fact(t.documents_receipt_refundedAmount, Text(refund)),
                ],
            ),
            Container(
                margin: const EdgeInsets.fromLTRB(_pad, 12, _pad, 20),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(color: _soft(context), borderRadius: BorderRadius.circular(16)),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                        Expanded(
                            child: Text(
                                t.documents_receipt_totalInclTaxes,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _muted(context)),
                            ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                            formatMoney(total, currency),
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _title(context)),
                        ),
                    ],
                ),
            ),
        ];
    }

    List<Widget> _notices(BuildContext context, AppLocalizations t) => [
        _Band(icon: LucideIcons.info, label: t.documents_receipt_sections_important),
        Padding(
            padding: const EdgeInsets.fromLTRB(_pad + 4, 16, _pad, 16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    for (final notice in [
                        t.documents_receipt_notices_checkIn,
                        t.documents_receipt_notices_airport,
                        t.documents_receipt_notices_names,
                        t.documents_receipt_notices_liquids,
                        t.documents_receipt_notices_baggage,
                    ])
                        Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Text('•  ', style: TextStyle(fontSize: 13, height: 1.6, color: _text(context))),
                                    Expanded(
                                        child: Text(notice, style: TextStyle(fontSize: 13, height: 1.6, color: _text(context))),
                                    ),
                                ],
                            ),
                        ),
                ],
            ),
        ),
    ];
}

/// The column's name above a value — V2's phone layout, where the header row is hidden.
class _Cell extends StatelessWidget {
    const _Cell(this.label, this.child);

    final String label;
    final Widget child;

    @override
    Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(label, style: TextStyle(fontSize: 12, color: _muted(context))),
            child,
        ],
    );
}

// ─── Where a traveller reaches them ───────────────────────────────────────────

/// The route a document is opened at — V2's `/trips/document/:id?type=…&kind=…`.
String documentPath(TripBooking b, TravelDocument kind) => Uri(
    path: '/trips/document/${Uri.encodeComponent(b.id)}',
    queryParameters: {
        'type': b is FlightTripBooking ? 'flight' : 'hotel',
        'kind': kind.name,
    },
).toString();

/// The documents this booking has, as soft pills — V2's `DocumentLinks` buttons.
///
/// Only what exists: no greyed-out e-ticket on a booking the airline has not ticketed. A
/// disabled control invites a tap and explains nothing; the pending line says what is being
/// waited on instead.
class DocumentLinkButtons extends StatelessWidget {
    const DocumentLinkButtons({required this.booking, super.key});

    final TripBooking booking;

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;
        final docs = availableDocuments(booking);
        final pending = pendingReason(booking);

        Widget pill(TravelDocument kind, IconData icon, String label) => Material(
            color: _soft(context),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => context.push(documentPath(booking, kind)),
                child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            Icon(icon, size: 14, color: _text(context)),
                            const SizedBox(width: 6),
                            Flexible(
                                child: Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _text(context)),
                                ),
                            ),
                        ],
                    ),
                ),
            ),
        );

        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                        if (docs.contains(TravelDocument.eticket))
                            pill(TravelDocument.eticket, LucideIcons.plane, t.documents_actions_eticket),
                        if (docs.contains(TravelDocument.voucher))
                            pill(TravelDocument.voucher, LucideIcons.hotel, t.documents_actions_voucher),
                        if (docs.contains(TravelDocument.receipt))
                            pill(TravelDocument.receipt, LucideIcons.receipt, t.documents_actions_receipt),
                    ],
                ),
                if (pending != null)
                    Padding(
                        padding: EdgeInsets.only(top: docs.isEmpty ? 0 : 8),
                        child: Text(
                            pending == DocumentPending.awaitingTicket
                                ? t.documents_pending_awaitingTicket
                                : t.documents_pending_awaitingConfirmation,
                            style: TextStyle(fontSize: 13, color: _muted(context)),
                        ),
                    ),
            ],
        );
    }
}

extension on String {
    String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

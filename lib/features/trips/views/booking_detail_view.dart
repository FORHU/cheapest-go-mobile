import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cheapest_go_mobile/features/trips/api/booking_actions.dart';
import 'package:cheapest_go_mobile/features/trips/api/bookings_source.dart';
import 'package:cheapest_go_mobile/features/trips/components/booking_card.dart';
import 'package:cheapest_go_mobile/features/trips/lib/travel_documents.dart';
import 'package:cheapest_go_mobile/features/trips/models/trip_booking.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/lib/env.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';
import 'package:cheapest_go_mobile/shared/utils/format.dart';
import 'package:cheapest_go_mobile/shared/utils/money.dart';

/// **Booking Details** — one booking, in full. See #42.
///
/// Found in the list rather than fetched on its own, as V2 does: `GET /bookings/:id` answers
/// with a hotel-only summary in another shape, and cards link by row id while that endpoint
/// looks up by reference. A traveller's own bookings are a short list.
///
/// What is here and what is not: everything the booking says, the policy it was made under,
/// and the two changes that cannot damage a reservation — special requests, which api-v2
/// keeps locally, and forwarding the confirmation. **Cancelling is not here.** It reaches the
/// live supplier through a refund path this project has not yet trusted, and a Cancel button
/// that silently fails is worse than no button.
class BookingDetailView extends StatefulWidget {
    const BookingDetailView({required this.bookingId, super.key});

    /// The row id, or a reference — both are in circulation, so both are matched.
    final String bookingId;

    @override
    State<BookingDetailView> createState() => _BookingDetailViewState();
}

class _BookingDetailViewState extends State<BookingDetailView> {
    Future<TripBooking?>? _load;

    @override
    void initState() {
        super.initState();
        _reload();
    }

    void _reload() => setState(() => _load = _find());

    Future<TripBooking?> _find() async {
        final page = await bookingsSource.myBookings();
        for (final booking in page.all) {
            if (booking.id == widget.bookingId || booking.reference == widget.bookingId) {
                return booking;
            }
        }
        return null;
    }

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;
        final c = context.colors;

        return Scaffold(
            backgroundColor: c.background,
            appBar: AppBar(
                backgroundColor: c.background,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: t.common_goBack,
                    onPressed: () => context.canPop() ? context.pop() : context.go('/trips'),
                ),
                title: Text(t.trips_bookingDetails, style: const TextStyle(fontSize: 18)),
            ),
            body: FutureBuilder<TripBooking?>(
                future: _load,
                builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                    }
                    final booking = snapshot.data;
                    if (booking == null) {
                        return Center(
                            child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                    t.trips_loadFailed_title,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: c.textMuted),
                                ),
                            ),
                        );
                    }
                    return _Body(booking: booking, t: t, onChanged: _reload);
                },
            ),
        );
    }
}

class _Body extends StatelessWidget {
    const _Body({required this.booking, required this.t, required this.onChanged});

    final TripBooking booking;
    final AppLocalizations t;
    final VoidCallback onChanged;

    @override
    Widget build(BuildContext context) {
        final c = context.colors;

        return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
                // The reference, in mono: the one thing on this page somebody reads aloud.
                Row(
                    children: [
                        Text('Ref: ', style: TextStyle(fontSize: 13, color: c.textMuted)),
                        SelectableText(
                            booking.reference,
                            style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.1,
                                color: c.textPrimary,
                            ),
                        ),
                    ],
                ),
                const SizedBox(height: 14),

                // The same card the list drew, without a link to the page it is already on.
                BookingCard(booking: booking, onOpen: () {}, detail: true),
                const SizedBox(height: 16),

                ...switch (booking) {
                    final HotelStayBooking b => _hotel(context, b),
                    final FlightTripBooking b => _flight(context, b),
                    final GolfTeeTimeBooking b => _golf(context, b),
                },

                _DocumentsPanel(booking: booking, t: t),
            ],
        );
    }

    // ── Hotel ─────────────────────────────────────────────────────────────────

    List<Widget> _hotel(BuildContext context, HotelStayBooking b) {
        final guests = [
            '${b.adults} ${b.adults == 1 ? 'adult' : 'adults'}',
            if (b.children > 0) '${b.children} ${b.children == 1 ? 'child' : 'children'}',
        ].join(', ');

        return [
            _Panel(
                title: t.trips_sections_stayDetails,
                icon: Icons.calendar_today_rounded,
                rows: [
                    _Row(t.trips_labels_checkIn, _long(b.checkIn)),
                    _Row(t.trips_labels_checkOut, _long(b.checkOut)),
                    _Row(t.trips_labels_duration,
                        b.nights == 1 ? t.trips_bookingCard_night(1) : t.trips_bookingCard_nights(b.nights)),
                    if (b.roomName.isNotEmpty) _Row(t.trips_labels_room, b.roomName),
                    _Row(t.trips_labels_guests, guests),
                ],
            ),
            if (b.holderName.isNotEmpty || b.holderEmail.isNotEmpty)
                _Panel(
                    title: t.trips_sections_guestInformation,
                    icon: Icons.person_outline_rounded,
                    rows: [
                        if (b.holderName.isNotEmpty) _Row(t.trips_labels_name, b.holderName),
                        if (b.holderEmail.isNotEmpty) _Row(t.trips_labels_email, b.holderEmail),
                    ],
                ),
            _CancellationPanel(booking: b, t: t),
            _SpecialRequestsPanel(booking: b, t: t, onSaved: onChanged),
            _SharePanel(booking: b, t: t),
            _PaymentPanel(
                t: t,
                total: formatMoney(b.totalPaid, b.currency),
                bookedAt: b.bookedAt,
                method: 'Card (Stripe)',
            ),
        ];
    }

    // ── Flight ────────────────────────────────────────────────────────────────

    List<Widget> _flight(BuildContext context, FlightTripBooking b) => [
        if (b.segments.isNotEmpty)
            _Panel(
                title: t.trips_sections_itinerary,
                icon: Icons.flight_takeoff_rounded,
                children: [
                    for (final leg in b.segments) _Leg(segment: leg),
                ],
            ),
        if (b.passengers.isNotEmpty)
            _Panel(
                title: t.trips_sections_passengers,
                icon: Icons.person_outline_rounded,
                children: [
                    for (final p in b.passengers)
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    if (p.ticketNumber != null)
                                        Text(
                                            'E-Ticket: ${p.ticketNumber}',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF15803D)),
                                        ),
                                ],
                            ),
                        ),
                ],
            ),
        _PaymentPanel(
            t: t,
            total: formatMoney(b.totalPaid, b.currency),
            bookedAt: b.bookedAt,
            provider: b.provider,
        ),
    ];

    // ── Golf ──────────────────────────────────────────────────────────────────

    List<Widget> _golf(BuildContext context, GolfTeeTimeBooking b) => [
        _Panel(
            title: t.trips_sections_stayDetails,
            icon: Icons.golf_course_rounded,
            rows: [
                _Row('Date', _long(b.startsAt)),
                _Row(t.trips_golfCard_teeTime, formatTeeTime(
                    '${b.startsAt.hour.toString().padLeft(2, '0')}:'
                    '${b.startsAt.minute.toString().padLeft(2, '0')}',
                )),
                _Row('Players', '${b.players}'),
                _Row(t.trips_labels_name, b.leadName),
                _Row(t.trips_labels_email, b.contactEmail),
            ],
        ),
        _Panel(
            title: t.trips_sections_payment,
            icon: Icons.credit_card_rounded,
            rows: [
                _Row('Green fees', formatMoney(b.greenFee, b.currency)),
                if (b.serviceFee > 0) _Row('Service fee', formatMoney(b.serviceFee, b.currency)),
                // A refunded booking says so here rather than only in the badge.
                if (b.refundAmount > 0)
                    _Row(t.trips_golfCard_refunded(formatMoney(b.refundAmount, b.currency)), ''),
                _Row(
                    b.wasCharged ? t.trips_golfCard_totalPaid : t.trips_golfCard_notCharged,
                    formatMoney(b.totalPaid, b.currency),
                    strong: true,
                ),
            ],
        ),
    ];

    static String _long(DateTime d) => '${formatShortDate(d)}, ${d.year}';
}

// ─── Panels ───────────────────────────────────────────────────────────────────

class _Row {
    const _Row(this.label, this.value, {this.strong = false});
    final String label;
    final String value;
    final bool strong;
}

class _Panel extends StatelessWidget {
    const _Panel({
        required this.title,
        required this.icon,
        this.rows = const [],
        this.children = const [],
    });

    final String title;
    final IconData icon;
    final List<_Row> rows;
    final List<Widget> children;

    @override
    Widget build(BuildContext context) {
        final c = context.colors;
        return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Row(
                        children: [
                            Icon(icon, size: 16, color: c.textMuted),
                            const SizedBox(width: 8),
                            Text(
                                title,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: c.textPrimary,
                                ),
                            ),
                        ],
                    ),
                    const SizedBox(height: 10),
                    for (final row in rows)
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Expanded(
                                        child: Text(
                                            row.label,
                                            style: TextStyle(fontSize: 13, color: c.textMuted),
                                        ),
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                        child: Text(
                                            row.value,
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: row.strong ? FontWeight.w800 : FontWeight.w600,
                                                color: c.textPrimary,
                                            ),
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    ...children,
                ],
            ),
        );
    }
}

class _Leg extends StatelessWidget {
    const _Leg({required this.segment});

    final FlightSegment segment;

    @override
    Widget build(BuildContext context) {
        final c = context.colors;
        String clock(DateTime d) {
            final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
            return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
        }

        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(
                        segment.itineraryIndex == 0 ? 'OUTBOUND' : 'RETURN',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: c.textMuted,
                        ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                        children: [
                            Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        Text(clock(segment.departure),
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                        Text(segment.origin, style: TextStyle(fontSize: 12, color: c.textMuted)),
                                    ],
                                ),
                            ),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                        Text(clock(segment.arrival),
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                        Text(segment.destination,
                                            style: TextStyle(fontSize: 12, color: c.textMuted)),
                                    ],
                                ),
                            ),
                        ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                        '${formatDayDate(segment.departure)}, ${segment.departure.year} · '
                        '${segment.airline}${segment.flightNumber}'
                        '${segment.cabinClass.isEmpty ? '' : ' · ${segment.cabinClass}'}',
                        style: TextStyle(fontSize: 11.5, color: c.textMuted),
                    ),
                ],
            ),
        );
    }
}

/// The policy as it was agreed — shown, never acted on. #42 has no Cancel button.
class _CancellationPanel extends StatelessWidget {
    const _CancellationPanel({required this.booking, required this.t});

    final HotelStayBooking booking;
    final AppLocalizations t;

    @override
    Widget build(BuildContext context) {
        final c = context.colors;
        final refundable = booking.refundable;
        final infos = booking.cancellationPolicy?['cancelPolicyInfos'];

        return _Panel(
            title: t.trips_sections_cancellationPolicy,
            icon: Icons.shield_outlined,
            children: [
                Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: refundable ? const Color(0x1A10B981) : const Color(0x1AEF4444),
                        borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                        children: [
                            Icon(
                                refundable ? Icons.check_circle_outline : Icons.cancel_outlined,
                                size: 16,
                                color: refundable ? const Color(0xFF059669) : const Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(
                                    refundable
                                        ? t.trips_labels_freeCancellation
                                        : t.trips_labels_nonRefundable,
                                    style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: refundable
                                            ? const Color(0xFF047857)
                                            : const Color(0xFFDC2626),
                                    ),
                                ),
                            ),
                        ],
                    ),
                ),
                if (infos is List)
                    for (final info in infos)
                        if (info is Map)
                            Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                    t.trips_labels_afterDatePenalty(
                                        _when(info['cancelTime']),
                                        formatMoney(
                                            num.tryParse('${info['amount']}') ?? 0,
                                            '${info['currency'] ?? booking.currency}',
                                        ),
                                    ),
                                    style: TextStyle(fontSize: 13, color: c.textMuted),
                                ),
                            ),
                if (infos is! List || infos.isEmpty)
                    Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                            t.trips_labels_policyNotAvailable,
                            style: TextStyle(fontSize: 13, color: c.textMuted),
                        ),
                    ),
            ],
        );
    }

    static String _when(Object? raw) {
        final at = DateTime.tryParse('$raw');
        return at == null ? '$raw' : '${formatShortDate(at)}, ${at.year}';
    }
}

/// Special requests. api-v2 keeps these against the booking and does **not** send them on, so
/// the note under the field says exactly that rather than implying the hotel has agreed.
class _SpecialRequestsPanel extends StatefulWidget {
    const _SpecialRequestsPanel({required this.booking, required this.t, required this.onSaved});

    final HotelStayBooking booking;
    final AppLocalizations t;
    final VoidCallback onSaved;

    @override
    State<_SpecialRequestsPanel> createState() => _SpecialRequestsPanelState();
}

class _SpecialRequestsPanelState extends State<_SpecialRequestsPanel> {
    late final _text = TextEditingController(text: widget.booking.specialRequests ?? '');
    bool _busy = false;
    String? _error;

    @override
    void dispose() {
        _text.dispose();
        super.dispose();
    }

    Future<void> _save() async {
        setState(() {
            _busy = true;
            _error = null;
        });
        try {
            await bookingActions.saveRequests(widget.booking, _text.text);
            if (!mounted) return;
            setState(() => _busy = false);
            widget.onSaved();
        } catch (error) {
            if (!mounted) return;
            setState(() {
                _busy = false;
                _error = error.toString().replaceFirst('Exception: ', '');
            });
        }
    }

    @override
    Widget build(BuildContext context) {
        final c = context.colors;
        return _Panel(
            title: widget.t.trips_labels_specialRequests,
            icon: Icons.chat_bubble_outline_rounded,
            children: [
                TextField(
                    controller: _text,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        hintText: 'e.g. Late check-in after 10 PM, extra bed, high floor…',
                    ),
                ),
                const SizedBox(height: 8),
                Text(
                    'Requests are passed to the property and are not guaranteed.',
                    style: TextStyle(fontSize: 11.5, color: c.textMuted),
                ),
                if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
                ],
                const SizedBox(height: 10),
                Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton(
                        onPressed: _busy ? null : _save,
                        child: Text(_busy ? '…' : 'Save request'),
                    ),
                ),
            ],
        );
    }
}

class _SharePanel extends StatefulWidget {
    const _SharePanel({required this.booking, required this.t});

    final HotelStayBooking booking;
    final AppLocalizations t;

    @override
    State<_SharePanel> createState() => _SharePanelState();
}

class _SharePanelState extends State<_SharePanel> {
    late final _email = TextEditingController(text: widget.booking.holderEmail);
    bool _busy = false;
    String? _message;
    bool _failed = false;

    @override
    void dispose() {
        _email.dispose();
        super.dispose();
    }

    Future<void> _send() async {
        setState(() {
            _busy = true;
            _message = null;
        });
        try {
            await bookingActions.share(widget.booking, _email.text);
            if (!mounted) return;
            setState(() {
                _busy = false;
                _failed = false;
                _message = widget.t.trips_shareForm_sentTo(_email.text.trim());
            });
        } catch (_) {
            if (!mounted) return;
            setState(() {
                _busy = false;
                _failed = true;
                _message = widget.t.trips_shareForm_sendError;
            });
        }
    }

    @override
    Widget build(BuildContext context) {
        final c = context.colors;
        return _Panel(
            title: widget.t.trips_shareForm_title,
            icon: Icons.mail_outline_rounded,
            children: [
                Text(
                    widget.t.trips_shareForm_blurb,
                    style: TextStyle(fontSize: 12.5, color: c.textMuted),
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: widget.t.trips_shareForm_sendTo),
                ),
                if (_message != null) ...[
                    const SizedBox(height: 8),
                    Text(
                        _message!,
                        style: TextStyle(
                            fontSize: 12,
                            color: _failed ? const Color(0xFFDC2626) : const Color(0xFF059669),
                        ),
                    ),
                ],
                const SizedBox(height: 10),
                Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton(
                        onPressed: _busy ? null : _send,
                        child: Text(_busy ? '…' : widget.t.trips_shareForm_submit),
                    ),
                ),
            ],
        );
    }
}

class _PaymentPanel extends StatelessWidget {
    const _PaymentPanel({
        required this.t,
        required this.total,
        required this.bookedAt,
        this.method,
        this.provider,
    });

    final AppLocalizations t;
    final String total;
    final DateTime? bookedAt;
    final String? method;
    final String? provider;

    @override
    Widget build(BuildContext context) => _Panel(
        title: t.trips_sections_payment,
        icon: Icons.credit_card_rounded,
        rows: [
            _Row(t.trips_labels_totalPaid, total, strong: true),
            if (method != null) _Row(t.trips_labels_paymentMethod, method!),
            if (provider != null && provider!.isNotEmpty) _Row(t.trips_labels_provider, provider!),
            if (bookedAt != null)
                _Row(t.trips_labels_bookedOn, '${formatShortDate(bookedAt!)}, ${bookedAt!.year}'),
        ],
    );
}

/// **Travel documents** — only the ones this booking has earned. See `travel_documents.dart`.
///
/// A button offered too early promises something that does not exist, so when nothing is
/// available yet the reason is given instead: silence reads as a fault.
class _DocumentsPanel extends StatelessWidget {
    const _DocumentsPanel({required this.booking, required this.t});

    final TripBooking booking;
    final AppLocalizations t;

    @override
    Widget build(BuildContext context) {
        final c = context.colors;
        final docs = availableDocuments(booking);
        final pending = pendingReason(booking);
        if (docs.isEmpty && pending == null) return const SizedBox.shrink();

        return _Panel(
            title: 'Travel documents',
            icon: Icons.description_outlined,
            children: [
                if (docs.contains(TravelDocument.receipt))
                    _DocButton(
                        icon: Icons.receipt_long_rounded,
                        label: 'View payment receipt',
                        onTap: () => _openReceipt(context),
                    ),
                // The voucher and the e-ticket are screens built from the booking, which is
                // its own ticket. Until then they are not offered, rather than offered broken.
                if (pending != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                            pending == DocumentPending.awaitingTicket
                                ? 'Waiting for the airline to issue your ticket.'
                                : 'Waiting for the property to confirm your booking.',
                            style: TextStyle(fontSize: 12.5, color: c.textMuted),
                        ),
                    ),
            ],
        );
    }

    Future<void> _openReceipt(BuildContext context) async {
        // Addressed by the row's id, which is what api-v2's invoice route takes.
        final url = Uri.parse('${env.webApiUrl}/api/v2/invoices/${booking.id}/pdf'
            '?type=${booking is FlightTripBooking ? 'flight' : 'hotel'}');
        await launchUrl(url, mode: LaunchMode.externalApplication);
    }
}

class _DocButton extends StatelessWidget {
    const _DocButton({required this.icon, required this.label, required this.onTap});

    final IconData icon;
    final String label;
    final VoidCallback onTap;

    @override
    Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: OutlinedButton.icon(
                onPressed: onTap,
                icon: Icon(icon, size: 16),
                label: Text(label),
            ),
        ),
    );
}

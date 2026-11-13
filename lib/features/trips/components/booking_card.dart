import 'package:flutter/material.dart';

import 'package:cheapest_go_mobile/features/trips/models/trip_booking.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';
import 'package:cheapest_go_mobile/shared/utils/format.dart';
import 'package:cheapest_go_mobile/shared/utils/money.dart';

/// A booking as My Bookings draws it. See #42.
///
/// One shell for all three kinds, as V2 has: a status badge, the thing booked, a span with
/// what sits between its two ends, then a foot carrying what was paid and the way in. Check-in
/// and check-out take the places a flight's departure and arrival do, with the nights between
/// them where a flight has its stops — which is what makes the three read as one list.
///
/// The headline figure is what was **paid**, in the currency it was paid in. Never converted:
/// a charge is not an estimate.
class BookingCard extends StatelessWidget {
    const BookingCard({required this.booking, required this.onOpen, this.detail = false, super.key});

    final TripBooking booking;

    /// Null action in [detail]: the card is the head of the page it would link to.
    final VoidCallback onOpen;
    final bool detail;

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;
        return switch (booking) {
            final HotelStayBooking b => _hotel(context, t, b),
            final FlightTripBooking b => _flight(context, t, b),
            final GolfTeeTimeBooking b => _golf(context, t, b),
        };
    }

    // ── Hotel ─────────────────────────────────────────────────────────────────

    Widget _hotel(BuildContext context, AppLocalizations t, HotelStayBooking b) {
        final guests = [
            if (b.adults > 0) b.adults == 1 ? t.trips_bookingCard_adult(1) : t.trips_bookingCard_adults(b.adults),
            if (b.children > 0)
                b.children == 1 ? t.trips_bookingCard_child(1) : t.trips_bookingCard_children(b.children),
        ].join(', ');

        return _Shell(
            status: _StatusBadge(status: _hotelStatus(b.status, t)),
            image: b.propertyImage,
            imageFallback: Icons.apartment_rounded,
            title: b.propertyName,
            subtitle: b.roomName,
            span: _Span(
                fromValue: _day(b.checkIn),
                fromLabel: t.trips_labels_checkIn,
                toValue: _day(b.checkOut),
                toLabel: t.trips_labels_checkOut,
                above: b.nights == 1 ? t.trips_bookingCard_night(1) : t.trips_bookingCard_nights(b.nights),
                below: guests,
            ),
            price: formatMoney(b.totalPaid, b.currency),
            priceLabel: t.trips_bookingCard_totalPaid,
            action: detail ? null : t.trips_viewDetails,
            onOpen: onOpen,
        );
    }

    // ── Flight ────────────────────────────────────────────────────────────────

    Widget _flight(BuildContext context, AppLocalizations t, FlightTripBooking b) {
        final out = b.first;
        final arrive = b.lastOutbound;
        final route = out == null || arrive == null
            ? ''
            : '${out.origin} → ${arrive.destination}';
        final when = out == null
            ? ''
            : '${formatDayDate(out.departure)}, ${out.departure.year} · '
                '${out.airline}${out.flightNumber}';

        return _Shell(
            status: _StatusBadge(status: _flightStatus(b.status, t)),
            title: route,
            subtitle: when,
            span: out == null || arrive == null
                ? null
                : _Span(
                    fromValue: _clock(out.departure),
                    fromLabel: out.origin,
                    toValue: _clock(arrive.arrival),
                    toLabel: arrive.destination,
                    above: b.stops == 0 ? 'Nonstop' : '${b.stops} stop',
                    below: 'PNR ${b.pnr}',
                ),
            price: formatMoney(b.totalPaid, b.currency),
            priceLabel: t.trips_bookingCard_totalPaid,
            action: detail ? null : t.trips_viewDetails,
            onOpen: onOpen,
        );
    }

    // ── Golf ──────────────────────────────────────────────────────────────────

    Widget _golf(BuildContext context, AppLocalizations t, GolfTeeTimeBooking b) {
        return _Shell(
            status: _StatusBadge(status: _golfStatus(b.status, t)),
            image: b.courseImage,
            imageFallback: Icons.golf_course_rounded,
            title: b.courseName,
            subtitle: b.where,
            span: _Span(
                fromValue: '${b.startsAt.day} ${_month(b.startsAt)}',
                fromLabel: 'Date',
                toValue: _clock(b.startsAt),
                toLabel: t.trips_golfCard_teeTime,
                above: b.players == 1 ? '1 player' : '${b.players} players',
                below: b.reference,
            ),
            price: formatMoney(b.totalPaid, b.currency),
            // A hold that lapsed was never charged, and saying "total paid" over it would be
            // a small lie about money.
            priceLabel: b.wasCharged ? t.trips_golfCard_totalPaid : t.trips_golfCard_notCharged,
            action: detail ? null : t.trips_golfCard_view,
            onOpen: onOpen,
        );
    }

    // ── Statuses ──────────────────────────────────────────────────────────────

    static _Status _hotelStatus(String status, AppLocalizations t) => switch (status) {
        'pending' => const _Status('Pending', Color(0xFFB45309), Color(0xFFFEF3C7)),
        'confirmed' => const _Status('Confirmed', Color(0xFF15803D), Color(0xFFDCFCE7)),
        'completed' => const _Status('Completed', Color(0xFF475569), Color(0xFFF1F5F9)),
        'cancelled' => const _Status('Cancelled', Color(0xFFB91C1C), Color(0xFFFEE2E2)),
        'cancelled_refunded' => const _Status('Refunded', Color(0xFF0F766E), Color(0xFFCCFBF1)),
        'cancelled_refund_failed' =>
            const _Status('Refund Failed', Color(0xFFB91C1C), Color(0xFFFEE2E2)),
        _ => _Status(status, const Color(0xFF475569), const Color(0xFFF1F5F9)),
    };

    static _Status _flightStatus(String status, AppLocalizations t) => switch (status) {
        'booked' || 'confirmed' || 'ticketed' =>
            const _Status('Confirmed', Color(0xFF15803D), Color(0xFFDCFCE7)),
        'cancelled' => const _Status('Cancelled', Color(0xFFB91C1C), Color(0xFFFEE2E2)),
        'refunded' => const _Status('Refunded', Color(0xFF0F766E), Color(0xFFCCFBF1)),
        _ => _Status(status, const Color(0xFF475569), const Color(0xFFF1F5F9)),
    };

    static _Status _golfStatus(String status, AppLocalizations t) => switch (status) {
        'confirmed' => _Status(t.trips_golfCard_status_confirmed, const Color(0xFF15803D), const Color(0xFFDCFCE7)),
        'cancelled' => _Status(t.trips_golfCard_status_cancelled, const Color(0xFFB91C1C), const Color(0xFFFEE2E2)),
        'declined' => _Status(t.trips_golfCard_status_declined, const Color(0xFFB91C1C), const Color(0xFFFEE2E2)),
        'expired' => _Status(t.trips_golfCard_status_expired, const Color(0xFF475569), const Color(0xFFF1F5F9)),
        'held' => _Status(t.trips_golfCard_status_held, const Color(0xFFB45309), const Color(0xFFFEF3C7)),
        'requested' => _Status(t.trips_golfCard_status_requested, const Color(0xFFB45309), const Color(0xFFFEF3C7)),
        _ => _Status(status, const Color(0xFF475569), const Color(0xFFF1F5F9)),
    };

    // ── Formatting ────────────────────────────────────────────────────────────

    /// The year only when it is not this one: both ends of the span have to fit a phone.
    static String _day(DateTime d) =>
        d.year == DateTime.now().year ? formatShortDate(d) : '${formatShortDate(d)}, ${d.year}';

    static String _month(DateTime d) => formatShortDate(d).split(' ').first;

    static String _clock(DateTime d) {
        final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
        final minute = d.minute.toString().padLeft(2, '0');
        return '$hour:$minute ${d.hour < 12 ? 'AM' : 'PM'}';
    }
}

// ─── Parts ────────────────────────────────────────────────────────────────────

class _Status {
    const _Status(this.label, this.foreground, this.background);
    final String label;
    final Color foreground;
    final Color background;
}

class _StatusBadge extends StatelessWidget {
    const _StatusBadge({required this.status});

    final _Status status;

    @override
    Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
            color: status.background,
            borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
            status.label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: status.foreground),
        ),
    );
}

/// Two ends with something between them: nights for a stay, stops for a flight, players for
/// a tee time. The shape that makes the three kinds read as one list.
class _Span extends StatelessWidget {
    const _Span({
        required this.fromValue,
        required this.fromLabel,
        required this.toValue,
        required this.toLabel,
        required this.above,
        required this.below,
    });

    final String fromValue;
    final String fromLabel;
    final String toValue;
    final String toLabel;
    final String above;
    final String below;

    @override
    Widget build(BuildContext context) {
        final c = context.colors;
        final end = Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
        );

        return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(fromValue, maxLines: 1, overflow: TextOverflow.ellipsis, style: end),
                            Text(fromLabel, style: TextStyle(fontSize: 11.5, color: c.textMuted)),
                        ],
                    ),
                ),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                        children: [
                            Text(
                                above,
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: c.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Container(width: 56, height: 1, color: c.border),
                            const SizedBox(height: 4),
                            Text(below, style: TextStyle(fontSize: 11, color: c.textMuted)),
                        ],
                    ),
                ),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                            Text(toValue, maxLines: 1, overflow: TextOverflow.ellipsis, style: end),
                            Text(toLabel, style: TextStyle(fontSize: 11.5, color: c.textMuted)),
                        ],
                    ),
                ),
            ],
        );
    }
}

class _Shell extends StatelessWidget {
    const _Shell({
        required this.status,
        required this.title,
        required this.subtitle,
        required this.span,
        required this.price,
        required this.priceLabel,
        required this.action,
        required this.onOpen,
        this.image,
        this.imageFallback,
    });

    final Widget status;
    final String? image;
    final IconData? imageFallback;
    final String title;
    final String subtitle;
    final Widget? span;
    final String price;
    final String priceLabel;

    /// Null on the detail page, where the card is already the thing it would open.
    final String? action;
    final VoidCallback onOpen;

    @override
    Widget build(BuildContext context) {
        final c = context.colors;

        return Container(
            decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    if (imageFallback != null)
                        SizedBox(
                            height: 160,
                            width: double.infinity,
                            child: image == null
                                ? ColoredBox(
                                    color: c.surfaceMuted,
                                    child: Icon(imageFallback, size: 30, color: c.textSubtle),
                                )
                                : Image.network(
                                    image!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => ColoredBox(
                                        color: c.surfaceMuted,
                                        child: Icon(imageFallback, size: 30, color: c.textSubtle),
                                    ),
                                ),
                        ),
                    Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Align(alignment: Alignment.centerLeft, child: status),
                                const SizedBox(height: 12),
                                Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 20,
                                        height: 1.15,
                                        fontWeight: FontWeight.w700,
                                        color: c.textPrimary,
                                    ),
                                ),
                                if (subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                        subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 13, color: c.textMuted),
                                    ),
                                ],
                                if (span != null) ...[
                                    const SizedBox(height: 16),
                                    span!,
                                ],
                            ],
                        ),
                    ),
                    Divider(height: 1, color: c.border),
                    Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                        child: Row(
                            children: [
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            Text(
                                                price,
                                                style: TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w700,
                                                    color: c.textPrimary,
                                                ),
                                            ),
                                            Text(
                                                priceLabel,
                                                style: TextStyle(fontSize: 11.5, color: c.textMuted),
                                            ),
                                        ],
                                    ),
                                ),
                                if (action != null)
                                    _GradientButton(label: action!, onPressed: onOpen),
                            ],
                        ),
                    ),
                ],
            ),
        );
    }
}

class _GradientButton extends StatelessWidget {
    const _GradientButton({required this.label, required this.onPressed});

    final String label;
    final VoidCallback onPressed;

    @override
    Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(999),
            child: Ink(
                decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF06B6D4)]),
                    borderRadius: BorderRadius.circular(999),
                ),
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Text(
                        label,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                        ),
                    ),
                ),
            ),
        ),
    );
}

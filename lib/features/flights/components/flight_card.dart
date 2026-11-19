import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:cheapest_go_mobile/features/flights/components/flight_chrome.dart';
import 'package:cheapest_go_mobile/features/flights/components/flight_itinerary.dart';
import 'package:cheapest_go_mobile/features/flights/lib/filter_offers.dart';
import 'package:cheapest_go_mobile/features/flights/lib/flight_utils.dart';
import 'package:cheapest_go_mobile/features/flights/models/flight_fare.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_palette.dart';

/// Turns an amount in the currency it came in into the text the card prints.
typedef MoneyFormatter = String Function(double amount, String currency);

/// One result, as V2's `FlightCard` draws it below `md` — the phone's grid.
///
/// The airline's line (logo disc, name, flight number, the Cheapest/Fastest badge), then the
/// outbound's times either side of the route line, the fare's two chips, and the price over a
/// rule with Select beside it. "Flight details" opens the segment-by-segment itinerary.
///
/// V2's bookmark is not drawn: on mobile a Saved Trip is still a device-local hotel, and a
/// flight cannot be saved until Saved Trips become account-tied (#43).
class FlightCard extends StatefulWidget {
  const FlightCard({
    required this.offer,
    required this.money,
    required this.onSelect,
    this.highlight,
    this.checkingPrice = false,
    super.key,
  });

  final FlightFare offer;
  final MoneyFormatter money;
  final ValueChanged<FlightFare> onSelect;
  final OfferHighlight? highlight;

  /// The fare is being checked with the airline before checkout.
  final bool checkingPrice;

  @override
  State<FlightCard> createState() => _FlightCardState();
}

class _FlightCardState extends State<FlightCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final skin = FlightSkin.of(context);
    final offer = widget.offer;

    final slices = groupSegmentsBySlice(offer.segments);
    if (slices.isEmpty) return const SizedBox.shrink();
    // The summary row is the outbound alone: read across every segment, a round trip went
    // CRK → CRK and counted the return's stops as the outbound's.
    final outbound = slices.first.segments;
    final primary = outbound.first;
    final last = outbound.last;
    final stops = outbound.length - 1;
    final minutes = (slices.first.index < offer.sliceDurations.length)
        ? offer.sliceDurations[slices.first.index]
        : (slices.length == 1 ? offer.totalDuration : null);
    final arrivalDays = dayOffset(primary.departure?.time, last.arrival?.time);

    final perPerson = offer.price.pricePerAdult > 0 ? offer.price.pricePerAdult : offer.price.total;

    final policy = offer.farePolicy;
    final refundable = policy?.isRefundable ?? offer.refundable;
    final penalty = policy?.refundPenaltyAmount;
    final refundLabel = !refundable
        ? t.flights_card_nonRefundable
        : penalty == 0
        ? t.flights_card_freeCancellation
        : penalty != null && penalty > 0
        ? 'Refundable (est. fee: ${widget.money(penalty, policy?.refundPenaltyCurrency ?? 'USD')})'
        : AppLocalizations.of(context)!.checkout_flight_receipt_refundable;
    final bag = offer.baggage;
    final bagsLine = bag == null
        ? null
        : [
            if (bag.cabinBag != null) bag.cabinBag! ? '1 carry-on' : 'No carry-on',
            bag.checkedBags > 0 ? '${bag.checkedBags} checked' : AppLocalizations.of(context)!.checkout_flight_summary_noCheckedBag,
          ].join(' · ');

    final timeStyle = TextStyle(
      fontSize: 20,
      height: 1,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: skin.title,
    );
    final codeStyle = TextStyle(fontSize: 11, letterSpacing: 0.44, color: skin.muted);

    return Container(
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: skin.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── The airline's line ──
                Row(
                  children: [
                    AirlineBadge(code: primary.airline, name: primary.airlineName, size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            primary.airlineName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 15, height: 1.2, fontWeight: FontWeight.w700, color: skin.title),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${primary.flightNumber}${offer.segments.length > 1 ? ' + ${offer.segments.length - 1} more' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: skin.muted),
                          ),
                        ],
                      ),
                    ),
                    if (widget.highlight != null) ...[
                      const SizedBox(width: 10),
                      _HighlightBadge(
                        kind: widget.highlight!,
                        label: widget.highlight == OfferHighlight.cheapest
                            ? t.flights_filters_cheapest
                            : t.flights_filters_fastest,
                      ),
                    ],
                  ],
                ),

                // ── Times ──
                const SizedBox(height: 12),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formatTime(primary.departure?.time), style: timeStyle),
                        const SizedBox(height: 4),
                        Text(primary.origin, style: codeStyle),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          Text(formatDuration(minutes), style: TextStyle(fontSize: 11, color: skin.text)),
                          const SizedBox(height: 4),
                          RouteLine(stops: stops),
                          const SizedBox(height: 4),
                          Text(stopsLabel(stops), style: TextStyle(fontSize: 12, color: skin.muted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text.rich(
                          TextSpan(
                            text: formatTime(last.arrival?.time),
                            children: [
                              if (arrivalDays > 0)
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.top,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 2),
                                    child: Text(
                                      '+$arrivalDays',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: skin.muted),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          style: timeStyle,
                        ),
                        const SizedBox(height: 4),
                        Text(last.destination, style: codeStyle),
                      ],
                    ),
                  ],
                ),

                // ── The fare's facts: refund terms and bags, as two chips ──
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _FactChip(
                      label: refundLabel,
                      color: refundable
                          ? (skin == FlightSkin.dark ? TwPalette.emerald400 : TwPalette.emerald600)
                          : (skin == FlightSkin.dark ? TwPalette.slate300 : TwPalette.slate600),
                    ),
                    if (bagsLine != null)
                      _FactChip(
                        label: bagsLine,
                        color: skin == FlightSkin.dark ? TwPalette.slate300 : TwPalette.slate600,
                      ),
                  ],
                ),

                // ── The price, over a rule, with Select beside it ──
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: skin.hairline)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.money(perPerson, offer.price.currency),
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 20,
                                height: 1.25,
                                fontWeight: FontWeight.w700,
                                color: skin.title,
                              ),
                            ),
                            const SizedBox(height: 2),
                            GestureDetector(
                              onTap: () => setState(() => _expanded = !_expanded),
                              child: Text(
                                t.flights_card_flightDetails,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: skin == FlightSkin.dark ? TwPalette.blue400 : TwPalette.blue600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GradientPill(
                        label: widget.checkingPrice ? 'Checking price…' : t.flights_card_select,
                        busy: false,
                        onTap: widget.checkingPrice ? null : () => widget.onSelect(offer),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Expanded: the fare options, then the itinerary ──
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: const Cubic(0.04, 0.62, 0.23, 0.98),
            alignment: Alignment.topCenter,
            child: !_expanded
                ? const SizedBox(width: double.infinity)
                : Container(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: skin.hairline)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (offer.alternatives.isNotEmpty)
                          _FareOptions(offer: offer, money: widget.money, onSelect: widget.onSelect),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                          child: FlightItinerary(segments: offer.segments, sliceDurations: offer.sliceDurations),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// The airline's logo in a white disc — pics.avs.io's square edition, the two-letter code
/// holding the disc until the image lands and staying if it never does.
class AirlineBadge extends StatelessWidget {
  const AirlineBadge({required this.code, required this.name, this.size = 32, super.key});

  final String code;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final iata = code.toUpperCase().substring(0, math.min(3, code.length));
    final fallback = Text(
      iata.isNotEmpty ? iata : name.substring(0, math.min(2, name.length)).toUpperCase(),
      style: TextStyle(
        fontSize: size * 0.32,
        fontWeight: FontWeight.w700,
        color: TwPalette.slate700,
        letterSpacing: 0.4,
      ),
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x0D000000)),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      child: iata.isEmpty
          ? fallback
          : Image.network(
              'https://pics.avs.io/200/200/$iata.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
              semanticLabel: name,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? Padding(padding: const EdgeInsets.all(4), child: child) : fallback,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}

/// The line between departure and arrival: a glowing streak of the brand gradient, a dot at
/// its middle for a connection, and the plane waiting at the departure end — V2's resting
/// state; it flies only under a hovering pointer, which a phone does not have.
class RouteLine extends StatelessWidget {
  const RouteLine({required this.stops, super.key});

  final int stops;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  TwPalette.blue500.withValues(alpha: 0.4),
                  TwPalette.cyan400.withValues(alpha: 0.7),
                  TwPalette.blue500.withValues(alpha: 0.4),
                ],
              ),
              boxShadow: [
                BoxShadow(color: dark ? const Color(0x8C22D3EE) : const Color(0x592563EB), blurRadius: dark ? 8 : 6),
              ],
            ),
          ),
          if (stops > 0)
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: FlightSkin.gradient),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Icon(
                LucideIcons.plane,
                size: 14,
                color: dark ? TwPalette.cyan300 : TwPalette.blue600,
                shadows: [
                  Shadow(color: dark ? const Color(0xE622D3EE) : const Color(0xB32563EB), blurRadius: dark ? 5 : 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightBadge extends StatelessWidget {
  const _HighlightBadge({required this.kind, required this.label});

  final OfferHighlight kind;
  final String label;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = kind == OfferHighlight.cheapest ? TwPalette.emerald500 : TwPalette.blue500;
    final text = switch ((kind, dark)) {
      (OfferHighlight.cheapest, false) => TwPalette.emerald700,
      (OfferHighlight.cheapest, true) => TwPalette.emerald300,
      (OfferHighlight.fastest, false) => TwPalette.blue700,
      (OfferHighlight.fastest, true) => TwPalette.blue300,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.1),
        border: Border.all(color: base.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 10, height: 1, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: text),
      ),
    );
  }
}

class _FactChip extends StatelessWidget {
  const _FactChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final skin = FlightSkin.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: skin.chip, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 12, color: color)),
    );
  }
}

/// "Available Fare Options": the offer itself, marked selected, and each alternative brand.
class _FareOptions extends StatelessWidget {
  const _FareOptions({required this.offer, required this.money, required this.onSelect});

  final FlightFare offer;
  final MoneyFormatter money;
  final ValueChanged<FlightFare> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final skin = FlightSkin.of(context);

    Widget option(FlightFare o, {required bool current}) {
      final name = o.brandedFare?.label ?? (current ? 'Standard' : 'Option');
      final cabin = o.segments.isEmpty ? 'economy' : o.segments.first.cabinClass;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: current ? TwPalette.blue500 : skin.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(name.toUpperCase(), style: TextStyle(fontSize: 12, color: skin.text)),
                ),
                Text(
                  money(o.price.total, o.price.currency),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: skin.title),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              current ? t.mobile_flights_bestValue(cabinLabel(cabin)) : cabinLabel(cabin),
              style: TextStyle(fontSize: 12, color: skin.muted),
            ),
            const SizedBox(height: 8),
            current
                ? Opacity(
                    opacity: 0.5,
                    child: GradientPill(
                      label: t.flights_card_currentlySelected,
                      onTap: null,
                      height: 32,
                      radius: 999,
                      fontSize: 12,
                    ),
                  )
                : Material(
                    color: skin.chip,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => onSelect(o),
                      child: SizedBox(
                        height: 32,
                        child: Center(
                          child: Text(
                            t.mobile_flights_selectFare(o.brandedFare?.label ?? t.mobile_flights_thisFare),
                            style: TextStyle(fontSize: 12, color: skin.text),
                          ),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: skin.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.badgeDollarSign, size: 14, color: skin.muted),
              const SizedBox(width: 6),
              Text(
                t.flights_card_fareOptions.toUpperCase(),
                style: TextStyle(fontSize: 12, letterSpacing: 1.56, color: skin.muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          option(offer, current: true),
          for (final alt in offer.alternatives) option(alt, current: false),
        ],
      ),
    );
  }
}

/// The card's own shape while the search runs, so nothing moves when results land.
class FlightCardSkeleton extends StatefulWidget {
  const FlightCardSkeleton({super.key});

  @override
  State<FlightCardSkeleton> createState() => _FlightCardSkeletonState();
}

class _FlightCardSkeletonState extends State<FlightCardSkeleton> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = FlightSkin.of(context);
    final fill = skin == FlightSkin.dark ? const Color(0x1AFFFFFF) : TwPalette.slate200;
    Widget bar(double w, double h, {double r = 4}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(r)),
    );

    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.5).animate(_pulse),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: skin.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: skin.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                bar(32, 32, r: 16),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [bar(96, 16), const SizedBox(height: 6), bar(56, 12)],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                bar(56, 20),
                const SizedBox(width: 12),
                Expanded(child: Container(height: 1, color: fill)),
                const SizedBox(width: 12),
                bar(56, 20),
              ],
            ),
            const SizedBox(height: 20),
            Row(children: [bar(112, 24, r: 12), const SizedBox(width: 6), bar(144, 24, r: 12)]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.only(top: 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: skin.hairline)),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [bar(64, 24), const SizedBox(height: 6), bar(80, 12)],
                  ),
                  const Spacer(),
                  bar(84, 44, r: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

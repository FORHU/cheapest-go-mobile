import 'package:flutter/material.dart';

import 'package:cheapest_go_mobile/features/hotels/components/stay_chrome.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/utils/currency.dart';
import 'package:cheapest_go_mobile/shared/utils/money.dart';

/// One stay on the rail, as V2's search page draws it at its phone size. See #39.
///
/// A landscape plate: the photograph fills the left edge over the card's whole height, the
/// name and address stack against it, and the baseline carries the price over the rating with
/// the View pill opposite.
///
/// What this replaced: a portrait card with the price in a circle straddling the picture. That
/// is V2's *old* card — `features/search/components/rail-card.tsx`, which the search page no
/// longer imports: it defines its own `RailCard` and renders that one. Porting the extracted
/// component because it had the tidier name is how this app ended up a design behind.
///
/// The geometry is V2's phone set, `CARD_GEOM_MOBILE`, and needs no conversion: that artboard
/// and its drawn width are both 340, so the numbers are already logical pixels.

/// `CARD_W_MOBILE`, capped by the window. The card stops short on both sides so the next one
/// shows at the edge and the strip reads as something to swipe.
const double railCardMaxWidth = 258;

/// `RAIL_GUTTER_MOBILE`.
const double railGutter = 20;

/// Every card stands the same height, as V2's rail measures one and matches the rest to it.
/// `minH` is 96 there; the two-line address and the baseline row carry it past that.
const double railCardHeight = 110;

/// `SELECT_SCALE`. The chosen card grows up into the map, which is how a pin shows which card
/// it landed on.
const double _selectScale = 1.08;

const double _photoWidth = 74;
const double _padX = 11;
const double _padY = 9;

class StayRailCard extends StatelessWidget {
    const StayRailCard({
        required this.hotel,
        required this.currency,
        required this.onSelect,
        required this.onView,
        this.selected = false,
        super.key,
    });

    final Hotel hotel;

    /// What a person reads prices in, not what the stay is quoted in.
    final String currency;
    final VoidCallback onSelect;
    final VoidCallback onView;
    final bool selected;

    /// Free cancellation, which V2 flags in the photograph's corner. V2 reads a supplier's
    /// `RFN`; the catalog says the same thing in words on the room.
    bool get _refundable =>
        hotel.rooms.any((r) => (r.cancellation ?? '').toLowerCase().contains('free'));

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;
        final skin = StaySkin.of(context);
        final photo = hotel.photos.isEmpty ? null : hotel.photos.first;
        final shown = exchangeRates.convertForDisplay(hotel.fromRate, hotel.currency, currency);
        final width = (MediaQuery.sizeOf(context).width - railGutter * 2)
            .clamp(0.0, railCardMaxWidth);

        return AnimatedScale(
            scale: selected ? _selectScale : 1,
            alignment: Alignment.bottomCenter,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: GestureDetector(
                onTap: onSelect,
                child: SizedBox(
                    width: width,
                    height: railCardHeight,
                    child: Material(
                        color: skin.surface,
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                                _Photo(photo: photo, skin: skin, refundable: _refundable, t: t),
                                Expanded(
                                    child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: _padX,
                                            vertical: _padY,
                                        ),
                                        child: _Panel(
                                            hotel: hotel,
                                            skin: skin,
                                            price: '${formatMoney(shown.amount, shown.currency)}/night',
                                            onView: onView,
                                        ),
                                    ),
                                ),
                            ],
                        ),
                    ),
                ),
            ),
        );
    }
}

class _Photo extends StatelessWidget {
    const _Photo({required this.photo, required this.skin, required this.refundable, required this.t});

    final String? photo;
    final StaySkin skin;
    final bool refundable;
    final AppLocalizations t;

    @override
    Widget build(BuildContext context) {
        return SizedBox(
            width: _photoWidth,
            child: Stack(
                fit: StackFit.expand,
                children: [
                    ColoredBox(
                        color: skin.imageBg,
                        child: photo == null
                            ? Icon(Icons.apartment_rounded, size: 26, color: skin.muted)
                            : Image.network(
                                photo!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    Icon(Icons.apartment_rounded, size: 26, color: skin.muted),
                            ),
                    ),
                    if (refundable)
                        Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    // V2's green, stated rather than taken from the palette: it
                                    // marks a supplier's term, not a state of the app.
                                    color: const Color(0xFF2FB67F),
                                    borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                    t.search_freeCancel,
                                    style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                    ),
                                ),
                            ),
                        ),
                ],
            ),
        );
    }
}

class _Panel extends StatelessWidget {
    const _Panel({
        required this.hotel,
        required this.skin,
        required this.price,
        required this.onView,
    });

    final Hotel hotel;
    final StaySkin skin;
    final String price;
    final VoidCallback onView;

    /// Where it is, and how far that is from what was asked for.
    ///
    /// The distance is only ever the one api-v2 sent: it sends one when a stay is far for the
    /// rung a person searched — a city above 15 km, a district above 5 — so a card without one
    /// is a central stay rather than a field that failed to load. Working a distance out here
    /// would put a line on every card that V2 shows on few. See ADR-0051 in the web repo.
    String get _where {
        final place = (hotel.address?.isNotEmpty ?? false) ? hotel.address! : hotel.area;
        final far = hotel.anchorDistanceKm;
        if (far == null || far <= 0) return place.isEmpty ? ' ' : place;
        final n = far < 10 ? far.toStringAsFixed(1) : far.round().toString();
        return '$place · $n km from ${hotel.area}';
    }

    @override
    Widget build(BuildContext context) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(
                    hotel.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: skin.title,
                    ),
                ),
                const SizedBox(height: 3),
                SizedBox(
                    // Two lines, held open whether or not there are two to show: rendered to
                    // fit, a stay with a short address came out shorter than its neighbours
                    // and the rail's baseline went ragged.
                    height: 11 * 1.35 * 2,
                    child: Text(
                        _where,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, height: 1.35, color: skin.muted),
                    ),
                ),
                const Spacer(),
                Row(
                    children: [
                        Flexible(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    Text(
                                        price,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 12.5,
                                            height: 1.3,
                                            fontWeight: FontWeight.w700,
                                            color: skin.title,
                                        ),
                                    ),
                                    Text(
                                        hotel.score > 0 ? '${hotel.score.toStringAsFixed(1)} rating' : ' ',
                                        maxLines: 1,
                                        style: TextStyle(fontSize: 11, height: 1.35, color: skin.muted),
                                    ),
                                ],
                            ),
                        ),
                        const SizedBox(width: 10),
                        Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(100),
                            child: InkWell(
                                onTap: onView,
                                borderRadius: BorderRadius.circular(100),
                                child: Ink(
                                    decoration: BoxDecoration(
                                        // The brand gradient, as V2's own palette gives it:
                                        // this button and the price chip are the only two
                                        // things on the card that wear it.
                                        gradient: StaySkin.chipGradient,
                                        borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                    // "View", not "View Stay": V2 shortens it on a phone, where
                                    // a peso amount runs to thirteen characters and the price
                                    // is the half that cannot be abbreviated. It is a literal
                                    // in `CARD_GEOM_MOBILE` there, so it is one here rather
                                    // than a phone-only entry in the shared copy.
                                        child: Text(
                                            'View',
                                            style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: skin.chipText,
                                            ),
                                        ),
                                    ),
                                ),
                            ),
                        ),
                    ],
                ),
            ],
        );
    }
}

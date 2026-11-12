import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cheapest_go_mobile/features/hotels/components/guest_reviews.dart';
import 'package:cheapest_go_mobile/features/hotels/components/nearby_explorer.dart';
import 'package:cheapest_go_mobile/features/hotels/components/property_description.dart';
import 'package:cheapest_go_mobile/features/hotels/components/property_hero.dart';
import 'package:cheapest_go_mobile/features/hotels/components/room_selection.dart';
import 'package:cheapest_go_mobile/features/hotels/components/stay_chrome.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/components/ui_kit.dart';
import 'package:cheapest_go_mobile/shared/stores/trip_search_store.dart';
import 'package:cheapest_go_mobile/shared/stores/ui_store.dart';
import 'package:cheapest_go_mobile/shared/utils/currency.dart';
import 'package:cheapest_go_mobile/shared/utils/format.dart';
import 'package:cheapest_go_mobile/shared/utils/money.dart';

/// One property, as V2's `/property/[id]` shows it. See #40.
///
/// The sections run in V2's order — the photographs, what the place is, the rooms and their
/// terms, then what guests said — with the chosen Offer carried on a bar that stays in view.
///
/// What this replaced: a single flat list of "rooms" that was really one row per price, with
/// the cheapest silently selected. A traveller could not see that the refundable rate existed,
/// which is the failure ADR-0007 in the web repo was written about.
class HotelDetailView extends StatefulWidget {
    const HotelDetailView({required this.hotelId, this.catalog = travelCatalog, super.key});

    final String hotelId;
    final TravelCatalog catalog;

    @override
    State<HotelDetailView> createState() => _HotelDetailViewState();
}

class _HotelDetailViewState extends State<HotelDetailView> {
    /// The Offer a traveller picked. Null until the rooms arrive, then the cheapest — which
    /// is what the card headlines, so the bar and the card agree from the first frame.
    String? _offerId;
    bool _loading = true;

    @override
    void initState() {
        super.initState();
        final s = tripSearchStore;
        exchangeRates.refresh();
        widget.catalog
            .fetchHotel(widget.hotelId, checkIn: s.checkIn, checkOut: s.checkOut, adults: s.adults)
            .then((_) {
                if (mounted) setState(() => _loading = false);
            })
            .catchError((_) {
                if (mounted) setState(() => _loading = false);
            });
    }

    /// Every Offer on the property, cheapest first — the order the rooms arrive in.
    List<Offer> _offersOf(Hotel hotel) => [
        for (final room in hotel.rooms) ...room.buyableOffers,
    ];

    Offer? _selected(Hotel hotel) {
        final offers = _offersOf(hotel);
        if (offers.isEmpty) return null;
        return offers.firstWhere(
            (o) => o.offerId == _offerId,
            orElse: () => offers.reduce((a, b) => a.nightlyRate <= b.nightlyRate ? a : b),
        );
    }

    @override
    Widget build(BuildContext context) {
        final hotel = widget.catalog.hotel(widget.hotelId);
        final skin = StaySkin.of(context);

        if (hotel == null) {
            return Scaffold(
                appBar: AppBar(),
                body: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : const EmptyState(
                        icon: Icons.hotel_outlined,
                        title: 'Hotel not found',
                        message: 'It may have been removed.',
                    ),
            );
        }

        return ListenableBuilder(
            listenable: Listenable.merge([tripSearchStore, uiSettingsStore, exchangeRates]),
            builder: (context, _) {
                final currency = uiSettingsStore.displayCurrency;
                final selected = _selected(hotel);
                final reviews = widget.catalog.reviewsFor(hotel.id);

                return Scaffold(
                    backgroundColor: skin.surface,
                    body: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                            PropertyHero(
                                hotel: hotel,
                                onBack: () => context.canPop() ? context.pop() : context.go('/'),
                                onToggleTheme: () => uiSettingsStore.setThemeMode(
                                    Theme.of(context).brightness == Brightness.dark
                                        ? ThemeMode.light
                                        : ThemeMode.dark,
                                ),
                            ),
                            PropertyDescription(hotel: hotel, currency: currency),
                            const SizedBox(height: 28),
                            if (_loading && hotel.rooms.isEmpty)
                                const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 40),
                                    child: Center(child: CircularProgressIndicator()),
                                )
                            else
                                RoomSelection(
                                    rooms: hotel.rooms,
                                    currency: currency,
                                    selectedOfferId: selected?.offerId,
                                    onSelect: (offer) => setState(() => _offerId = offer.offerId),
                                    // A supplier that owns its content sends no room
                                    // galleries, so the building stands in — V2 passes the
                                    // same photograph as its `galleryFallback`.
                                    fallbackPhoto: hotel.photos.isEmpty ? null : hotel.photos.first,
                                ),
                            // V2's order: the rooms, then what is around them, then what guests
                            // said. The explorer removes itself where the endpoint has
                            // nothing (or no Places key) to answer with.
                            if (hotel.latitude != null && hotel.longitude != null)
                                NearbyExplorer(
                                    latitude: hotel.latitude!,
                                    longitude: hotel.longitude!,
                                ),
                            GuestReviews(
                                reviews: reviews,
                                score: hotel.score,
                                count: hotel.reviews,
                            ),
                            // Clear of the bar, which floats over the foot of the page.
                            const SizedBox(height: 120),
                        ],
                    ),
                    bottomNavigationBar: selected == null
                        ? null
                        : _CheckoutBar(
                            offer: selected,
                            currency: currency,
                            nights: tripSearchStore.nights,
                            onReserve: () => context.push(
                                '/checkout?hotel=${hotel.id}&room=${selected.offerId}',
                            ),
                        ),
                );
            },
        );
    }
}

/// What the chosen Offer costs, and the way to book it.
///
/// The stay total comes from the Offer rather than from multiplying its nightly rate: api-v2
/// sends both because a rounded nightly figure multiplied back up is not what gets billed.
class _CheckoutBar extends StatelessWidget {
    const _CheckoutBar({
        required this.offer,
        required this.currency,
        required this.nights,
        required this.onReserve,
    });

    final Offer offer;
    final String currency;
    final int nights;
    final VoidCallback onReserve;

    @override
    Widget build(BuildContext context) {
        final skin = StaySkin.of(context);
        final shown = exchangeRates.convertForDisplay(offer.stayTotal, offer.currency, currency);

        return Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.viewPaddingOf(context).bottom),
            decoration: BoxDecoration(
                color: skin.surface,
                border: Border(top: BorderSide(color: skin.hairline)),
                boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, -6))],
            ),
            child: Row(
                children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                Text(
                                    formatMoney(shown.amount, shown.currency),
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: skin.title),
                                ),
                                Text(
                                    '${plural(nights, 'night')} · ${offer.boardName}'
                                    '${offer.refundable ? ' · free cancellation' : ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, color: skin.muted),
                                ),
                            ],
                        ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                            onTap: onReserve,
                            borderRadius: BorderRadius.circular(999),
                            child: Ink(
                                decoration: BoxDecoration(
                                    gradient: StaySkin.chipGradient,
                                    borderRadius: BorderRadius.circular(999),
                                ),
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                                    child: Text(
                                        AppLocalizations.of(context)!.property_rooms_reserve,
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                        ),
                                    ),
                                ),
                            ),
                        ),
                    ),
                ],
            ),
        );
    }
}

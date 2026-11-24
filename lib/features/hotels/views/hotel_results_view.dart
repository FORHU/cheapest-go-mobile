import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cheapest_go_mobile/features/hotels/components/stay_chrome.dart';
import 'package:cheapest_go_mobile/features/hotels/components/stay_filters_sheet.dart';
import 'package:cheapest_go_mobile/features/hotels/components/stay_list_card.dart';
import 'package:cheapest_go_mobile/features/hotels/components/stay_map.dart';
import 'package:cheapest_go_mobile/features/hotels/components/stay_map_card.dart';
import 'package:cheapest_go_mobile/features/hotels/components/stay_status.dart';
import 'package:cheapest_go_mobile/features/hotels/components/stay_top_bar.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/tips/tip_anchor.dart';
import 'package:cheapest_go_mobile/shared/tips/tip_overlay.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/stores/trip_search_store.dart';
import 'package:cheapest_go_mobile/shared/stores/ui_store.dart';
import 'package:cheapest_go_mobile/shared/utils/currency.dart';
import 'package:cheapest_go_mobile/shared/utils/format.dart';

/// The stays a search found, as V2's `/search` shows them. See #39.
///
/// A map, with the results standing on it and a rail of cards along the bottom — not a list
/// with a map behind a tab. V2 chose that because where a stay is answers most of what a
/// person is deciding, and the mobile port keeps it.
///
/// What this replaced: a list of stays near the searched *arrival airport*, ordered by
/// distance to a terminal. That was v1's question. V2 asks about a destination, and a
/// destination has no terminal to be near.
class HotelResultsView extends StatefulWidget {
    const HotelResultsView({this.catalog = travelCatalog, this.showBack = true, super.key});

    final TravelCatalog catalog;

    /// False when shown inside a tab rather than opened as a page.
    final bool showBack;

    @override
    State<HotelResultsView> createState() => _HotelResultsViewState();
}

class _HotelResultsViewState extends State<HotelResultsView> {
    StayFilters _filters = const StayFilters();
    bool _mapView = true;
    /// The **Stay Card**'s own state. The map draws the card (ADR-0008), so this screen's part
    /// is to say which stay it stands for and to let the map have it.
    late final _card = StayCardModel(catalog: widget.catalog);
    bool _loading = false;
    bool _failed = false;
    String? _selectedId;


    String? _lastLoadedCode;
    DateTime? _lastCheckIn;
    DateTime? _lastCheckOut;
    int? _lastAdults;

    @override
    void initState() {
        super.initState();
        _fetchIfNeeded();
        // Prices may not be shown in the currency a person chose until the rates are known,
        // so ask for them as the screen opens rather than when something first needs one.
        exchangeRates.refresh();
    }

    @override
    void dispose() {
        _card.dispose();
        super.dispose();
    }

    void _fetchIfNeeded({bool force = false}) {
        final s = tripSearchStore;
        if (!force &&
            _lastLoadedCode == _searchKey &&
            _lastCheckIn == s.checkIn &&
            _lastCheckOut == s.checkOut &&
            _lastAdults == s.adults) {
            return;
        }
        _lastLoadedCode = _searchKey;
        _lastCheckIn = s.checkIn;
        _lastCheckOut = s.checkOut;
        _lastAdults = s.adults;

        if (widget.catalog.hotelsNear(_searchKey).isEmpty && mounted) {
            setState(() {
                _loading = true;
                _failed = false;
            });
        }
        widget.catalog
            .fetchHotels(
                s.airportCode,
                checkIn: s.checkIn,
                checkOut: s.checkOut,
                adults: s.adults,
                at: s.destination,
            )
            .then((_) {
                if (mounted) setState(() => _loading = false);
            })
            .catchError((_) {
                // Asked and could not be told, which is a different answer from "none here".
                if (mounted) {
                    setState(() {
                        _loading = false;
                        _failed = true;
                    });
                }
            });
    }

    /// Which search these results belong to: the destination a person chose, or the airport
    /// when they have not chosen one. A city suggestion carries no IATA code, so keying on the
    /// airport would answer Seoul with Manila.
    String get _searchKey => tripSearchStore.destination?.id ?? tripSearchStore.airportCode;

    List<Hotel> get _all => widget.catalog.hotelsNear(_searchKey);

    double get _priceFloor =>
        _all.isEmpty ? 0 : _all.map((h) => h.fromRate.toDouble()).reduce((a, b) => a < b ? a : b);

    double get _priceCeiling =>
        _all.isEmpty ? 0 : _all.map((h) => h.fromRate.toDouble()).reduce((a, b) => a > b ? a : b);

    List<Hotel> _apply(StayFilters f) {
        final list = _all.where((h) {
            // The catalog scores stays out of ten and V2 filters by stars out of five, so a
            // score is halved to be compared — not rounded first, or a 7.9 would miss four
            // stars by a tenth it was never measured to.
            if (f.stars.isNotEmpty && !f.stars.contains((h.score / 2).ceil().clamp(1, 5))) return false;
            if (h.fromRate < f.minPrice || h.fromRate > f.maxPrice) return false;
            return true;
        }).toList();

        switch (f.sort) {
            case StaySort.recommended:
                // V2 leaves the supplier's order alone for this one: it is the order the
                // results arrived in, not an order computed here.
                break;
            case StaySort.priceLow:
                list.sort((a, b) => a.fromRate.compareTo(b.fromRate));
            case StaySort.priceHigh:
                list.sort((a, b) => b.fromRate.compareTo(a.fromRate));
            case StaySort.rating:
                list.sort((a, b) => b.score.compareTo(a.score));
            case StaySort.mostReviewed:
                list.sort((a, b) => b.reviews.compareTo(a.reviews));
        }
        return list;
    }

    Future<void> _openFilters() async {
        final chosen = await showModalBottomSheet<StayFilters>(
            context: context,
            isScrollControlled: true,
            showDragHandle: false,
            builder: (_) => StayFiltersSheet(
                filters: _filters,
                priceFloor: _priceFloor,
                priceCeiling: _priceCeiling,
                matching: (f) => _apply(f).length,
            ),
        );
        if (chosen != null && mounted) setState(() => _filters = chosen);
    }

    /// A pin was pressed.
    ///
    /// Pressing the pin of the stay already showing opens it, rather than closing the card.
    /// That is the client's own wording — "if clicked again will route to the property page"
    /// — and it is the one place this screen deliberately parts from V2, where a second click
    /// toggles the popup shut (`search/page.tsx:1060`). The map tap below is what dismisses,
    /// so nothing is unreachable.
    void _select(Hotel hotel) {
        if (_selectedId == hotel.id) {
            _openStay(hotel);
            return;
        }
        _card.show(hotel);
        setState(() => _selectedId = hotel.id);
    }

    void _dismiss() {
        if (_selectedId == null) return;
        _card.show(null);
        setState(() => _selectedId = null);
    }


    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;

        return ListenableBuilder(
            listenable: Listenable.merge([tripSearchStore, uiSettingsStore, exchangeRates]),
            builder: (context, _) {
                _fetchIfNeeded();
                final s = tripSearchStore;
                final shown = _apply(_filters);
                final currency = uiSettingsStore.displayCurrency;

                // The Tip waits for stays to actually be there: one over a spinner, describing
                // cards that have not arrived, teaches nothing. See #62 and ADR-0006.
                return TipScope(
                    tip: tipFor(t, TipAnchors.hotelResult),
                    ready: !_loading && shown.isNotEmpty,
                    child: Stack(
                    children: [
                        Positioned.fill(
                            child: _mapView
                                ? StayMap(
                                    hotels: shown,
                                    selectedId: _selectedId,
                                    currency: currency,
                                    card: _card,
                                    onSelect: _select,
                                    onOpen: _openStay,
                                    onMapTap: _dismiss,
                                    // What the search bar covers, so the map can ease a card
                                    // out from under it rather than drawing it there.
                                    topInset: MediaQuery.paddingOf(context).top + 120,
                                )
                                : _StayList(
                                    currency: currency,
                                    hotels: shown,
                                    onView: _openStay,
                                ),
                        ),

                        // Looking, or asked and not told. Over everything, as V2 covers the
                        // results surface rather than tucking a spinner into a corner.
                        if (_loading)
                            Positioned.fill(
                                child: StayStatus(
                                    busy: true,
                                    // V2's own wording, which does not name the place; the
                                    // toolbar above already says where the search is for.
                                    title: t.landing_search_searchingStays,
                                    lines: [t.mobile_hotels_searchingPrices],
                                ),
                            )
                        // A search that could not be made and one that found nothing are
                        // different answers, and used to read identically (#73). "We couldn't
                        // find hotels" under a supplier outage tells someone the city is full
                        // when nobody ever asked it.
                        else if (_failed)
                            Positioned.fill(
                                child: StayStatus(
                                    title: t.errors_generic,
                                    lines: [t.mobile_hotels_partnersUnreachable],
                                    actionLabel: t.auth_tryAgain,
                                    action: () => _fetchIfNeeded(force: true),
                                ),
                            )
                        else if (shown.isEmpty)
                            Positioned.fill(
                                child: StayStatus(
                                    title: t.search_v2_noAccommodations,
                                    lines: [
                                        t.mobile_hotels_noneFoundIn(s.destinationLabel),
                                        if (_filters.narrowedWithin(_priceFloor, _priceCeiling))
                                            t.hotels_filters_clear,
                                    ],
                                    actionLabel: t.search_results_whereTo,
                                    action: () => context.go('/'),
                                ),
                            ),

                        Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: SafeArea(
                                bottom: false,
                                child: StayTopBar(
                                    query: s.destinationLabel,
                                    // V2's StayEditor label: the nights and who is coming, as
                                    // one control for the two questions the landing asked.
                                    dateLabel: '${formatDateRange(s.checkIn, s.checkOut)}'
                                        ' · ${t.property_bookingWidget_guests(s.adults)}',
                                    mapView: _mapView,
                                    showBack: widget.showBack,
                                    filtersActive: _filters.narrowedWithin(_priceFloor, _priceCeiling),
                                    onBack: () => context.canPop() ? context.pop() : context.go('/'),
                                    onEditSearch: () => context.go('/'),
                                    onEditDates: () => context.go('/'),
                                    onFilters: _openFilters,
                                    onToggleTheme: () => uiSettingsStore.setThemeMode(
                                        Theme.of(context).brightness == Brightness.dark
                                            ? ThemeMode.light
                                            : ThemeMode.dark,
                                    ),
                                    onToggleView: () => setState(() => _mapView = !_mapView),
                                ),
                            ),
                        ),

                        // How many stays the map is showing. Was the rail's header; now its own
                        // plate, bottom left, where V2 puts it too — the rail itself is gone
                        // and the one card left is drawn by the map. See ADR-0008.
                        //
                        // It also carries this screen's Tip. The Tip used to point at the
                        // rail's first card, which left it pointing at nothing once the rail
                        // went, and a painted card cannot hold it either. This plate is on the
                        // screen whether or not a card is open. See ADR-0006.
                        if (_mapView && !_loading)
                            Positioned(
                                left: mapGutter,
                                bottom: mapGutter,
                                child: TipAnchor(
                                    id: TipAnchors.hotelResult,
                                    child: _Pill(
                                        skin: StaySkin.of(context),
                                        child: Text(
                                            t.search_v2_staysCount(shown.length),
                                            style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                                color: StaySkin.of(context).title,
                                            ),
                                        ),
                                    ),
                                ),
                            ),
                    ],
                ),
                );
            },
        );
    }

    /// The property page is `/hotel/:id` — singular, as every other caller has it. Pushing
    /// `/hotels/<id>` landed on the router's not-found page, and nothing caught it because
    /// no test followed a result card through to the property.
    void _openStay(Hotel hotel) => context.push('/hotel/${hotel.id}');
}

/// The count, the handle that puts the cards away, and the cards themselves.
class _StayList extends StatelessWidget {
    const _StayList({required this.hotels, required this.currency, required this.onView});

    final List<Hotel> hotels;
    final String currency;
    final ValueChanged<Hotel> onView;

    @override
    Widget build(BuildContext context) {
        return ColoredBox(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF0B1222)
                : const Color(0xFFF1F5F9),
            child: ListView.separated(
                // Clear of the toolbar floating above it.
                padding: const EdgeInsets.fromLTRB(16, 150, 16, 24),
                itemCount: hotels.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                    final card = StayListCard(
                        hotel: hotels[i],
                        currency: currency,
                        onOpen: () => onView(hotels[i]),
                    );
                    // The first card is what the Tip points at — the one a newcomer reads to
                    // learn what a price on this screen means. See #62.
                    return i == 0
                        ? TipAnchor(id: TipAnchors.hotelResult, child: card)
                        : card;
                },
            ),
        );
    }
}

/// The small rounded plate the stay count sits on, over the map.
///
/// It used to be part of the rail's header, which is why removing the rail took the count
/// with it — the client asked for the strip of cards gone, not for the screen to stop saying
/// how many stays it found. Now placed on its own, where V2 also has it.
class _Pill extends StatelessWidget {
    const _Pill({required this.child, required this.skin});

    final Widget child;
    final StaySkin skin;

    @override
    Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: skin.surface,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [BoxShadow(color: Color(0x24000000), blurRadius: 12, offset: Offset(0, 3))],
        ),
        child: child,
    );
}

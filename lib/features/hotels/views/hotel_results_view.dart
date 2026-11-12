import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cheapest_go_mobile/features/hotels/components/stay_chrome.dart';
import 'package:cheapest_go_mobile/features/hotels/components/stay_filters_sheet.dart';
import 'package:cheapest_go_mobile/features/hotels/components/stay_list_card.dart';
import 'package:cheapest_go_mobile/features/hotels/components/stay_map.dart';
import 'package:cheapest_go_mobile/features/hotels/components/stay_rail_card.dart';
import 'package:cheapest_go_mobile/features/hotels/components/stay_status.dart';
import 'package:cheapest_go_mobile/features/hotels/components/stay_top_bar.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
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
    bool _railHidden = false;
    bool _loading = false;
    bool _failed = false;
    String? _selectedId;

    final _rail = ScrollController();

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
        _rail.dispose();
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

    /// One card plus the gap between two.
    double _cardStep(BuildContext context) =>
        (MediaQuery.sizeOf(context).width - railGutter * 2).clamp(0.0, railCardMaxWidth) + 12;

    void _select(Hotel hotel, List<Hotel> shown) {
        setState(() {
            _selectedId = hotel.id;
            _railHidden = false;
        });
        final index = shown.indexWhere((h) => h.id == hotel.id);
        if (index < 0 || !_rail.hasClients) return;
        _rail.animateTo(
            // One card plus the gap, which is what a step along this strip is.
            (index * (_cardStep(context))).clamp(0, _rail.position.maxScrollExtent),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
        );
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

                return Stack(
                    children: [
                        Positioned.fill(
                            child: _mapView
                                ? StayMap(
                                    hotels: shown,
                                    currency: currency,
                                    selectedId: _selectedId,
                                    onSelect: (h) => _select(h, shown),
                                )
                                : _StayList(
                                    hotels: shown,
                                    currency: currency,
                                    onView: _openStay,
                                ),
                        ),

                        // Looking, or asked and not told. Over everything, as V2 covers the
                        // results surface rather than tucking a spinner into a corner.
                        if (_loading)
                            Positioned.fill(
                                child: StayStatus(
                                    busy: true,
                                    title: 'Finding Stays In ${s.destinationLabel}...',
                                    lines: const ['Searching for Availability and Prices'],
                                ),
                            )
                        else if (_failed || shown.isEmpty)
                            Positioned.fill(
                                child: StayStatus(
                                    title: t.search_v2_noAccommodations,
                                    lines: [
                                        'We couldn’t find hotels in ${s.destinationLabel}',
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
                                    currency: currency,
                                    mapView: _mapView,
                                    showBack: widget.showBack,
                                    filtersActive: _filters.narrowedWithin(_priceFloor, _priceCeiling),
                                    onBack: () => context.canPop() ? context.pop() : context.go('/'),
                                    onEditSearch: () => context.go('/'),
                                    onEditDates: () => context.go('/'),
                                    onFilters: _openFilters,
                                    onCurrency: uiSettingsStore.setDisplayCurrency,
                                    onToggleTheme: () => uiSettingsStore.setThemeMode(
                                        Theme.of(context).brightness == Brightness.dark
                                            ? ThemeMode.light
                                            : ThemeMode.dark,
                                    ),
                                    onToggleView: () => setState(() => _mapView = !_mapView),
                                ),
                            ),
                        ),

                        if (_mapView && shown.isNotEmpty && !_loading)
                            Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: _Rail(
                                    hotels: shown,
                                    currency: currency,
                                    controller: _rail,
                                    hidden: _railHidden,
                                    selectedId: _selectedId,
                                    onHiddenChanged: (v) => setState(() => _railHidden = v),
                                    onSelect: (h) => _select(h, shown),
                                    onView: _openStay,
                                ),
                            ),
                    ],
                );
            },
        );
    }

    void _openStay(Hotel hotel) => context.push('/hotels/${hotel.id}');
}

/// The count, the handle that puts the cards away, and the cards themselves.
class _Rail extends StatelessWidget {
    const _Rail({
        required this.hotels,
        required this.currency,
        required this.controller,
        required this.hidden,
        required this.selectedId,
        required this.onHiddenChanged,
        required this.onSelect,
        required this.onView,
    });

    final List<Hotel> hotels;
    final String currency;
    final ScrollController controller;
    final bool hidden;
    final String? selectedId;
    final ValueChanged<bool> onHiddenChanged;
    final ValueChanged<Hotel> onSelect;
    final ValueChanged<Hotel> onView;

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;
        final skin = StaySkin.of(context);

        return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(railGutter, 0, railGutter, 8),
                    child: Row(
                        children: [
                            _Pill(
                                skin: skin,
                                child: Text(
                                    t.search_v2_staysCount(hotels.length),
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: skin.title,
                                    ),
                                ),
                            ),
                            const Spacer(),
                            Tooltip(
                                message: hidden ? t.search_v2_hideStayCards : t.search_v2_hideCards,
                                child: GestureDetector(
                                    onTap: () => onHiddenChanged(!hidden),
                                    child: _Pill(
                                        skin: skin,
                                        child: Icon(
                                            hidden ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                            size: 18,
                                            color: skin.title,
                                        ),
                                    ),
                                ),
                            ),
                        ],
                    ),
                ),
                AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: hidden
                        ? const SizedBox(width: double.infinity)
                        : SizedBox(
                            // Headroom for the chosen card, which grows rather than being
                            // clipped by the strip it sits in.
                            // The card, the room it needs to grow into when chosen, and the
                            // gesture bar underneath.
                            height: railCardHeight * 1.08 + 20 + MediaQuery.viewPaddingOf(context).bottom,
                            child: ListView.separated(
                                controller: controller,
                                scrollDirection: Axis.horizontal,
                                // Clear of the gesture bar: the rail is docked to the very
                                // bottom, so without the inset the cards are cut by it.
                                padding: EdgeInsets.fromLTRB(
                                    railGutter, 10, railGutter,
                                    4 + MediaQuery.viewPaddingOf(context).bottom,
                                ),
                                itemCount: hotels.length,
                                separatorBuilder: (_, _) => const SizedBox(width: 12),
                                itemBuilder: (context, i) => Align(
                                    alignment: Alignment.bottomCenter,
                                    child: StayRailCard(
                                        hotel: hotels[i],
                                        currency: currency,
                                        selected: hotels[i].id == selectedId,
                                        onSelect: () => onSelect(hotels[i]),
                                        onView: () => onView(hotels[i]),
                                    ),
                                ),
                            ),
                        ),
                ),
            ],
        );
    }
}

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

/// The same stays without the map, for when a person would rather read them than place them.
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
                itemBuilder: (context, i) => StayListCard(
                    hotel: hotels[i],
                    currency: currency,
                    onOpen: () => onView(hotels[i]),
                ),
            ),
        );
    }
}

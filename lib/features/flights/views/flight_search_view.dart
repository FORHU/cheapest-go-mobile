import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:cheapest_go_mobile/features/flights/api/flights_api.dart';
import 'package:cheapest_go_mobile/features/flights/components/flight_card.dart';
import 'package:cheapest_go_mobile/features/flights/components/flight_chrome.dart';
import 'package:cheapest_go_mobile/features/flights/components/flight_filters_sheet.dart';
import 'package:cheapest_go_mobile/features/flights/components/flight_status.dart';
import 'package:cheapest_go_mobile/features/flights/components/flight_top_bar.dart';
import 'package:cheapest_go_mobile/features/flights/components/trip_sheet.dart';
import 'package:cheapest_go_mobile/features/flights/lib/filter_offers.dart';
import 'package:cheapest_go_mobile/features/flights/lib/flight_search_query.dart';
import 'package:cheapest_go_mobile/features/flights/lib/flight_utils.dart';
import 'package:cheapest_go_mobile/features/flights/models/flight_fare.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/tips/tip_anchor.dart';
import 'package:cheapest_go_mobile/shared/tips/tip_overlay.dart';
import 'package:cheapest_go_mobile/shared/errors/api_error.dart';
import 'package:cheapest_go_mobile/shared/stores/ui_store.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_palette.dart';
import 'package:cheapest_go_mobile/shared/utils/currency.dart';

enum _Status { loading, slow, success, empty, timeout, error }

/// V2's `/flights/search` at its phone size. See `flight-search-client.tsx`. (#47)
///
/// The toolbar stands in for the app header; under it, "Flights to …" with the count, then the
/// cards — or the screen that says why there are none. Every fare is the airline's, from
/// api-v2's Duffel search: there is no list of invented flights to fall back on.
///
/// Picking a fare checks it with the airline first. A fare that went up is a question; one that
/// went down is taken at the lower price; one that has gone sends the traveller back here to a
/// fresh search with a note saying why. Only then does checkout open.
class FlightSearchView extends StatefulWidget {
  const FlightSearchView({required this.params, this.api, this.now, super.key});

  /// The route's query parameters, V2's names.
  final Map<String, String> params;
  final FlightsApi? api;

  /// For tests: the day the search is run on.
  final DateTime? now;

  @override
  State<FlightSearchView> createState() => _FlightSearchViewState();
}

class _FlightSearchViewState extends State<FlightSearchView> {
  static const _slowAfter = Duration(seconds: 15);
  static const _timeoutAfter = Duration(seconds: 45);
  static const _pageSize = 15;

  late FlightSearchQuery _query;
  _Status _status = _Status.loading;
  String _error = '';
  List<FlightFare> _offers = const [];
  final _filters = ValueNotifier<FlightFilterState>(defaultFlightFilters);
  bool _filtersOpen = false;
  int _visible = _pageSize;
  int _run = 0;
  Timer? _slow;
  Timer? _timeout;

  /// The offer whose fare is being checked with the airline.
  String? _checking;

  /// The search a picked fare turned out to have gone on — the note is shown on that search only.
  String? _fareGoneOn;

  FlightsApi get _api => widget.api ?? flightsApi;

  @override
  void initState() {
    super.initState();
    _query = FlightSearchQuery.fromParams(widget.params, now: widget.now);
    exchangeRates.addListener(_redraw);
    uiSettingsStore.addListener(_onSettings);
    exchangeRates.refresh();
    _search();
  }

  @override
  void didUpdateWidget(FlightSearchView old) {
    super.didUpdateWidget(old);
    if (!_sameSearch(old.params, widget.params)) {
      _query = FlightSearchQuery.fromParams(widget.params, now: widget.now);
      _filters.value = defaultFlightFilters;
      _search();
    }
  }

  bool _sameSearch(Map<String, String> a, Map<String, String> b) {
    final x = Map.of(a)..remove(fareGoneParam);
    final y = Map.of(b)..remove(fareGoneParam);
    return x.length == y.length && x.entries.every((e) => y[e.key] == e.value);
  }

  @override
  void dispose() {
    _slow?.cancel();
    _timeout?.cancel();
    _filters.dispose();
    exchangeRates.removeListener(_redraw);
    uiSettingsStore.removeListener(_onSettings);
    super.dispose();
  }

  void _redraw() {
    if (mounted) setState(() {});
  }

  String _shownCurrencyFor = '';

  /// A range typed in one currency means nothing in another: when the cards change currency,
  /// the price filter starts over in the new one.
  void _onSettings() {
    if (!mounted) return;
    final shown = _shownCurrency;
    if (shown != _shownCurrencyFor && _filters.value.priceRange != null) {
      _filters.value = _filters.value.copyWith(priceRange: null);
    }
    _shownCurrencyFor = shown;
    setState(() {});
  }

  String get _searchKey => _query.toParams().toString();

  Future<void> _search() async {
    final run = ++_run;
    _slow?.cancel();
    _timeout?.cancel();
    setState(() {
      _status = _Status.loading;
      // The last route's offers would otherwise fill the filter panel until this one answers.
      _offers = const [];
      _visible = _pageSize;
    });

    final origin = resolveIata(_query.origin);
    final destination = resolveIata(_query.destination);
    // The date is always resolvable; a route is not. That is the only case worth refusing.
    // The message is the build's to word: this runs from initState, before the screen's
    // localisations can be read.
    if (origin == null || destination == null) {
      setState(() {
        _status = _Status.error;
        _error = '';
      });
      return;
    }

    _slow = Timer(_slowAfter, () {
      if (mounted && run == _run && _status == _Status.loading) setState(() => _status = _Status.slow);
    });
    _timeout = Timer(_timeoutAfter, () {
      if (mounted && run == _run) {
        _run++;
        setState(() => _status = _Status.timeout);
      }
    });

    final started = DateTime.now();
    try {
      final result = await _api.search(
        origin: origin,
        destination: destination,
        departureDate: _query.departure,
        returnDate: _query.returnDate,
        adults: _query.adults,
        children: _query.children,
        infants: _query.infants,
        cabinClass: _query.cabin,
        tripType: _query.tripType,
      );
      // V2 holds the skeletons for at least a second and a half, so a fast answer does
      // not flash.
      final elapsed = DateTime.now().difference(started);
      if (elapsed < const Duration(milliseconds: 1500)) {
        await Future<void>.delayed(const Duration(milliseconds: 1500) - elapsed);
      }
      if (!mounted || run != _run) return;
      _slow?.cancel();
      _timeout?.cancel();
      setState(() {
        _offers = result.offers;
        if (result.offers.isEmpty && result.providersFailed) {
          // An outage is not a fact about the route: it gets the error state and a retry.
          _status = _Status.error;
          _error = 'We could not reach the airlines just now. Your search has not been run — please try again.';
        } else {
          _status = result.offers.isEmpty ? _Status.empty : _Status.success;
        }
      });
    } on ApiError catch (e) {
      if (!mounted || run != _run) return;
      _slow?.cancel();
      _timeout?.cancel();
      setState(() {
        _status = e.message.startsWith('Request timed out') ? _Status.timeout : _Status.error;
        _error = e.message;
      });
    }
  }

  /// A change on the toolbar — route, dates, travellers or cabin — as a new search link.
  void _apply(FlightSearchQuery next) {
    _filters.value = defaultFlightFilters;
    context.go(next.toLocation());
  }

  // ── Money, as the cards print it ──

  String get _userCurrency => uiSettingsStore.displayCurrency;

  double _shownPrice(double amount, String from) =>
      exchangeRates.live ? exchangeRates.convertForDisplay(amount, from, _userCurrency).amount.toDouble() : amount;

  String _money(double amount, String from) {
    final shown = exchangeRates.convertForDisplay(amount, from, _userCurrency);
    return formatPrice(shown.amount, shown.currency);
  }

  String get _shownCurrency {
    final fare = _offers.isEmpty ? 'USD' : _offers.first.price.currency;
    return exchangeRates.convertForDisplay(1, fare, _userCurrency).currency;
  }

  // ── Selecting a fare ──

  Future<void> _select(FlightFare offer) async {
    var chosen = offer;
    setState(() => _checking = offer.offerId);
    try {
      final check = await _api.revalidate(offer);
      if (!mounted) return;
      if (check.offerExpired) {
        // The airline no longer has it, and the offers beside it are as old as it is.
        setState(() {
          _checking = null;
          _fareGoneOn = _searchKey;
        });
        unawaited(_search());
        return;
      }
      final newPrice = check.newPrice;
      if (check.priceChanged && newPrice != null) {
        final shown = exchangeRates.convertForDisplay(newPrice, offer.price.currency, _userCurrency);
        setState(() => _checking = null);
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            content: Text(
              'The price for this flight has changed to ${formatPrice(shown.amount, shown.currency)}.'
              '\n\nContinue at the new price?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
              ),
            ],
          ),
        );
        if (ok != true || !mounted) return;
      }
      // Including a drop: the booking charges what the airline now quotes.
      if (newPrice != null && newPrice > 0) chosen = offer.withTotal(newPrice);
    } on ApiError {
      // The order path re-quotes and says what is wrong; a failed check here is not a
      // reason to stop someone booking.
    } finally {
      if (mounted && _checking != null) setState(() => _checking = null);
    }
    if (!mounted) return;

    final first = chosen.segments.first;
    final last = chosen.segments.last;
    // Checkout opens in the currency the selector shows, if it is one checkout can charge in.
    final checkoutCurrency = currencies.any((c) => c.code == _userCurrency) ? _userCurrency : chosen.price.currency;
    final search = Uri(queryParameters: _query.toParams()).query;
    final location = Uri(
      path: '/flight-checkout',
      queryParameters: {
        'offerId': chosen.offerId,
        'totalAmount': '${chosen.price.total}',
        'currency': checkoutCurrency,
        'fareCurrency': chosen.price.currency,
        'origin': first.origin,
        'destination': last.destination,
        if ((first.departure?.time?.length ?? 0) >= 10) 'departureDate': first.departure!.time!.substring(0, 10),
        'cabin': first.cabinClass,
        'adults': '${_query.adults}',
        if (_query.children > 0) 'children': '${_query.children}',
        if (_query.infants > 0) 'infants': '${_query.infants}',
        'search': search,
      },
    ).toString();
    context.push(location);
  }

  Future<void> _openFilters(List<FlightFare> all, List<FlightFare> Function() filtered) async {
    setState(() => _filtersOpen = true);
    await showFlightFilters(
      context,
      filters: _filters,
      onChange: (next) {
        _filters.value = next;
        setState(() => _visible = _pageSize);
      },
      allOffers: all,
      convert: _shownPrice,
      priceCurrency: _shownCurrency,
      resultCount: () => filtered().length,
    );
    if (mounted) setState(() => _filtersOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final skin = FlightSkin.of(context);
    final dark = skin == FlightSkin.dark;

    final filters = _filters.value;
    List<FlightFare> filteredNow() => applyFlightFilters(_offers, _filters.value, _shownPrice);
    final filtered = filteredNow();
    final highlights = offerHighlights(filtered, _shownPrice);
    final loading = _status == _Status.loading || _status == _Status.slow;
    final failed = _status == _Status.timeout || _status == _Status.error;
    final fareGone = widget.params[fareGoneParam] == '1' || _fareGoneOn == _searchKey;
    final trip = Trip(
      departure: _query.departure,
      returnDate: _query.returnDate,
      adults: _query.adults,
      children: _query.children,
      infants: _query.infants,
      cabin: _query.cabin,
    );

    // Five questions rather than three, and the results arrive in the same screen — so the
    // Tip waits until the search is not mid-flight. See #62 and ADR-0006.
    return TipScope(
      tip: tipFor(t, TipAnchors.flightSearch),
      ready: !loading,
      child: Scaffold(
      backgroundColor: skin.ground,
      body: SafeArea(
        bottom: false,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            // Fifteen at a time, the next fifteen as the end comes into view.
            if (n.metrics.extentAfter < 600 && _visible < filtered.length) {
              setState(() => _visible += _pageSize);
            }
            return false;
          },
          child: Column(
            children: [
              // ── The toolbar, held over the page ground while the cards scroll
              // under it — sized by what it holds, not by a guessed height ──
              ColoredBox(
                color: skin.ground,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    children: [
                      // What the Tip points at: the bar carrying the route, the dates and who
                      // is flying — the five questions, in one control.
                      TipAnchor(
                        id: TipAnchors.flightSearch,
                        child: FlightTopBar(
                        origin: _query.origin,
                        destination: _query.destination,
                        searching: loading,
                        trip: trip,
                        onBack: () => context.canPop() ? context.pop() : context.go('/'),
                        onRoute: (o, d) => _apply(_query.copyWith(origin: o, destination: d)),
                        onTrip: (next) => _apply(
                          _query.copyWith(
                            departure: next.departure,
                            returnDate: () => next.returnDate,
                            adults: next.adults,
                            children: next.children,
                            infants: next.infants,
                            cabin: next.cabin,
                          ),
                        ),
                        filterCount: activeFilterCount(filters),
                        filtersOpen: _filtersOpen,
                        onFilters: () => _openFilters(_offers, filteredNow),
                        currency: _userCurrency,
                        onCurrency: uiSettingsStore.setDisplayCurrency,
                        onToggleTheme: () => uiSettingsStore.setThemeMode(dark ? ThemeMode.light : ThemeMode.dark),
                      ),
                      ),
                      // A date nobody asked for is disclosed, never applied quietly.
                      if (!_query.departureChosen)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.calendarClock, size: 12, color: TwPalette.blue500),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  t.flights_results_datePicked,
                                  style: TextStyle(fontSize: 11, color: dark ? Colors.white54 : TwPalette.slate500),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                      sliver: SliverList.list(
                        children: [
                          // Above every state: it says why they are here.
                          if (fareGone) ...[
                            FlightNotice(
                              icon: LucideIcons.refreshCw,
                              title: t.flights_results_fareGoneTitle,
                              body: t.flights_results_fareGoneBody,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_status == _Status.timeout)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: FlightStatus(
                                icon: LucideIcons.clock,
                                title: t.flights_results_slowTitle,
                                lines: [t.flights_results_slowBody],
                                action: (t.flights_results_tryAgain, _search),
                                secondary: (t.flights_results_newSearch, () => context.go('/')),
                              ),
                            ),
                          if (_status == _Status.error)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: FlightStatus(
                                icon: LucideIcons.searchX,
                                title: t.flights_results_searchError,
                                lines: [_error.isEmpty ? t.flights_results_missingRoute : _error],
                                action: (t.flights_results_tryAnother, () => context.go('/')),
                              ),
                            ),
                          if (!failed) ..._results(t, skin, filtered, highlights, loading),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  List<Widget> _results(
    AppLocalizations t,
    FlightSkin skin,
    List<FlightFare> filtered,
    Map<FlightFare, OfferHighlight> highlights,
    bool loading,
  ) {
    final dark = skin == FlightSkin.dark;
    final shown = filtered.take(_visible).toList();
    return [
      Text(
        t.flights_results_flightsTo(placeCity(_query.destination)),
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: skin.title),
      ),
      const SizedBox(height: 2),
      Text(
        loading ? t.flights_results_findingFares : withCount(t.flights_results_flightsFound(filtered.length), filtered.length),
        style: TextStyle(fontSize: 11, color: dark ? Colors.white54 : TwPalette.slate500),
      ),
      const SizedBox(height: 16),
      if (_status == _Status.slow) ...[
        FlightNotice(icon: null, title: 'Still searching…', body: t.flights_results_slowHint, spinning: true),
        const SizedBox(height: 16),
      ],
      if (_checking != null) ...[
        Semantics(
          liveRegion: true,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: dark ? const Color(0x14FFFFFF) : TwPalette.slate100,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              t.flights_results_checkingFare,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: dark ? Colors.white70 : TwPalette.slate600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
      if (loading) ...[
        // A plain blue ring and one line saying what it is doing.
        Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: dark ? TwPalette.blue400 : TwPalette.blue600,
                    backgroundColor: (dark ? TwPalette.blue400 : TwPalette.blue600).withValues(alpha: 0.2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  t.flights_results_findingFares,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: dark ? TwPalette.slate200 : TwPalette.slate700,
                  ),
                ),
              ],
            ),
          ),
        ),
        for (var i = 0; i < 8; i++) ...[const FlightCardSkeleton(), const SizedBox(height: 12)],
      ] else if (_status == _Status.success && filtered.isEmpty) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 64),
          decoration: BoxDecoration(
            color: skin.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: dark ? const Color(0x1AFFFFFF) : TwPalette.slate300),
          ),
          child: Column(
            children: [
              Text(
                t.flights_results_noMatch,
                style: TextStyle(fontWeight: FontWeight.w500, color: skin.title),
              ),
              const SizedBox(height: 4),
              Text(
                t.flights_results_noMatchHint,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: dark ? Colors.white54 : TwPalette.slate500),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  _filters.value = defaultFlightFilters;
                  setState(() {});
                },
                child: Text(
                  t.flights_results_clearFilters,
                  style: TextStyle(
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                    color: dark ? Colors.white70 : TwPalette.slate600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ] else if (_status == _Status.empty) ...[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: FlightStatus(
            icon: LucideIcons.search,
            title: t.flights_results_noFlights,
            lines: [t.flights_results_noFlightsBody],
          ),
        ),
      ] else ...[
        for (final o in shown) ...[
          FlightCard(
            key: ValueKey(o.offerId),
            offer: o,
            money: _money,
            highlight: highlights[o],
            checkingPrice: _checking == o.offerId,
            onSelect: _select,
          ),
          const SizedBox(height: 16),
        ],
        if (shown.length < filtered.length) ...[
          const FlightCardSkeleton(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              t.mobile_flights_discoveringMore(shown.length, filtered.length),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: dark ? TwPalette.slate500 : TwPalette.slate400,
              ),
            ),
          ),
        ] else if (filtered.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 48),
            child: Text(
              t.mobile_flights_allShown(filtered.length),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: dark ? Colors.white38 : TwPalette.slate400),
            ),
          ),
      ],
    ];
  }
}

import 'dart:math' as math;

import 'package:cheapest_go_mobile/features/flights/models/flight_fare.dart';

/// V2's `filter-offers.ts`: what the filter panel asks of a set of offers, and the code that
/// answers it. Kept apart from the panel so the rules are testable without rendering it.

enum FlightSortBy { price, duration, departure }

const dayStartMinute = 0;
const dayEndMinute = 24 * 60 - 1;

/// An amount in the currency it came in, as the page prints it.
typedef PriceConverter = double Function(double amount, String currency);

double _asQuoted(double amount, String _) => amount;

class FlightFilterState {
  const FlightFilterState({
    this.sortBy = FlightSortBy.price,
    this.selectedAirlines = const [],
    this.stops,
    this.refundableOnly = false,
    this.selectedProviders = const [],
    this.priceRange,
    this.departureWindow,
    this.arrivalWindow,
    this.maxDurationMinutes,
    this.selectedArrivalAirports = const [],
  });

  final FlightSortBy sortBy;

  /// Empty means every airline — the same as every one ticked.
  final List<String> selectedAirlines;

  /// null is any number; 2 means two or more.
  final int? stops;
  final bool refundableOnly;
  final List<String> selectedProviders;

  /// Per person, in the currency the cards show.
  final (double, double)? priceRange;
  final (int, int)? departureWindow;
  final (int, int)? arrivalWindow;
  final int? maxDurationMinutes;
  final List<String> selectedArrivalAirports;

  static const _unset = Object();

  FlightFilterState copyWith({
    FlightSortBy? sortBy,
    List<String>? selectedAirlines,
    Object? stops = _unset,
    bool? refundableOnly,
    List<String>? selectedProviders,
    Object? priceRange = _unset,
    Object? departureWindow = _unset,
    Object? arrivalWindow = _unset,
    Object? maxDurationMinutes = _unset,
    List<String>? selectedArrivalAirports,
  }) => FlightFilterState(
    sortBy: sortBy ?? this.sortBy,
    selectedAirlines: selectedAirlines ?? this.selectedAirlines,
    stops: identical(stops, _unset) ? this.stops : stops as int?,
    refundableOnly: refundableOnly ?? this.refundableOnly,
    selectedProviders: selectedProviders ?? this.selectedProviders,
    priceRange: identical(priceRange, _unset) ? this.priceRange : priceRange as (double, double)?,
    departureWindow: identical(departureWindow, _unset) ? this.departureWindow : departureWindow as (int, int)?,
    arrivalWindow: identical(arrivalWindow, _unset) ? this.arrivalWindow : arrivalWindow as (int, int)?,
    maxDurationMinutes: identical(maxDurationMinutes, _unset) ? this.maxDurationMinutes : maxDurationMinutes as int?,
    selectedArrivalAirports: selectedArrivalAirports ?? this.selectedArrivalAirports,
  );
}

const defaultFlightFilters = FlightFilterState();

/// The airline a traveller would say they are flying with — the name the card shows.
String offerAirline(FlightFare o) {
  final first = o.segments.isEmpty ? null : o.segments.first;
  final name = first?.airlineName ?? '';
  if (name.isNotEmpty) return name;
  final code = first?.airline ?? '';
  return code.isNotEmpty ? code : o.provider;
}

/// What one traveller pays: the total moves with the party size, a filter must not.
double offerPricePerPerson(FlightFare o) => o.price.pricePerAdult > 0 ? o.price.pricePerAdult : o.price.total;

double _shown(FlightFare o, PriceConverter convert) => convert(offerPricePerPerson(o), o.price.currency);

/// Minutes past midnight, read out of the string — Local Airport Time, as `formatTime` reads it.
int? minutesOfDay(String? iso) {
  if (iso == null) return null;
  final m = RegExp(r'T(\d{2}):(\d{2})').firstMatch(iso);
  if (m == null) return null;
  final h = int.parse(m.group(1)!);
  final min = int.parse(m.group(2)!);
  if (h > 23 || min > 59) return null;
  return h * 60 + min;
}

List<List<FlightSegment>> _directions(FlightFare o) {
  final groups = <int, List<FlightSegment>>{};
  for (final s in o.segments) {
    groups.putIfAbsent(s.segmentIndex, () => []).add(s);
  }
  final keys = groups.keys.toList()..sort();
  return [for (final k in keys) groups[k]!];
}

List<FlightSegment> _outbound(FlightFare o) {
  final d = _directions(o);
  return d.isEmpty ? const [] : d.first;
}

/// Plane changes on the direction that has the most of them — never `totalStops`, which sums
/// a round trip's two directions while the card reads one.
int offerStopsPerDirection(FlightFare o) {
  final d = _directions(o);
  if (d.isEmpty) return o.totalStops;
  return d.map((x) => x.length - 1).reduce(math.max);
}

int? offerDepartureMinute(FlightFare o) {
  final out = _outbound(o);
  return out.isEmpty ? null : minutesOfDay(out.first.departure?.time);
}

int? offerArrivalMinute(FlightFare o) {
  final out = _outbound(o);
  return out.isEmpty ? null : minutesOfDay(out.last.arrival?.time);
}

String offerArrivalAirport(FlightFare o) {
  final out = _outbound(o);
  if (out.isEmpty) return '';
  final last = out.last;
  final a = last.arrival?.airport ?? '';
  return a.isNotEmpty ? a : last.destination;
}

/// The outbound's elapsed time, falling back to the offer-wide figure when unquoted.
int offerDurationMinutes(FlightFare o) => o.sliceDurations.isNotEmpty ? o.sliceDurations.first : o.totalDuration;

enum OfferHighlight { cheapest, fastest }

/// The cheapest and the fastest of the listed offers, one mark each, as V2 decides them.
Map<FlightFare, OfferHighlight> offerHighlights(List<FlightFare> offers, [PriceConverter convert = _asQuoted]) {
  final marks = <FlightFare, OfferHighlight>{};
  if (offers.length < 2) return marks;

  FlightFare? cheapest;
  for (final o in offers.where((o) => offerPricePerPerson(o) > 0)) {
    if (cheapest == null || _shown(o, convert) < _shown(cheapest, convert)) cheapest = o;
  }
  if (cheapest != null) marks[cheapest] = OfferHighlight.cheapest;

  final timed = offers.where((o) => offerDurationMinutes(o) > 0).toList();
  if (timed.isNotEmpty) {
    final shortest = timed.map(offerDurationMinutes).reduce(math.min);
    for (final o in timed) {
      if (offerDurationMinutes(o) == shortest && !identical(o, cheapest)) {
        marks[o] = OfferHighlight.fastest;
        break;
      }
    }
  }
  return marks;
}

bool offerIsRefundable(FlightFare o) => (o.farePolicy?.isRefundable ?? o.refundable) == true;

bool offerMatchesStops(FlightFare o, int? stops) {
  if (stops == null) return true;
  final actual = offerStopsPerDirection(o);
  return stops == 2 ? actual >= 2 : actual == stops;
}

class FilterBounds {
  const FilterBounds({
    required this.price,
    required this.duration,
    required this.airlines,
    required this.arrivalAirports,
  });

  final (double, double) price;
  final (int, int) duration;
  final List<String> airlines;
  final List<String> arrivalAirports;
}

FilterBounds filterBounds(List<FlightFare> offers, [PriceConverter convert = _asQuoted]) {
  if (offers.isEmpty) {
    return const FilterBounds(price: (0, 0), duration: (0, 0), airlines: [], arrivalAirports: []);
  }
  final prices = offers.map((o) => _shown(o, convert)).toList();
  final durations = offers.map(offerDurationMinutes).toList();
  final airlines = <String>{};
  final airports = <String>{};
  for (final o in offers) {
    final a = offerAirline(o);
    if (a.isNotEmpty) airlines.add(a);
    final p = offerArrivalAirport(o);
    if (p.isNotEmpty) airports.add(p);
  }
  return FilterBounds(
    price: (prices.reduce(math.min).floorToDouble(), prices.reduce(math.max).ceilToDouble()),
    duration: (durations.reduce(math.min), durations.reduce(math.max)),
    airlines: airlines.toList()..sort(),
    arrivalAirports: airports.toList()..sort(),
  );
}

/// How many filters the traveller has narrowed by — sort is not one of them.
int activeFilterCount(FlightFilterState f) =>
    f.selectedAirlines.length +
    f.selectedArrivalAirports.length +
    f.selectedProviders.length +
    (f.stops != null ? 1 : 0) +
    (f.refundableOnly ? 1 : 0) +
    (f.priceRange != null ? 1 : 0) +
    (f.departureWindow != null ? 1 : 0) +
    (f.arrivalWindow != null ? 1 : 0) +
    (f.maxDurationMinutes != null ? 1 : 0);

bool _within(int? minute, (int, int)? window) {
  if (window == null || minute == null) return true;
  return minute >= window.$1 && minute <= window.$2;
}

/// Every offer that matches, in the chosen order. Never sorts in place.
List<FlightFare> applyFlightFilters(
  List<FlightFare> offers,
  FlightFilterState f, [
  PriceConverter convert = _asQuoted,
]) {
  final matched = offers.where((o) {
    if (!offerMatchesStops(o, f.stops)) return false;
    if (f.refundableOnly && !offerIsRefundable(o)) return false;
    if (f.selectedProviders.isNotEmpty && !f.selectedProviders.contains(o.provider)) return false;
    if (f.selectedAirlines.isNotEmpty && !f.selectedAirlines.contains(offerAirline(o))) return false;
    if (f.selectedArrivalAirports.isNotEmpty && !f.selectedArrivalAirports.contains(offerArrivalAirport(o))) {
      return false;
    }
    final range = f.priceRange;
    if (range != null) {
      final p = _shown(o, convert);
      if (p < range.$1 || p > range.$2) return false;
    }
    if (f.maxDurationMinutes != null && offerDurationMinutes(o) > f.maxDurationMinutes!) return false;
    if (!_within(offerDepartureMinute(o), f.departureWindow)) return false;
    if (!_within(offerArrivalMinute(o), f.arrivalWindow)) return false;
    return true;
  }).toList();

  final num Function(FlightFare) key = switch (f.sortBy) {
    FlightSortBy.price => (o) => convert(o.price.total, o.price.currency),
    FlightSortBy.duration => offerDurationMinutes,
    FlightSortBy.departure => (o) => offerDepartureMinute(o) ?? 0,
  };
  return _stableSort(matched, key);
}

/// Ties keep the order the API gave them, as JavaScript's sort does — Dart's `sort` makes no
/// such promise, and two equal fares swapping places between renders reads as a glitch.
List<FlightFare> _stableSort(List<FlightFare> list, num Function(FlightFare) key) {
  final indexed = [for (var i = 0; i < list.length; i++) (i, key(list[i]), list[i])];
  indexed.sort((a, b) {
    final c = a.$2.compareTo(b.$2);
    return c != 0 ? c : a.$1.compareTo(b.$1);
  });
  return [for (final e in indexed) e.$3];
}

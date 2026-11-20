import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:cheapest_go_mobile/features/flights/components/flight_chrome.dart';
import 'package:cheapest_go_mobile/features/flights/lib/filter_offers.dart';
import 'package:cheapest_go_mobile/features/flights/lib/flight_utils.dart';
import 'package:cheapest_go_mobile/features/flights/models/flight_fare.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_palette.dart';

/// The filter drawer, as V2 opens it below `lg`: a 320px sheet sliding in from the right edge
/// over a dimmed scrim, V2's `FlightFilters` panel inside, and "Show N flights" at its foot.
Future<void> showFlightFilters(
  BuildContext context, {
  required ValueListenable<FlightFilterState> filters,
  required ValueChanged<FlightFilterState> onChange,
  required List<FlightFare> allOffers,
  required PriceConverter convert,
  required String priceCurrency,
  required int Function() resultCount,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: const Color(0x80000000),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, _, _) => Align(
      alignment: Alignment.centerRight,
      child: ValueListenableBuilder(
        valueListenable: filters,
        builder: (context, value, _) => _Drawer(
          filters: value,
          onChange: onChange,
          allOffers: allOffers,
          convert: convert,
          priceCurrency: priceCurrency,
          count: resultCount(),
        ),
      ),
    ),
    transitionBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(curved),
        child: child,
      );
    },
  );
}

class _Drawer extends StatelessWidget {
  const _Drawer({
    required this.filters,
    required this.onChange,
    required this.allOffers,
    required this.convert,
    required this.priceCurrency,
    required this.count,
  });

  final FlightFilterState filters;
  final ValueChanged<FlightFilterState> onChange;
  final List<FlightFare> allOffers;
  final PriceConverter convert;
  final String priceCurrency;
  final int count;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    return Material(
      color: dark ? TwPalette.slate950 : TwPalette.slate50,
      child: SizedBox(
        width: width < 320 ? width : 320,
        height: double.infinity,
        child: SafeArea(
          left: false,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: t.hotels_filters_close,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(LucideIcons.x, size: 18, color: dark ? Colors.white60 : TwPalette.slate500),
                ),
              ),
              FlightFiltersPanel(
                filters: filters,
                onChange: onChange,
                allOffers: allOffers,
                convert: convert,
                priceCurrency: priceCurrency,
              ),
              const SizedBox(height: 24),
              GradientPill(
                label: withCount(t.flights_filtersPanel_showCount(count), count),
                onTap: () => Navigator.of(context).pop(),
                expand: true,
                height: 44,
                radius: 999,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// V2's `FlightFilters`: sort, airlines, stops, price per person, times, duration, arrival
/// airports — and, outside production, the supplier. Counts come from the unfiltered offers so
/// an option never reads as empty because another filter is hiding its results.
class FlightFiltersPanel extends StatefulWidget {
  const FlightFiltersPanel({
    required this.filters,
    required this.onChange,
    required this.allOffers,
    required this.convert,
    required this.priceCurrency,
    super.key,
  });

  final FlightFilterState filters;
  final ValueChanged<FlightFilterState> onChange;
  final List<FlightFare> allOffers;
  final PriceConverter convert;
  final String priceCurrency;

  @override
  State<FlightFiltersPanel> createState() => _FlightFiltersPanelState();
}

class _FlightFiltersPanelState extends State<FlightFiltersPanel> {
  final _open = <String, bool>{};

  bool _isOpen(String k) => _open[k] ?? true;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette.of(context);
    final f = widget.filters;
    final offers = widget.allOffers;
    final bounds = filterBounds(offers, widget.convert);

    final airlineCounts = <String, int>{};
    final airportCounts = <String, int>{};
    final providerCounts = <String, int>{};
    for (final o in offers) {
      final a = offerAirline(o);
      if (a.isNotEmpty) airlineCounts[a] = (airlineCounts[a] ?? 0) + 1;
      final ap = offerArrivalAirport(o);
      if (ap.isNotEmpty) airportCounts[ap] = (airportCounts[ap] ?? 0) + 1;
      if (o.provider.isNotEmpty) providerCounts[o.provider] = (providerCounts[o.provider] ?? 0) + 1;
    }
    final stopCounts = [
      for (final s in [0, 1, 2]) offers.where((o) => offerMatchesStops(o, s)).length,
    ];
    final refundableCount = offers.where(offerIsRefundable).length;

    final dirty = f.sortBy != defaultFlightFilters.sortBy || activeFilterCount(f) > 0;
    final priceRange = f.priceRange ?? bounds.price;
    final departure = f.departureWindow ?? (dayStartMinute, dayEndMinute);
    final arrival = f.arrivalWindow ?? (dayStartMinute, dayEndMinute);
    final maxDuration = f.maxDurationMinutes ?? bounds.duration.$2;
    final hasPriceSpread = bounds.price.$2 > bounds.price.$1;
    final hasDurationSpread = bounds.duration.$2 > bounds.duration.$1;
    final providers = providerCounts.keys.toList()..sort();
    final reset = t.flights_filtersPanel_reset;

    void change(FlightFilterState next) => widget.onChange(next);

    Widget section(String key, String label, List<Widget> children, {VoidCallback? onReset}) => _Section(
      label: label,
      open: _isOpen(key),
      onToggle: () => setState(() => _open[key] = !_isOpen(key)),
      resetLabel: reset,
      onReset: onReset,
      children: children,
    );

    Widget timeWindow(String label, (int, int) window, ValueChanged<(int, int)> onWindow) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 15, color: p.body)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _TimeSelect(
                  label: t.flights_filtersPanel_rangeFrom(label),
                  value: window.$1,
                  from: dayStartMinute,
                  to: window.$2,
                  onPick: (v) => onWindow((v, window.$2)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('–', style: TextStyle(color: p.muted)),
              ),
              Expanded(
                child: _TimeSelect(
                  label: t.flights_filtersPanel_rangeTo(label),
                  value: window.$2,
                  from: window.$1,
                  to: dayEndMinute,
                  onPick: (v) => onWindow((window.$1, v)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
      decoration: BoxDecoration(
        color: p.panel,
        borderRadius: BorderRadius.circular(20),
        boxShadow: p.dark ? null : const [BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Icon(LucideIcons.slidersHorizontal, size: 17, color: p.icon),
                const SizedBox(width: 10),
                Text(t.flights_results_filters, style: TextStyle(fontSize: 17, color: p.heading)),
                const Spacer(),
                if (dirty)
                  GestureDetector(
                    onTap: () => change(defaultFlightFilters),
                    child: Text(reset, style: TextStyle(fontSize: 12, color: p.muted)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Sort ──
          section('sort', t.flights_filtersPanel_sortBy, [
            for (final (value, label) in [
              (FlightSortBy.price, t.flights_filtersPanel_cheapestFirst),
              (FlightSortBy.duration, t.flights_filtersPanel_fastestFirst),
              (FlightSortBy.departure, t.flights_filtersPanel_earliestDeparture),
            ])
              _Row(
                label: label,
                active: f.sortBy == value,
                onTap: () => change(f.copyWith(sortBy: value)),
              ),
          ]),

          // ── Airlines ──
          if (bounds.airlines.isNotEmpty)
            section('airlines', t.flights_filtersPanel_airlines, [
              _CheckList(
                options: bounds.airlines,
                selected: f.selectedAirlines,
                counts: airlineCounts,
                selectAllLabel: t.flights_filtersPanel_selectAllAirlines,
                onChange: (next) => change(f.copyWith(selectedAirlines: next)),
              ),
            ], onReset: f.selectedAirlines.isNotEmpty ? () => change(f.copyWith(selectedAirlines: const [])) : null),

          // ── Stops: one of three, or none — picking the lit row again lets it go ──
          section('stops', t.flights_filtersPanel_stops, [
            for (final (value, label) in [
              (0, t.flights_filtersPanel_direct),
              (1, t.flights_filtersPanel_oneStop),
              (2, t.flights_filtersPanel_twoStopsPlus),
            ])
              _Row(
                label: label,
                right: offers.isNotEmpty ? '${stopCounts[value]}' : null,
                active: f.stops == value,
                onTap: () => change(f.copyWith(stops: f.stops == value ? null : value)),
              ),
          ], onReset: f.stops != null ? () => change(f.copyWith(stops: null)) : null),

          // ── Price per person ──
          section(
            'price',
            t.flights_filtersPanel_pricePerPerson,
            [
              _Switch(
                label: t.flights_filtersPanel_refundable,
                checked: f.refundableOnly,
                onChange: (v) => change(f.copyWith(refundableOnly: v)),
              ),
              if (f.refundableOnly && refundableCount == 0 && offers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    t.flights_filtersPanel_refundableFaresDescription,
                    style: TextStyle(fontSize: 12, color: p.dark ? TwPalette.amber400 : TwPalette.amber600),
                  ),
                ),
              if (hasPriceSpread) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: _NumberField(
                        label: t.flights_filtersPanel_rangeFrom(t.flights_filtersPanel_pricePerPerson),
                        prefix: _symbol(widget.priceCurrency),
                        value: priceRange.$1.round(),
                        normalize: (v) => v.clamp(bounds.price.$1.round(), priceRange.$2.round()),
                        onCommit: (v) => change(f.copyWith(priceRange: (v.toDouble(), priceRange.$2))),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('–', style: TextStyle(color: p.muted)),
                    ),
                    Expanded(
                      child: _NumberField(
                        label: t.flights_filtersPanel_rangeTo(t.flights_filtersPanel_pricePerPerson),
                        prefix: _symbol(widget.priceCurrency),
                        value: priceRange.$2.round(),
                        normalize: (v) => v.clamp(priceRange.$1.round(), bounds.price.$2.round()),
                        onCommit: (v) => change(f.copyWith(priceRange: (priceRange.$1, v.toDouble()))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    activeTrackColor: TwPalette.blue600,
                    inactiveTrackColor: p.track,
                    thumbColor: TwPalette.cyan500,
                    overlayShape: SliderComponentShape.noOverlay,
                    rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 9),
                  ),
                  child: RangeSlider(
                    min: bounds.price.$1,
                    max: bounds.price.$2,
                    values: RangeValues(priceRange.$1, priceRange.$2),
                    semanticFormatterCallback: (v) => '${_symbol(widget.priceCurrency)}${v.round()}',
                    onChanged: (r) => change(f.copyWith(priceRange: (r.start.roundToDouble(), r.end.roundToDouble()))),
                  ),
                ),
              ],
            ],
            onReset: f.priceRange != null || f.refundableOnly
                ? () => change(f.copyWith(priceRange: null, refundableOnly: false))
                : null,
          ),

          // ── Times — picked, not dragged ──
          section(
            'times',
            t.flights_filtersPanel_times,
            [
              timeWindow(t.flights_filtersPanel_departure, departure, (w) => change(f.copyWith(departureWindow: w))),
              const SizedBox(height: 8),
              timeWindow(t.flights_filtersPanel_arrival, arrival, (w) => change(f.copyWith(arrivalWindow: w))),
            ],
            onReset: f.departureWindow != null || f.arrivalWindow != null
                ? () => change(f.copyWith(departureWindow: null, arrivalWindow: null))
                : null,
          ),

          // ── Flight duration — a ceiling, in whole hours ──
          if (hasDurationSpread)
            section('duration', t.flights_filtersPanel_flightDuration, [
              _UnderHours(
                template: t.flights_filtersPanel_underHours('\u0000'),
                hours: (maxDuration / 60).ceil(),
                minHours: (bounds.duration.$1 / 60).ceil(),
                maxHours: (bounds.duration.$2 / 60).ceil(),
                label: t.flights_filtersPanel_flightDuration,
                onCommit: (h) =>
                    change(f.copyWith(maxDurationMinutes: (h * 60).clamp(bounds.duration.$1, bounds.duration.$2))),
              ),
            ], onReset: f.maxDurationMinutes != null ? () => change(f.copyWith(maxDurationMinutes: null)) : null),

          // ── Arrival airports — only when there is a choice ──
          if (bounds.arrivalAirports.length > 1)
            section(
              'airports',
              t.flights_filtersPanel_arrivalAirports,
              [
                _CheckList(
                  options: bounds.arrivalAirports,
                  selected: f.selectedArrivalAirports,
                  counts: airportCounts,
                  selectAllLabel: t.flights_filtersPanel_selectAllAirports,
                  onChange: (next) => change(f.copyWith(selectedArrivalAirports: next)),
                ),
              ],
              onReset: f.selectedArrivalAirports.isNotEmpty
                  ? () => change(f.copyWith(selectedArrivalAirports: const []))
                  : null,
            ),

          // Which supplier a fare came from is ours to know, not the traveller's —
          // shown outside production only, as on the web.
          if (!kReleaseMode && providers.isNotEmpty)
            section('provider', t.flights_filtersPanel_provider, [
              for (final name in providers)
                _Row(
                  label: name == 'mystifly_v2' ? 'Mystifly' : name,
                  right: name == 'mystifly_v2' ? 'Branded fares' : 'NDC fares',
                  active: f.selectedProviders.contains(name),
                  onTap: () => change(
                    f.copyWith(
                      selectedProviders: f.selectedProviders.contains(name)
                          ? f.selectedProviders.where((x) => x != name).toList()
                          : [...f.selectedProviders, name],
                    ),
                  ),
                ),
            ]),
        ],
      ),
    );
  }
}

String _symbol(String currency) {
  try {
    return NumberFormat.simpleCurrency(locale: 'en_US', name: currency).currencySymbol;
  } catch (_) {
    return currency;
  }
}

class _Palette {
  const _Palette({
    required this.dark,
    required this.panel,
    required this.heading,
    required this.icon,
    required this.muted,
    required this.body,
    required this.idle,
    required this.mark,
    required this.switchOff,
    required this.fieldBg,
    required this.fieldBorder,
    required this.track,
  });

  final bool dark;
  final Color panel;
  final Color heading;
  final Color icon;
  final Color muted;
  final Color body;
  final Color idle;
  final Color mark;
  final Color switchOff;
  final Color fieldBg;
  final Color fieldBorder;
  final Color track;

  /// V2's `filtersPalette`.
  static _Palette of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark
        ? const _Palette(
            dark: true,
            panel: TwPalette.slate900,
            heading: Colors.white,
            icon: Colors.white,
            muted: TwPalette.slate400,
            body: Color(0xE6FFFFFF),
            idle: Color(0xE6FFFFFF),
            mark: Color(0x4DFFFFFF),
            switchOff: Color(0x33FFFFFF),
            fieldBg: TwPalette.obsidian,
            fieldBorder: Color(0x1AFFFFFF),
            track: Color(0x33FFFFFF),
          )
        : const _Palette(
            dark: false,
            panel: Colors.white,
            heading: TwPalette.slate900,
            icon: TwPalette.slate700,
            muted: TwPalette.slate500,
            body: TwPalette.slate700,
            idle: TwPalette.slate700,
            mark: TwPalette.slate300,
            switchOff: TwPalette.slate200,
            fieldBg: TwPalette.slate50,
            fieldBorder: TwPalette.slate200,
            track: TwPalette.slate200,
          );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.open,
    required this.onToggle,
    required this.resetLabel,
    required this.children,
    this.onReset,
  });

  final String label;
  final bool open;
  final VoidCallback onToggle;
  final String resetLabel;
  final VoidCallback? onReset;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onToggle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        AnimatedRotation(
                          turns: open ? 0 : 0.5,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(LucideIcons.chevronUp, size: 16, color: p.muted),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            label.toUpperCase(),
                            style: TextStyle(fontSize: 13, letterSpacing: 1.69, color: p.muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (onReset != null)
                GestureDetector(
                  onTap: onReset,
                  child: Text(resetLabel, style: TextStyle(fontSize: 12, color: p.muted)),
                ),
            ],
          ),
          if (open) ...[const SizedBox(height: 10), ...children],
        ],
      ),
    );
  }
}

/// One choice in a list: the gradient pill when on.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.active, required this.onTap, this.right});

  final String label;
  final bool active;
  final VoidCallback onTap;
  final String? right;

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    return Semantics(
      selected: active,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: 34,
          decoration: BoxDecoration(
            gradient: active ? FlightSkin.gradient : null,
            borderRadius: BorderRadius.circular(999),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.only(left: 26, right: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, color: active ? Colors.white : p.idle),
                    ),
                  ),
                  if (right != null)
                    Opacity(
                      opacity: active ? 0.9 : 0.6,
                      child: Text(right!, style: TextStyle(fontSize: 12, color: active ? Colors.white : p.idle)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.label, required this.checked, required this.onTap, required this.right});

  final String label;
  final bool checked;
  final VoidCallback onTap;
  final int right;

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    return Semantics(
      checked: checked,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: SizedBox(
          height: 34,
          child: Padding(
            padding: const EdgeInsets.only(left: 18, right: 16),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: checked ? FlightSkin.gradient : null,
                    border: Border.all(color: checked ? Colors.transparent : p.mark),
                  ),
                  child: checked ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, color: p.idle),
                  ),
                ),
                Opacity(
                  opacity: 0.6,
                  child: Text('$right', style: TextStyle(fontSize: 12, color: p.idle)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({required this.label, required this.checked, required this.onChange});

  final String label;
  final bool checked;
  final ValueChanged<bool> onChange;

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 15, color: p.body)),
          ),
          Semantics(
            toggled: checked,
            label: label,
            child: GestureDetector(
              onTap: () => onChange(!checked),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 20,
                padding: const EdgeInsets.all(2),
                alignment: checked ? Alignment.centerRight : Alignment.centerLeft,
                decoration: BoxDecoration(
                  gradient: checked ? FlightSkin.gradient : null,
                  color: checked ? null : p.switchOff,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 2)],
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

/// A checklist with a select-all switch over it. Empty means "no restriction", which is also
/// what every box ticked means; the switch writes whichever of the two was asked for.
class _CheckList extends StatefulWidget {
  const _CheckList({
    required this.options,
    required this.selected,
    required this.counts,
    required this.selectAllLabel,
    required this.onChange,
  });

  final List<String> options;
  final List<String> selected;
  final Map<String, int> counts;
  final String selectAllLabel;
  final ValueChanged<List<String>> onChange;

  @override
  State<_CheckList> createState() => _CheckListState();
}

class _CheckListState extends State<_CheckList> {
  static const _collapsed = 5;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = _Palette.of(context);
    final options = widget.options;
    final selected = widget.selected;
    final all = selected.isEmpty || selected.length == options.length;
    final shown = _expanded ? options : options.take(_collapsed).toList();

    void toggle(String option) {
      // An untouched list reads as "everything"; the first untick starts from that, or
      // unticking one airline would silently select only that airline.
      final base = selected.isEmpty ? options : selected;
      final next = base.contains(option) ? base.where((o) => o != option).toList() : [...base, option];
      widget.onChange(next.length == options.length ? const [] : next);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Switch(
          label: widget.selectAllLabel,
          checked: all,
          onChange: (on) => widget.onChange(on ? const [] : [options.first]),
        ),
        for (final o in shown)
          _CheckRow(
            label: o,
            checked: selected.isEmpty || selected.contains(o),
            right: widget.counts[o] ?? 0,
            onTap: () => toggle(o),
          ),
        if (options.length > _collapsed)
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(LucideIcons.chevronDown, size: 14, color: p.muted),
              ),
              label: Text(
                _expanded ? t.flights_filtersPanel_showLess : t.flights_filtersPanel_showAll,
                style: TextStyle(fontSize: 12, color: p.muted),
              ),
            ),
          ),
      ],
    );
  }
}

/// One end of a day window, as a dropdown of half hours — offering only times on its own side
/// of the other end, the day's last minute, and wherever it stands now.
class _TimeSelect extends StatelessWidget {
  const _TimeSelect({
    required this.label,
    required this.value,
    required this.from,
    required this.to,
    required this.onPick,
  });

  final String label;
  final int value;
  final int from;
  final int to;
  final ValueChanged<int> onPick;

  static String clock(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    final marks = <int>{dayEndMinute, value};
    for (var m = dayStartMinute; m < dayEndMinute; m += 30) {
      marks.add(m);
    }
    final options = marks.where((m) => m >= from && m <= to).toList()..sort();
    return PopupMenuButton<int>(
      tooltip: label,
      onSelected: onPick,
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(maxHeight: 320, minWidth: 160),
      itemBuilder: (_) => [
        for (final m in options)
          PopupMenuItem(
            value: m,
            height: 36,
            child: Text(
              clock(m),
              style: TextStyle(fontSize: 13, fontWeight: m == value ? FontWeight.w700 : FontWeight.w400),
            ),
          ),
      ],
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: p.fieldBg,
          border: Border.all(color: p.fieldBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(clock(value), style: TextStyle(fontSize: 13, color: p.heading)),
            ),
            Icon(LucideIcons.chevronDown, size: 14, color: p.muted),
          ],
        ),
      ),
    );
  }
}

/// A typed whole number, committed on submit or when focus leaves, and normalised into range.
class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.normalize,
    required this.onCommit,
    this.prefix,
    this.width,
    this.center = false,
  });

  final String label;
  final int value;
  final int Function(int) normalize;
  final ValueChanged<int> onCommit;
  final String? prefix;
  final double? width;
  final bool center;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final _text = TextEditingController(text: '${widget.value}');
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
    });
  }

  @override
  void didUpdateWidget(_NumberField old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && old.value != widget.value) _text.text = '${widget.value}';
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit() {
    final n = int.tryParse(_text.text.trim());
    if (n == null) {
      _text.text = '${widget.value}';
      return;
    }
    final v = widget.normalize(n);
    _text.text = '$v';
    if (v != widget.value) widget.onCommit(v);
  }

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    return SizedBox(
      width: widget.width,
      height: 38,
      child: TextField(
        controller: _text,
        focusNode: _focus,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: widget.center ? TextAlign.center : TextAlign.start,
        onSubmitted: (_) => _commit(),
        style: TextStyle(fontSize: 13, color: p.heading),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: p.fieldBg,
          semanticCounterText: widget.label,
          hintText: widget.label,
          hintStyle: const TextStyle(fontSize: 0),
          prefixText: widget.prefix,
          prefixStyle: TextStyle(fontSize: 13, color: p.muted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: p.fieldBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: p.fieldBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: TwPalette.blue600),
          ),
        ),
      ),
    );
  }
}

/// "Under [ 9 ] hours": V2's message with the field inside it. The rich form of that message is
/// not carried to mobile, so the plain one is split around its placeholder instead.
class _UnderHours extends StatelessWidget {
  const _UnderHours({
    required this.template,
    required this.hours,
    required this.minHours,
    required this.maxHours,
    required this.label,
    required this.onCommit,
  });

  /// The message with `\u0000` where the number goes.
  final String template;
  final int hours;
  final int minHours;
  final int maxHours;
  final String label;
  final ValueChanged<int> onCommit;

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    final parts = template.split('\u0000');
    final style = TextStyle(fontSize: 15, color: p.body);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          if (parts.first.trim().isNotEmpty) Text(parts.first.trim(), style: style),
          const SizedBox(width: 8),
          _NumberField(
            label: label,
            value: hours,
            width: 64,
            center: true,
            normalize: (h) => h.clamp(minHours, maxHours),
            onCommit: onCommit,
          ),
          const SizedBox(width: 8),
          if (parts.length > 1 && parts[1].trim().isNotEmpty) Text(parts[1].trim(), style: style),
        ],
      ),
    );
  }
}

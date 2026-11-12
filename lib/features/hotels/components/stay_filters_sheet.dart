import 'package:flutter/material.dart';

import 'package:cheapest_go_mobile/features/hotels/components/stay_chrome.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';

/// What a person has asked to see, and in what order.
///
/// V2's `HotelFiltersState`, field for field: the sort, the star categories, and the price
/// bounds. The bounds are open rather than zeroed — a concrete 0 would read as a deliberate
/// filter the moment the cheapest stay costs more than nothing.
class StayFilters {
    const StayFilters({
        this.sort = StaySort.recommended,
        this.stars = const {},
        this.minPrice = double.negativeInfinity,
        this.maxPrice = double.infinity,
    });

    final StaySort sort;
    final Set<int> stars;
    final double minPrice;
    final double maxPrice;

    /// Whether anything is narrowing the results. The sort is not a filter: it changes the
    /// order, not the set.
    bool narrowedWithin(double floor, double ceiling) =>
        stars.isNotEmpty || minPrice > floor || maxPrice < ceiling;

    StayFilters copyWith({StaySort? sort, Set<int>? stars, double? minPrice, double? maxPrice}) =>
        StayFilters(
            sort: sort ?? this.sort,
            stars: stars ?? this.stars,
            minPrice: minPrice ?? this.minPrice,
            maxPrice: maxPrice ?? this.maxPrice,
        );
}

/// The filter sheet: V2's panel, as a sheet because that is where a phone puts it.
class StayFiltersSheet extends StatefulWidget {
    const StayFiltersSheet({
        required this.filters,
        required this.priceFloor,
        required this.priceCeiling,
        required this.matching,
        super.key,
    });

    final StayFilters filters;

    /// The cheapest and dearest stay found, which is what the price slider spans. V2 only
    /// knows these once results have streamed, and so does this.
    final double priceFloor;
    final double priceCeiling;

    /// How many stays the current choice leaves, recounted as it changes.
    final int Function(StayFilters) matching;

    @override
    State<StayFiltersSheet> createState() => _StayFiltersSheetState();
}

class _StayFiltersSheetState extends State<StayFiltersSheet> {
    late StayFilters _draft = widget.filters;

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;
        final skin = StaySkin.of(context);
        final floor = widget.priceFloor;
        final ceiling = widget.priceCeiling;
        final low = _draft.minPrice.isFinite ? _draft.minPrice.clamp(floor, ceiling) : floor;
        final high = _draft.maxPrice.isFinite ? _draft.maxPrice.clamp(floor, ceiling) : ceiling;

        return SafeArea(
            top: false,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Center(
                            child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                    color: skin.hairline,
                                    borderRadius: BorderRadius.circular(999),
                                ),
                            ),
                        ),
                        const SizedBox(height: 18),
                        _Heading('Sort By', skin: skin),
                        const SizedBox(height: 10),
                        // The five V2 offers, in V2's order.
                        Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                                for (final option in StaySort.values)
                                    _Chip(
                                        label: option.label,
                                        selected: _draft.sort == option,
                                        skin: skin,
                                        onTap: () => setState(() => _draft = _draft.copyWith(sort: option)),
                                    ),
                            ],
                        ),
                        const SizedBox(height: 22),
                        _Heading('Star Rating', skin: skin),
                        const SizedBox(height: 10),
                        Wrap(
                            spacing: 8,
                            children: [
                                for (final star in [5, 4, 3, 2, 1])
                                    _Chip(
                                        label: t.search_results_starSuffix(star),
                                        selected: _draft.stars.contains(star),
                                        skin: skin,
                                        onTap: () => setState(() {
                                            final next = Set<int>.of(_draft.stars);
                                            next.contains(star) ? next.remove(star) : next.add(star);
                                            _draft = _draft.copyWith(stars: next);
                                        }),
                                    ),
                            ],
                        ),
                        if (ceiling > floor) ...[
                            const SizedBox(height: 22),
                            _Heading(t.hotels_filters_adjustPrice, skin: skin),
                            RangeSlider(
                                values: RangeValues(low.toDouble(), high.toDouble()),
                                min: floor,
                                max: ceiling,
                                onChanged: (v) => setState(() => _draft = _draft.copyWith(
                                    minPrice: v.start,
                                    maxPrice: v.end,
                                )),
                            ),
                        ],
                        const SizedBox(height: 18),
                        Row(
                            children: [
                                TextButton(
                                    onPressed: () => setState(() => _draft = const StayFilters()),
                                    child: Text(t.hotels_filters_clear),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () => Navigator.of(context).pop(_draft),
                                    child: Text(t.search_v2_staysCount(widget.matching(_draft))),
                                  ),
                                ),
                            ],
                        ),
                    ],
                ),
            ),
        );
    }
}

class _Heading extends StatelessWidget {
    const _Heading(this.text, {required this.skin});

    final String text;
    final StaySkin skin;

    @override
    Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: skin.title),
    );
}

class _Chip extends StatelessWidget {
    const _Chip({required this.label, required this.selected, required this.skin, required this.onTap});

    final String label;
    final bool selected;
    final StaySkin skin;
    final VoidCallback onTap;

    @override
    Widget build(BuildContext context) {
        return Material(
            color: selected ? skin.chipBg : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: selected ? Colors.transparent : skin.hairline),
                    ),
                    child: Text(
                        label,
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: selected ? skin.chipText : skin.title,
                        ),
                    ),
                ),
            ),
        );
    }
}

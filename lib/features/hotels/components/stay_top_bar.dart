import 'package:flutter/material.dart';

import 'package:cheapest_go_mobile/features/hotels/components/stay_chrome.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/utils/currency.dart';

/// The toolbar over the search map, as V2's `SearchTopBar` arranges it. See #39.
///
/// It floats on the map rather than sitting above it, which is why it carries its own surface
/// and shadow instead of taking the page's. Two rows: what is being searched for, then the
/// controls that change how it is read — filters, currency, theme, and the map/list switch.
///
/// Two of V2's controls are not here. The nearby-places layer has no counterpart on mobile
/// yet, and the locale flag has nothing to drive: this app is pinned to English in `app.dart`
/// until a locale can be chosen. Both are their own piece of work rather than a stub here.
class StayTopBar extends StatelessWidget {
    const StayTopBar({
        required this.query,
        required this.dateLabel,
        required this.currency,
        required this.mapView,
        this.showBack = true,
        required this.onBack,
        required this.onEditSearch,
        required this.onEditDates,
        required this.onFilters,
        required this.onCurrency,
        required this.onToggleTheme,
        required this.onToggleView,
        this.filtersActive = false,
        super.key,
    });

    /// Where the search is pointed — the destination, as a person typed or picked it.
    final String query;

    /// The nights, already formatted, or null when none were chosen.
    final String? dateLabel;
    final String currency;

    /// True while the map is showing, which makes the switch offer the list.
    final bool mapView;

    /// False inside a tab, where there is nothing to go back to — the Stay & Play tab shows
    /// this screen without having navigated to it.
    final bool showBack;

    final VoidCallback onBack;
    final VoidCallback onEditSearch;
    final VoidCallback onEditDates;
    final VoidCallback onFilters;
    final ValueChanged<String> onCurrency;
    final VoidCallback onToggleTheme;
    final VoidCallback onToggleView;

    /// Marks the filter button when anything is narrowing the results.
    final bool filtersActive;

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;
        final skin = StaySkin.of(context);
        final dark = Theme.of(context).brightness == Brightness.dark;

        return Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            // V2's own: `p-2`, `rounded-[16px]`, `gap-x-1.5 gap-y-2` — the phone values, not
            // the `md:` ones.
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: skin.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                    BoxShadow(color: Color(0x1F000000), blurRadius: 18, offset: Offset(0, 6)),
                ],
            ),
            child: Column(
                children: [
                    Row(
                        children: [
                            if (showBack) ...[
                                _Round(
                                    icon: Icons.arrow_back_rounded,
                                    tooltip: t.common_goBack,
                                    skin: skin,
                                    onTap: onBack,
                                ),
                                const SizedBox(width: 8),
                            ],
                            Expanded(
                                child: GestureDetector(
                                    onTap: onEditSearch,
                                    child: Container(
                                        height: 42,
                                        padding: const EdgeInsets.symmetric(horizontal: 14),
                                        decoration: BoxDecoration(
                                            // A step darker than the controls beside it, which
                                            // is what makes it read as a field rather than
                                            // another button — V2 states the same three tones.
                                            color: dark ? const Color(0xFF111111) : const Color(0xFFF1F3F6),
                                            borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Row(
                                            children: [
                                                Icon(Icons.search_rounded, size: 17, color: skin.muted),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                    child: Text(
                                                        query.isEmpty ? t.search_results_whereTo : query,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w600,
                                                            color: query.isEmpty ? skin.muted : skin.title,
                                                        ),
                                                    ),
                                                ),
                                            ],
                                        ),
                                    ),
                                ),
                            ),
                            const SizedBox(width: 6),
                            // The stay — dates and guests — beside the place it belongs to,
                            // as V2 puts it. The field takes the leftover width (`flex 1 1
                            // 0%` there) so this pill keeps its own.
                            // Flexible, so the pair shares the row: at the narrowest widths
                            // the dates keep their place and give up characters instead of
                            // pushing the field past the bar's edge.
                            Flexible(
                                child: _StayPill(
                                    label: dateLabel ?? t.search_results_anyWeek,
                                    skin: skin,
                                    onTap: onEditDates,
                                ),
                            ),
                        ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                        children: [
                            _Round(
                                icon: Icons.tune_rounded,
                                tooltip: t.flights_results_filters,
                                skin: skin,
                                onTap: onFilters,
                                marked: filtersActive,
                            ),
                            // V2 splits this row with a spacer: the map's own tools on the
                            // left under Back, and what the session is set to — currency,
                            // theme, view — on the right under the stay.
                            const Spacer(),
                            _CurrencyButton(currency: currency, skin: skin, onPick: onCurrency),
                            const SizedBox(width: 6),
                            _Round(
                                icon: dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                tooltip: dark ? t.property_v2_lightMode : t.property_v2_darkMode,
                                skin: skin,
                                onTap: onToggleTheme,
                            ),
                            const SizedBox(width: 6),
                            _Round(
                                icon: mapView ? Icons.format_list_bulleted_rounded : Icons.map_outlined,
                                tooltip: mapView ? t.search_listView : t.search_mapView,
                                skin: skin,
                                onTap: onToggleView,
                            ),
                        ],
                    ),
                ],
            ),
        );
    }
}

class _Round extends StatelessWidget {
    const _Round({
        required this.icon,
        required this.tooltip,
        required this.skin,
        required this.onTap,
        this.marked = false,
    });

    final IconData icon;
    final String tooltip;
    final StaySkin skin;
    final VoidCallback onTap;

    /// Filled rather than outlined: the control is doing something to the results.
    final bool marked;

    @override
    Widget build(BuildContext context) {
        return Tooltip(
            message: tooltip,
            child: Material(
                color: marked ? skin.chipBg : Colors.transparent,
                shape: CircleBorder(side: BorderSide(color: marked ? Colors.transparent : skin.hairline)),
                child: InkWell(
                    onTap: onTap,
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                        width: 38,
                        height: 38,
                        child: Icon(icon, size: 17, color: marked ? skin.chipText : skin.title),
                    ),
                ),
            ),
        );
    }
}

class _CurrencyButton extends StatelessWidget {
    const _CurrencyButton({required this.currency, required this.skin, required this.onPick});

    final String currency;
    final StaySkin skin;
    final ValueChanged<String> onPick;

    @override
    Widget build(BuildContext context) {
        return PopupMenuButton<String>(
            tooltip: AppLocalizations.of(context)!.account_preferences_displayCurrency,
            onSelected: onPick,
            position: PopupMenuPosition.under,
            itemBuilder: (context) => [
                for (final c in currencies)
                    PopupMenuItem(
                        value: c.code,
                        child: Text(
                            '${c.code} · ${c.label}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: c.code == currency ? FontWeight.w700 : FontWeight.w500,
                            ),
                        ),
                    ),
            ],
            child: Container(
                height: 38,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: skin.hairline),
                ),
                child: Text(
                    currency,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: skin.title),
                ),
            ),
        );
    }
}

/// The stay: the nights and how many are coming, as one control.
///
/// V2's `StayEditor` — "Nov 25 – 28 · 2 guests" — which opens the calendar and the guest
/// steppers. Here it hands back to the landing's own step search, which asks the same two
/// questions; a sheet of its own would be a second place to answer them.
class _StayPill extends StatelessWidget {
    const _StayPill({required this.label, required this.skin, required this.onTap});

    final String label;
    final StaySkin skin;
    final VoidCallback onTap;

    @override
    Widget build(BuildContext context) {
        return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                    height: 36,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: skin.hairline),
                    ),
                    child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: skin.title),
                    ),
                ),
            ),
        );
    }
}

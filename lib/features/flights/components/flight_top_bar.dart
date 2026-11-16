import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:cheapest_go_mobile/features/flights/components/flight_chrome.dart';
import 'package:cheapest_go_mobile/features/flights/components/route_picker.dart';
import 'package:cheapest_go_mobile/features/flights/components/trip_sheet.dart';
import 'package:cheapest_go_mobile/features/flights/lib/flight_search_query.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/utils/currency.dart';

/// The flight results toolbar, as V2's `FlightSearchTopBar` lays it out below `lg`.
///
/// Two rows. Back, the route (two airports either side of a swap) and the trip button on the
/// first; filters on the left of the second, the session's currency and theme on the right.
/// It stands in for the app header, as V2's does, so those controls are always drawn.
///
/// Like the hotel bar on mobile, it leaves out V2's language flag and account button: this
/// app is pinned to English until a locale can be chosen, and the account lives in Settings.
class FlightTopBar extends StatelessWidget {
  const FlightTopBar({
    required this.origin,
    required this.destination,
    required this.searching,
    required this.trip,
    required this.onBack,
    required this.onRoute,
    required this.onTrip,
    required this.filterCount,
    required this.filtersOpen,
    required this.onFilters,
    required this.currency,
    required this.onCurrency,
    required this.onToggleTheme,
    super.key,
  });

  /// As the link carries them — "Clark (CRK)", or a bare code.
  final String origin;
  final String destination;
  final bool searching;
  final Trip trip;
  final VoidCallback onBack;
  final void Function(String origin, String destination) onRoute;
  final ValueChanged<Trip> onTrip;
  final int filterCount;
  final bool filtersOpen;
  final VoidCallback onFilters;
  final String currency;
  final ValueChanged<String> onCurrency;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final skin = FlightSkin.of(context);
    final dark = skin == FlightSkin.dark;

    Future<void> pick(bool toDestination) async {
      final choice = await showAirportPicker(context, destination: toDestination, origin: origin);
      if (choice == null) return;
      final next = toDestination ? (origin, choice.title) : (choice.title, destination);
      // Picking re-runs the search at once; there is no half-changed route to hold.
      if (next.$1 != origin || next.$2 != destination) onRoute(next.$1, next.$2);
    }

    Widget end(String value, String label, bool toDestination) => Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => pick(toDestination),
          child: Text(
            shortPlaceLabel(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: toDestination ? TextAlign.left : TextAlign.left,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: skin.title),
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: dark ? const Color(0x8C000000) : const Color(0x290F172A),
            blurRadius: dark ? 28 : 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _Round(icon: LucideIcons.arrowLeft, tooltip: t.common_goBack, onTap: onBack),
              const SizedBox(width: 6),
              // The route: grows from nothing, so it takes what the row leaves.
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: skin.field,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: skin.hairline),
                  ),
                  child: Row(
                    children: [
                      end(origin, t.landing_search_from, false),
                      const SizedBox(width: 6),
                      Tooltip(
                        message: t.flights_topBar_swap,
                        child: Material(
                          color: skin.hover,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => onRoute(destination, origin),
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: Icon(LucideIcons.arrowLeftRight, size: 13, color: skin.title),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      end(destination, t.landing_search_to, true),
                      if (searching)
                        SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: skin.title,
                            backgroundColor: skin.hairline,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // The trip, beside the route it belongs to. An icon on a phone; its
              // label is the accessible name, as V2's `aria-label`.
              Tooltip(
                message: t.flights_topBar_changeTrip,
                child: Semantics(
                  button: true,
                  label: tripLabel(t, trip),
                  excludeSemantics: true,
                  child: Material(
                    color: skin.field,
                    shape: StadiumBorder(side: BorderSide(color: skin.hairline)),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () async {
                        final next = await showTripSheet(context, trip);
                        if (next != null) onTrip(next);
                      },
                      child: SizedBox(
                        height: 36,
                        width: 40,
                        child: Icon(LucideIcons.calendarDays, size: 15, color: skin.title),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Round(
                icon: LucideIcons.slidersHorizontal,
                tooltip: t.flights_results_filters,
                onTap: onFilters,
                lit: filtersOpen || filterCount > 0,
                dot: filterCount > 0,
              ),
              const Spacer(),
              _CurrencyButton(currency: currency, onPick: onCurrency),
              const SizedBox(width: 6),
              _Round(
                icon: dark ? LucideIcons.sun : LucideIcons.moon,
                tooltip: dark ? t.property_v2_lightMode : t.property_v2_darkMode,
                onTap: onToggleTheme,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A round control on the bar — 36px on a phone. "Lit" is the brand gradient, V2's on-state.
class _Round extends StatelessWidget {
  const _Round({required this.icon, required this.tooltip, required this.onTap, this.lit = false, this.dot = false});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool lit;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final skin = FlightSkin.of(context);
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            child: Ink(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: lit ? FlightSkin.gradient : null,
                color: lit ? null : skin.control,
                border: Border.all(color: lit ? Colors.transparent : skin.hairline),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: Icon(icon, size: 16, color: lit ? Colors.white : skin.title),
              ),
            ),
          ),
          if (dot)
            Positioned(
              top: 1,
              right: 1,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2563EB), width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CurrencyButton extends StatelessWidget {
  const _CurrencyButton({required this.currency, required this.onPick});

  final String currency;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final skin = FlightSkin.of(context);
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
              style: TextStyle(fontSize: 13, fontWeight: c.code == currency ? FontWeight.w700 : FontWeight.w500),
            ),
          ),
      ],
      child: Container(
        height: 36,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: skin.control,
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

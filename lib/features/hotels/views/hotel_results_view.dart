import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/components/airport_picker.dart';
import 'package:cheapest_go_mobile/shared/components/ui_kit.dart';
import 'package:cheapest_go_mobile/shared/stores/saved_store.dart';
import 'package:cheapest_go_mobile/shared/stores/trip_search_store.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_radius.dart';
import 'package:cheapest_go_mobile/shared/utils/format.dart';

enum _Sort { nearest, price }

/// Stays near the searched arrival airport, v1 property-card style.
class HotelResultsView extends StatefulWidget {
  const HotelResultsView({this.catalog = travelCatalog, this.showBack = true, super.key});

  final TravelCatalog catalog;

  /// False when shown inside a tab rather than opened as a page.
  final bool showBack;

  @override
  State<HotelResultsView> createState() => _HotelResultsViewState();
}

class _HotelResultsViewState extends State<HotelResultsView> {
  _Sort _sort = _Sort.nearest;
  bool _shuttleOnly = false;
  bool _ratedOnly = false;

  List<Hotel> _results(String code) {
    final list = widget.catalog.hotelsNear(code).where((h) {
      if (_shuttleOnly && !h.hasShuttle) return false;
      if (_ratedOnly && h.score < 8) return false;
      return true;
    }).toList();
    if (_sort == _Sort.price) list.sort((a, b) => a.fromRate.compareTo(b.fromRate));
    return list;
  }

  Widget _searchPill(BuildContext context, TripSearchStore s) {
    final c = context.colors;
    return Material(
      color: c.surface,
      shape: StadiumBorder(side: BorderSide(color: c.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () async {
          final code = await showAirportPicker(context, selected: s.airportCode, catalog: widget.catalog);
          if (code != null) s.setAirport(code);
        },
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(Icons.search_rounded, size: 18, color: c.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${s.airportCode} · ${formatDateRange(s.checkIn, s.checkOut)} · ${plural(s.adults, 'guest')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.expand_more_rounded, color: c.textMuted),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([tripSearchStore, savedStaysStore]),
      builder: (context, _) {
        final s = tripSearchStore;
        final results = _results(s.airportCode);
        return SafeArea(
          bottom: false,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Row(
                spacing: 8,
                children: [
                  if (widget.showBack)
                    CircleIconButton(
                      icon: Icons.chevron_left_rounded,
                      tooltip: 'Back',
                      onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                    ),
                  Expanded(child: _searchPill(context, s)),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    FilterPill(
                      label: 'Nearest to terminal',
                      selected: _sort == _Sort.nearest,
                      onTap: () => setState(() => _sort = _Sort.nearest),
                    ),
                    const SizedBox(width: 8),
                    FilterPill(
                      label: 'Lowest price',
                      selected: _sort == _Sort.price,
                      onTap: () => setState(() => _sort = _Sort.price),
                    ),
                    const SizedBox(width: 8),
                    FilterPill(
                      label: 'Free shuttle',
                      selected: _shuttleOnly,
                      onTap: () => setState(() => _shuttleOnly = !_shuttleOnly),
                    ),
                    const SizedBox(width: 8),
                    FilterPill(
                      label: 'Rating 8+',
                      selected: _ratedOnly,
                      onTap: () => setState(() => _ratedOnly = !_ratedOnly),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              UiLabel('${plural(results.length, 'stay')} near ${s.airportCode}'),
              const SizedBox(height: 10),
              if (results.isEmpty)
                EmptyState(
                  icon: Icons.filter_alt_off_outlined,
                  title: 'No stays match',
                  message: 'Clear a filter to see more stays near ${s.airportCode}.',
                  action: OutlinedButton(
                    onPressed: () => setState(() {
                      _shuttleOnly = false;
                      _ratedOnly = false;
                    }),
                    child: const Text('Clear filters'),
                  ),
                ),
              for (final h in results) ...[
                HotelCard(
                  hotel: h,
                  saved: savedStaysStore.isSaved(h.id),
                  onToggleSaved: () => savedStaysStore.toggle(h.id),
                  onTap: () => context.push('/hotel/${h.id}'),
                ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// v1 property card: photo with badge and save button, then name, distance,
/// tags, rating, and nightly price.
class HotelCard extends StatelessWidget {
  const HotelCard({
    required this.hotel,
    required this.saved,
    required this.onToggleSaved,
    required this.onTap,
    super.key,
  });

  final Hotel hotel;
  final bool saved;
  final VoidCallback onToggleSaved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: EdgeInsets.zero,
      clip: true,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 150,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PhotoPlaceholder(image: hotel.cover, label: hotel.name, radius: 0, fade: true),
                if (hotel.badge != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: c.accent, borderRadius: AppRadius.brPill),
                      child: Text(hotel.badge!, style: TextStyle(color: c.accentOn, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: IconButton(
                    tooltip: saved ? 'Remove from saved' : 'Save hotel',
                    onPressed: onToggleSaved,
                    style: IconButton.styleFrom(backgroundColor: c.surface.withValues(alpha: 0.9)),
                    icon: Icon(
                      saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 20,
                      color: saved ? c.error : c.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hotel.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                PinLine(hotel.distanceLabel),
                const SizedBox(height: 8),
                Wrap(spacing: 4, runSpacing: 4, children: [for (final t in hotel.tags) TagChip(t)]),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    RatingBadge(hotel.score),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${hotel.scoreLabel} · ${hotel.reviews} reviews',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        PriceText(hotel.fromRate, size: 18),
                        Text('per night · taxes extra', style: TextStyle(fontSize: 11, color: c.textMuted)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:cheapest_go_mobile/features/hotels/components/nearby_icons.dart';
import 'package:cheapest_go_mobile/features/hotels/components/nearby_map.dart';
import 'package:cheapest_go_mobile/features/hotels/components/stay_chrome.dart';
import 'package:cheapest_go_mobile/shared/search/nearby_api.dart';

/// What is around the property: the places, filtered by what they are. See #40.
///
/// V2 draws this as a map with a strip of place cards beside it and a details modal over the
/// top. On a phone the strip is the subject — a map this small says little that the distance
/// on each card does not — so the places lead and the map is left to the search screen, which
/// is where a traveller is choosing *where* rather than *what is nearby*.
///
/// Nothing is invented when the endpoint has nothing to say: api-v2 answers 503 without a
/// Places key, and an empty answer removes the section rather than showing an empty frame.
class NearbyExplorer extends StatefulWidget {
    const NearbyExplorer({
        required this.latitude,
        required this.longitude,
        this.api,
        super.key,
    });

    final double latitude;
    final double longitude;

    /// Replaced in tests.
    final NearbyApi? api;

    @override
    State<NearbyExplorer> createState() => _NearbyExplorerState();
}

class _NearbyExplorerState extends State<NearbyExplorer> {
    NearbyCategory _category = NearbyCategory.all;
    List<NearbyPlace> _places = const [];
    bool _looking = true;

    /// The place a pin or a card has picked. The two surfaces show one selection between
    /// them: tapping a pin brings its card to the front of the strip, and tapping a card
    /// lights its pin.
    String? _selectedId;
    final _strip = ScrollController();

    /// Which ask is current, so a slow answer for a category nobody is looking at any more
    /// cannot replace the one on screen.
    int _ask = 0;

    @override
    void initState() {
        super.initState();
        _load();
    }

    /// One selection between the map and the strip: a pin brings its card to the front, a
    /// card lights its pin.
    void _select(NearbyPlace place) {
        setState(() => _selectedId = place.id);
        final index = _places.indexWhere((p) => p.id == place.id);
        if (index < 0 || !_strip.hasClients) return;
        _strip.animateTo(
            (index * 202).clamp(0, _strip.position.maxScrollExtent).toDouble(),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
        );
    }

    Future<void> _load() async {
        final ask = ++_ask;
        setState(() => _looking = true);

        final found = await (widget.api ?? nearbyApi).around(
            widget.latitude,
            widget.longitude,
            category: _category,
        );

        if (!mounted || ask != _ask) return;
        setState(() {
            _places = found;
            _looking = false;
        });
    }

    @override
    Widget build(BuildContext context) {
        final skin = StaySkin.of(context);

        // Nothing to show and nothing being fetched: the section is not part of the page.
        if (!_looking && _places.isEmpty && _category == NearbyCategory.all) {
            return const SizedBox.shrink();
        }

        return Padding(
            padding: const EdgeInsets.only(top: 28),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                            "What's nearby",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: skin.title),
                        ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                        height: 36,
                        child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: NearbyCategory.values.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                                final category = NearbyCategory.values[i];
                                return _Filter(
                                    label: category.label,
                                    icon: iconForCategory(category),
                                    selected: category == _category,
                                    skin: skin,
                                    onTap: () {
                                        if (category == _category) return;
                                        setState(() => _category = category);
                                        _load();
                                    },
                                );
                            },
                        ),
                    ),
                    const SizedBox(height: 14),
                    // The map, then the places. V2 puts them side by side; a phone has one
                    // column, and the map goes first because it answers "where" at a glance.
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: NearbyMap(
                            latitude: widget.latitude,
                            longitude: widget.longitude,
                            places: _places,
                            selectedId: _selectedId,
                            onSelect: _select,
                        ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                        height: 184,
                        child: _looking
                            ? const Center(child: CircularProgressIndicator())
                            : _places.isEmpty
                                ? Center(
                                    child: Text(
                                        'Nothing of this kind nearby',
                                        style: TextStyle(fontSize: 13, color: skin.muted),
                                    ),
                                )
                                : ListView.separated(
                                    controller: _strip,
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    itemCount: _places.length,
                                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                                    itemBuilder: (context, i) => _PlaceCard(
                                        place: _places[i],
                                        origin: (widget.latitude, widget.longitude),
                                        selected: _places[i].id == _selectedId,
                                        onTap: () => _select(_places[i]),
                                        skin: skin,
                                    ),
                                ),
                    ),
                ],
            ),
        );
    }
}

class _PlaceCard extends StatelessWidget {
    const _PlaceCard({
        required this.place,
        required this.origin,
        required this.selected,
        required this.onTap,
        required this.skin,
    });

    final NearbyPlace place;

    /// The property, which is what "400 m" is measured from.
    final (double, double) origin;
    final bool selected;
    final VoidCallback onTap;
    final StaySkin skin;

    @override
    Widget build(BuildContext context) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: 190,
            decoration: BoxDecoration(
                color: skin.surface,
                borderRadius: BorderRadius.circular(16),
                // The chosen place is outlined rather than filled: it is still a card to
                // read, and a filled one competes with the room cards above it.
                border: Border.all(
                    color: selected ? const Color(0xFF06B6D4) : skin.hairline,
                    width: selected ? 2 : 1,
                ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    SizedBox(
                        height: 96,
                        width: double.infinity,
                        child: ColoredBox(
                            color: skin.imageBg,
                            child: Icon(iconForPoi(place.category), size: 26, color: skin.muted),
                        ),
                    ),
                    Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                    place.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: skin.title,
                                    ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                    // How far it is, and what it is — the two things that
                                    // decide whether a place is worth walking to.
                                    [
                                        _distance(origin, place),
                                        if (place.rating != null) '★ ${place.rating!.toStringAsFixed(1)}',
                                    ].join(' · '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 11.5, color: skin.muted),
                                ),
                            ],
                        ),
                    ),
                ],
            ),
          ),
        );
    }

    /// Metres under a kilometre, kilometres over it — as a person would say it.
    static String _distance((double, double) from, NearbyPlace to) {
        const metresPerDegree = 111320.0;
        final dLat = (to.latitude - from.$1) * metresPerDegree;
        final dLng = (to.longitude - from.$2) * metresPerDegree * 0.85;
        final distance = math.sqrt(dLat * dLat + dLng * dLng);
        if (distance < 1000) return '${distance.round()} m';
        return '${(distance / 1000).toStringAsFixed(1)} km';
    }

}

class _Filter extends StatelessWidget {
    const _Filter({
        required this.label,
        required this.icon,
        required this.selected,
        required this.skin,
        required this.onTap,
    });

    final String label;
    final IconData icon;
    final bool selected;
    final StaySkin skin;
    final VoidCallback onTap;

    @override
    Widget build(BuildContext context) {
        return Material(
            color: selected ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: selected ? Colors.transparent : skin.hairline),
                    ),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            // The same glyph marks the filter and the places it finds, so
                            // the key is learned once.
                            Icon(icon, size: 13, color: selected ? Colors.white : skin.muted),
                            const SizedBox(width: 6),
                            Text(
                                label,
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: selected ? Colors.white : skin.title,
                                ),
                            ),
                        ],
                    ),
                ),
            ),
        );
    }
}

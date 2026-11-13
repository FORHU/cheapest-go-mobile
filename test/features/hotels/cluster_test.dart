import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/features/hotels/components/stay_map.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';

/// What the number on a cluster promises. See #39 and #40.
///
/// A pin reading "2" says two stays are under it, and zooming in has to produce those two —
/// not three, and not one. The counts are the only thing on the map a traveller can add up,
/// so they are the thing to pin down.
void main() {
    Hotel at(String id, double lat, double lng, {int rate = 1000}) => Hotel(
        id: id,
        airportCode: 'MNL',
        name: id,
        area: 'Manila',
        distanceKm: 1,
        distanceFrom: 'Terminal',
        score: 8,
        reviews: 10,
        tags: const [],
        latitude: lat,
        longitude: lng,
        // The pin quotes the cheapest room, so the rate lives on one.
        rooms: [Room(id: '-r', name: 'Room', meta: 'Room only', nightlyRate: rate)],
    );

    /// Roughly 111 m to a thousandth of a degree of latitude.
    final stays = [
        at('a', 14.5900, 120.9800),
        at('b', 14.5901, 120.9801),  // ~14 m from a
        at('c', 14.6000, 120.9900),  // ~1.4 km from a
        at('d', 14.6001, 120.9901),  // ~14 m from c
    ];

    test('every stay is in exactly one group, whatever the radius', () {
        for (final radius in [0.0, 50.0, 500.0, 5000.0, 50000.0]) {
            final groups = groupNearbyStays(stays, radiusMetres: radius);
            final ids = [for (final group in groups) ...group.map((h) => h.id)];

            expect(ids.length, stays.length, reason: 'radius $radius lost or duplicated a stay');
            expect(ids.toSet().length, stays.length, reason: 'radius $radius drew one twice');
        }
    });

    test('the number on a pin is the number of stays under it', () {
        final groups = groupNearbyStays(stays, radiusMetres: 500);

        expect(groups.map((g) => g.length).toList(), [2, 2]);
        expect(groups.first.map((h) => h.id), ['a', 'b']);
        expect(groups.last.map((h) => h.id), ['c', 'd']);
    });

    test('zooming in parts a group into its own members, and only those', () {
        // A radius under the 14 m between them is what zooming in amounts to.
        final apart = groupNearbyStays(stays, radiusMetres: 5);

        expect(apart.map((g) => g.length).toList(), [1, 1, 1, 1]);
    });

    test('a pin marked "2" expands to two, while its neighbour parts at the same time', () {
        // The question this answers: tapping a "2" can leave four pins in view, which looks
        // like a miscount and is not. The tapped pair becomes two pins; the pair beside it
        // crosses the same threshold on the same zoom and becomes two more.
        final before = groupNearbyStays(stays, radiusMetres: 500);
        expect(before.every((g) => g.length == 2), isTrue);

        final after = groupNearbyStays(stays, radiusMetres: 5);
        final tapped = before.first.map((h) => h.id).toSet();
        final fromTapped = after.where((g) => tapped.contains(g.first.id)).toList();

        expect(fromTapped.length, 2, reason: 'the tapped pin accounts for exactly its own two');
        expect(after.length, 4, reason: 'the other two come from the neighbouring pin');
    });

    test('stays at one coordinate stay together however far it is zoomed', () {
        // Nothing separates them, which is why the map selects the cheapest instead of
        // zooming forever — see `_onMarkerTap`.
        final stacked = [at('x', 14.59, 120.98), at('y', 14.59, 120.98)];

        expect(groupNearbyStays(stacked, radiusMetres: 0).single.length, 2);
    });

    test('the cheapest leads a group, because the pin quotes its price', () {
        final groups = groupNearbyStays([
            at('dear', 14.5900, 120.9800, rate: 9000),
            at('cheap', 14.5901, 120.9801, rate: 1200),
        ], radiusMetres: 500);

        expect(groups.single.first.id, 'cheap');
    });
}

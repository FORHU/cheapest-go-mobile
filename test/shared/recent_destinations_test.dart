import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cheapest_go_mobile/shared/search/recent_destinations.dart';

/// Where this person was looking last time.
///
/// Kept on the device and nowhere else — it is a convenience, not a record, so it needs no
/// account and nothing leaves the phone. What matters is the ordering and that a phone which
/// cannot store anything is not a phone that cannot search.
void main() {
    TestWidgetsFlutterBinding.ensureInitialized();

    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('nothing remembered is an empty list, not a failure', () async {
        expect(await RecentDestinations().read(), isEmpty);
    });

    test('most recent first', () async {
        final store = RecentDestinations();

        await store.remember('Cebu');
        await store.remember('Baguio');

        expect(await store.read(), ['Baguio', 'Cebu']);
    });

    /// Somewhere searched twice is one place, not two entries — and the spelling kept is the
    /// newest, because that is the one just confirmed.
    test('the same place twice moves it up rather than repeating it', () async {
        final store = RecentDestinations();

        await store.remember('Cebu');
        await store.remember('Baguio');
        await store.remember('cebu');

        expect(await store.read(), ['cebu', 'Baguio']);
    });

    test('keeps only the last few, so the chips cannot grow without end', () async {
        final store = RecentDestinations();

        for (final city in ['A', 'B', 'C', 'D', 'E', 'F', 'G']) {
            await store.remember(city);
        }

        final kept = await store.read();
        expect(kept, hasLength(RecentDestinations.max));
        expect(kept.first, 'G');
        expect(kept, isNot(contains('A')));
    });

    test('a blank name is not a place', () async {
        final store = RecentDestinations();
        await store.remember('Cebu');

        expect(await store.remember('   '), ['Cebu']);
    });

    /// A value left by an older version, or anything else that is not a list of strings.
    /// Reading it must not take the picker down with it.
    test('survives a stored value it does not recognise', () async {
        SharedPreferences.setMockInitialValues({'recent_destinations': '{"not":"a list"}'});

        expect(await RecentDestinations().read(), isEmpty);
    });

    test('clears', () async {
        final store = RecentDestinations();
        await store.remember('Cebu');

        await store.clear();

        expect(await store.read(), isEmpty);
    });
}

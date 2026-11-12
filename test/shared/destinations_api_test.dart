import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/shared/lib/http.dart';
import 'package:cheapest_go_mobile/shared/search/destinations_api.dart';

/// The "where" step's source. See #38.
///
/// Two endpoints answer it — the destination autocomplete for stays, the airport index for
/// flights — and they return different shapes, so the parsing is where this can go wrong
/// quietly: a dropped row reads as "no such place" rather than as a bug.
class _FakeClient extends HttpClientAdapter {
    _FakeClient(this.response);

    final dynamic response;
    String? lastPath;

    @override
    Future<dynamic> get(String path, {HttpRequestOptions? options}) async {
        lastPath = path;
        if (response is Exception) throw response as Exception;
        return response;
    }
}

void main() {
    test('asks the airport index for flights and the destinations list for stays', () async {
        final stays = _FakeClient({'data': []});
        await DestinationsApi(client: stays).search('seo');
        expect(stays.lastPath, contains('/hotels/destinations'));

        final flights = _FakeClient({'data': []});
        await DestinationsApi(client: flights).search('seo', forFlights: true);
        expect(flights.lastPath, contains('/airports/search'));
    });

    test('each endpoint is asked by the name it reads', () async {
        // api-v2 names the parameter differently on the two routes, and getting it wrong is
        // silent: `/hotels/destinations` answers 422 to `q`, the error is swallowed, and a
        // real city comes back as "No places match". Typing Manila did exactly that.
        final stays = _FakeClient({'data': []});
        await DestinationsApi(client: stays).search('manila');
        expect(stays.lastPath, contains('query=manila'));
        expect(stays.lastPath, isNot(contains('?q=')));

        final flights = _FakeClient({'data': []});
        await DestinationsApi(client: flights).search('manila', forFlights: true);
        expect(flights.lastPath, contains('q=manila'));
    });

    test('reads a destination row as the endpoint sends it', () async {
        // The shape api-v2 answers with: title is the place, subtitle says which one it is.
        final client = _FakeClient({
            'success': true,
            'data': [
                {
                    'type': 'city',
                    'rung': 'city',
                    'title': 'Manila',
                    'subtitle': 'Manila, Philippines',
                    'countryCode': 'PH',
                    'id': 'place.1057971',
                    'lat': 14.590449,
                    'lng': 120.980362,
                },
            ],
        });

        final found = await DestinationsApi(client: client).search('manila');

        expect(found, hasLength(1));
        expect(found.single.name, 'Manila', reason: 'not the Mapbox id');
        expect(found.single.city, 'Manila, Philippines');
        expect(found.single.kind, DestinationKind.city);
        // Carried so the search can be pointed at the place rather than at its name.
        expect(found.single.latitude, closeTo(14.590449, 0.000001));
        expect(found.single.longitude, closeTo(120.980362, 0.000001));
    });

    test('says nothing on one letter, so a keystroke is not a supplier lookup', () async {
        final client = _FakeClient({'data': []});
        expect(await DestinationsApi(client: client).search('s'), isEmpty);
        expect(client.lastPath, isNull, reason: 'no request was made at all');
    });

    test('reads a city', () async {
        final api = DestinationsApi(client: _FakeClient({
            'success': true,
            'data': [
                {'id': 'seoul', 'type': 'city', 'name': 'Seoul', 'countryCode': 'KR'},
            ],
        }));

        final [seoul] = await api.search('seoul');
        expect(seoul.kind, DestinationKind.city);
        expect(seoul.name, 'Seoul');
        expect(seoul.countryCode, 'KR');
        expect(seoul.isAirport, isFalse);
    });

    test('reads an airport, keeping its code as the id', () async {
        final api = DestinationsApi(client: _FakeClient({
            'data': [
                {'iata': 'ICN', 'name': 'Incheon International', 'city': 'Seoul', 'countryCode': 'KR'},
            ],
        }));

        final [icn] = await api.search('incheon', forFlights: true);
        expect(icn.isAirport, isTrue);
        expect(icn.id, 'ICN');
        expect(icn.iata, 'ICN');
        expect(icn.city, 'Seoul');
    });

    test('accepts a bare list as well as the wrapped shape', () async {
        final api = DestinationsApi(client: _FakeClient([
            {'id': 'tokyo', 'type': 'city', 'name': 'Tokyo'},
        ]));

        expect((await api.search('tokyo')).single.name, 'Tokyo');
    });

    test('drops a row with nothing to point a search at', () async {
        final api = DestinationsApi(client: _FakeClient({
            'data': [
                {'type': 'city'},
                {'id': 'bali', 'type': 'city', 'name': 'Bali'},
            ],
        }));

        expect((await api.search('ba')).map((d) => d.id), ['bali']);
    });

    test('a failed lookup is empty, not an exception in the middle of typing', () async {
        final api = DestinationsApi(client: _FakeClient(Exception('offline')));
        expect(await api.search('seoul'), isEmpty);
    });
}

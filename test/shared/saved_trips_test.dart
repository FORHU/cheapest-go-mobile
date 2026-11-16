import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/shared/lib/http.dart';
import 'package:cheapest_go_mobile/shared/saved/saved_trip.dart';
import 'package:cheapest_go_mobile/shared/saved/saved_trips_store.dart';

/// The shortlist, held against the account. See #43 and ADR-0004.
void main() {
  group('reading the shortlist', () {
    test('a stay knows where it opens in this app, not where it opens on the web', () {
      final trip = SavedTrip.fromJson({
        'id': 'row-1',
        'type': 'hotel',
        'title': 'Bayside Grand Manila',
        'price': '138.00',
        'currency': 'usd',
        'deep_link': '/property/MOCK-MNL-001',
        'snapshot': {'hotelId': 'MOCK-MNL-001'},
      });

      expect(trip.kind, SavedKind.hotel);
      // A Decimal column arrives as a string.
      expect(trip.price, 138);
      expect(trip.currency, 'USD');
      // deep_link is V2's path, written for the web's account page.
      expect(trip.deepLink, '/property/MOCK-MNL-001');
      // Mobile routes from the snapshot instead.
      expect(trip.route, '/hotel/MOCK-MNL-001');
    });

    test('a shortlist that cannot be read is empty, not broken', () async {
      final store = SavedTripsStore(client: _FakeHttp(fails: true));
      await store.refresh();

      expect(store.trips, isEmpty);
      expect(store.loaded, isTrue);
      expect(store.isSaved('anything'), isFalse);
    });
  });

  group('hearting a stay', () {
    late _FakeHttp http;
    late SavedTripsStore store;

    setUp(() {
      http = _FakeHttp();
      store = SavedTripsStore(client: http);
    });

    test('sends what the account screen needs to draw the row', () async {
      await store.toggleHotel(
        hotelId: 'MOCK-MNL-001',
        title: 'Bayside Grand Manila',
        subtitle: 'Malate',
        price: 138,
        currency: 'USD',
        imageUrl: 'https://pic',
      );

      final sent = http.posted.single;
      expect(sent['type'], 'hotel');
      expect(sent['title'], 'Bayside Grand Manila');
      expect(sent['price'], 138);
      // Identity lives in the snapshot, and the link is V2's path so the web can follow it.
      expect(sent['snapshot'], {'hotelId': 'MOCK-MNL-001'});
      expect(sent['deepLink'], '/property/MOCK-MNL-001');
      expect(store.isSaved('MOCK-MNL-001'), isTrue);
    });

    test('tapping a filled heart removes the row', () async {
      await store.toggleHotel(hotelId: 'MOCK-MNL-001', title: 'Bayside');
      expect(store.isSaved('MOCK-MNL-001'), isTrue);

      await store.toggleHotel(hotelId: 'MOCK-MNL-001', title: 'Bayside');

      expect(store.isSaved('MOCK-MNL-001'), isFalse);
      expect(http.deleted, ['/api/v2/bookings/saved-trips/row-1']);
    });

    // Signed out is the one refusal worth telling apart: it asks something of the traveller,
    // where a network failure asks nothing. The store reports it; the screen does the asking.
    test('signed out, it reports that nothing happened', () async {
      final refusing = SavedTripsStore(client: _FakeHttp(unauthorised: true));

      expect(await refusing.toggleHotel(hotelId: 'h1', title: 'A stay'), isFalse);
      expect(refusing.isSaved('h1'), isFalse);
    });

    test('any other failure is not reported as a sign-in problem', () async {
      final broken = SavedTripsStore(client: _FakeHttp(fails: true));

      expect(await broken.toggleHotel(hotelId: 'h1', title: 'A stay'), isTrue);
    });

    test('signing out forgets the shortlist', () async {
      await store.toggleHotel(hotelId: 'MOCK-MNL-001', title: 'Bayside');
      expect(store.trips, isNotEmpty);

      store.forget();

      // Otherwise one person's saved stays greet whoever signs in next on this phone.
      expect(store.trips, isEmpty);
      expect(store.loaded, isFalse);
    });
  });
}

/// api-v2, answering from memory.
class _FakeHttp implements HttpClientAdapter {
  _FakeHttp({this.fails = false, this.unauthorised = false});

  final bool fails;
  final bool unauthorised;

  final posted = <Map<String, dynamic>>[];
  final deleted = <String>[];
  var _next = 1;

  Never _refuse() {
    if (unauthorised) throw Exception('HTTP 401 Unauthorized');
    throw Exception('the network went away');
  }

  @override
  Future<dynamic> get(String url, {HttpRequestOptions? options}) async {
    if (fails || unauthorised) _refuse();
    return {'trips': <dynamic>[]};
  }

  @override
  Future<dynamic> post(String url, {Object? body, HttpRequestOptions? options}) async {
    if (fails || unauthorised) _refuse();
    final sent = (body as Map).cast<String, dynamic>();
    posted.add(sent);
    return {
      'success': true,
      'data': {
        'id': 'row-${_next++}',
        'type': sent['type'],
        'title': sent['title'],
        'subtitle': sent['subtitle'],
        'price': sent['price'],
        'currency': sent['currency'] ?? 'USD',
        'deep_link': sent['deepLink'],
        'snapshot': sent['snapshot'],
      },
    };
  }

  @override
  Future<dynamic> delete(String url, {Object? body, HttpRequestOptions? options}) async {
    if (fails || unauthorised) _refuse();
    deleted.add(url);
    return {'success': true};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

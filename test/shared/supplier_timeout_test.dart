import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cheapest_go_mobile/shared/catalog/api_travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/lib/http.dart';

/// How long a live supplier call is given before the app decides it failed.
///
/// Reported as "no results, then results": the stays screen showed "we can't reach the hotel
/// suppliers right now", **Try again** was pressed, and 250 stays came back in a second. The
/// supplier was never unreachable. A cold search on production was measured three times at
/// 20.5s, 21.4s and 32.6s, against a 30-second client default — the third one was cut off
/// while the server was still working, and the answer it eventually produced went into the
/// server's cache, which is what made the retry instant.
///
/// Thirty seconds is a reasonable wait on our own database and not one on a live availability
/// search, so the three calls that go out to a supplier say so.
class _Recorder extends HttpClientAdapter {
  final waits = <String, Duration>{};

  @override
  Future<dynamic> get(String url, {HttpRequestOptions options = const HttpRequestOptions()}) async {
    waits[url.split('?').first] = options.timeout;
    return <String, dynamic>{};
  }

  @override
  Future<dynamic> post(
    String url, {
    Object? body,
    HttpRequestOptions options = const HttpRequestOptions(),
  }) async {
    waits[url.split('?').first] = options.timeout;
    return <String, dynamic>{'data': <dynamic>[], 'offers': <dynamic>[]};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Recorder client;
  late ApiTravelCatalog catalog;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    client = _Recorder();
    catalog = ApiTravelCatalog(client: client);
  });

  /// A cold one took 32.6 seconds, so anything at or under the old default is still a screen
  /// that lies about the supplier.
  test('a stay search is allowed to take longer than the old default', () async {
    await catalog.fetchHotels('MNL');

    final wait = client.waits['/api/v2/hotels/search'];
    expect(wait, isNotNull, reason: 'the search was not made');
    expect(wait!.inSeconds, greaterThan(const HttpRequestOptions().timeout.inSeconds));
    expect(wait.inSeconds, greaterThan(40));
  });

  /// Both of the others ask a supplier too, and both were on the same thirty seconds.
  test('so are a property and a flight search', () async {
    await catalog.fetchHotel('13143275');
    await catalog.fetchFlights('MNL', 'ICN');

    expect(client.waits['/api/v2/hotels/property/13143275']!.inSeconds, greaterThan(40));
    expect(client.waits['/api/v2/flights/search']!.inSeconds, greaterThan(40));
  });

  /// Not so long that a handset with no signal sits on a spinner forever, and under the edge's
  /// own hundred — past that the network gives up first and the wait buys nothing.
  test('and none of them waits past the edge', () async {
    await catalog.fetchHotels('MNL');

    expect(client.waits['/api/v2/hotels/search']!.inSeconds, lessThan(100));
  });
}

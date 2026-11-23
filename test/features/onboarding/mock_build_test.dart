import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/features/onboarding/api/onboarding_api.dart';
import 'package:cheapest_go_mobile/shared/lib/env.dart';
import 'package:cheapest_go_mobile/shared/lib/http.dart';

/// A server that is not there, and counts every time it is asked anyway.
class _NoServer implements HttpClientAdapter {
  int calls = 0;

  Never _refuse() => throw StateError('a mock build has no server to ask');

  @override
  Future<dynamic> get(String url, {HttpRequestOptions? options}) async {
    calls++;
    _refuse();
  }

  @override
  Future<dynamic> patch(String url, {Object? body, HttpRequestOptions? options}) async {
    calls++;
    _refuse();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The demo APK signs its user in on the handset and never calls `/api/v2/auth`, so there is
/// no account on any server to hold their preferences. Account data has to know that: the
/// startup gate reads a failure here as "the app cannot start", and a demo build that asks
/// anyway dead-ends on the sign-in it has just completed — a retry that can never work above
/// a sign-out that leads back to the same wall.
void main() {
  test('a mock build never asks the server about the account', () async {
    expect(kMockAuth, isTrue, reason: 'the default build is the demo one');

    final client = _NoServer();
    final api = OnboardingApi(client: client);

    expect(await api.getPreferences(), isEmpty);
    expect(await api.getDetails(), isEmpty);
    expect(await api.savePreferences({'language': 'ko'}), {'language': 'ko'});
    await api.saveDetails(nationality: 'KR');

    expect(client.calls, 0, reason: 'nothing to ask, so nothing was asked');
  });
}

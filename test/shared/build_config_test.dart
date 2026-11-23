import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/shared/lib/env.dart';

/// Mock auth and a real API is a build that cannot work, and one nobody meant to make.
///
/// `.env.devapi` points at dev and says nothing about auth. While `kMockAuth` defaulted to
/// true on its own, every QA build signed a demo user in on the handset and then asked the
/// server about them. No token was ever stored, so: Trips told somebody who had just signed
/// in that they were not signed in, hotel checkout died on a 401 as "Session expired", and
/// flight checkout threw the traveller out after they had filled the whole form. Three
/// reports, one missing flag, and nothing in the code that could have caught it.
///
/// Now the default follows the catalogue. This test is the thing that notices if that is
/// ever unpicked — it cannot read another build's flags, but it can hold the rule that
/// relates them.
void main() {
  test('auth is mocked only when the data is', () {
    expect(
      kMockAuth,
      kCatalogMode == 'mock',
      reason:
          'a build talking to api-v2 must authenticate against it; a build on the '
          'compiled-in catalogue has no server to authenticate against',
    );
  });

  test('the test suite itself runs on the mock pair', () {
    // No --dart-define under `flutter test`, so this is the default build: both mocked.
    // If this fails, the defaults moved and every test asserting demo-account behaviour is
    // quietly testing something else.
    expect(kCatalogMode, 'mock');
    expect(kMockAuth, isTrue);
  });
}

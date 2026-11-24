import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cheapest_go_mobile/features/auth/api/google_identity.dart';
import 'package:cheapest_go_mobile/features/auth/stores/auth_store.dart';

/// Signing in with Google. See #45.
///
/// The account picker is a platform view behind a method channel, so [GoogleIdentity] is the
/// seam and this drives the half that is ours: what the store does with what Google says.
void main() {
  late GoogleIdentity real;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    real = googleIdentity;
  });

  tearDown(() => googleIdentity = real);

  test('backing out of the picker is not a failure and says nothing', () async {
    googleIdentity = _FakeGoogle(token: null);
    final store = AuthStore(mock: false);

    expect(await store.signInWithGoogle(), isFalse);
    expect(store.errorMessage, isNull,
        reason: 'they changed their mind; there is nothing wrong to report');
    expect(store.isAuthenticated, isFalse);
  });

  /// A build with no client id is a deployment fact, and the person holding the phone can do
  /// nothing with it. They are told something went wrong — in their own language — rather than
  /// being handed the name of a setting. It used to say "not configured" in English, under a
  /// Korean heading, which is how this was noticed.
  test('a build with no client id reports it in the traveller\'s language', () async {
    googleIdentity = _FakeGoogle(notConfigured: true);
    final store = AuthStore(mock: false);

    expect(await store.signInWithGoogle(), isFalse);
    expect(store.errorMessage, isNotNull, reason: 'the attempt failed and must say so');
    expect(store.errorMessage, isNot(contains('configured')),
        reason: 'no deployment vocabulary in front of a traveller');
  });

  test('signing out lets go of the Google account too', () async {
    final google = _FakeGoogle(token: null);
    googleIdentity = google;

    await AuthStore(mock: true).logout();
    // Otherwise the next sign-in silently picks the same account, with no way to choose
    // another — which looks like being unable to sign out.
    expect(google.forgotten, isTrue);
  });
}

class _FakeGoogle implements GoogleIdentity {
  _FakeGoogle({this.token, this.notConfigured = false});

  final String? token;
  final bool notConfigured;
  bool forgotten = false;

  @override
  Future<String?> idToken() async {
    if (notConfigured) throw const GoogleNotConfigured();
    return token;
  }

  @override
  Future<void> forget() async => forgotten = true;
}

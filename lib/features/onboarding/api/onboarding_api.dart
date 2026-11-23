import 'package:cheapest_go_mobile/shared/lib/env.dart';
import 'package:cheapest_go_mobile/shared/lib/http.dart';
import 'package:cheapest_go_mobile/features/onboarding/lib/onboarding_markers.dart';

/// The account's preferences and travel details. See #62.
///
/// Two endpoints, because they are two things to the server: preferences are a JSON blob the
/// web shares, details are columns on `users` and `profiles`.
class OnboardingApi {
  OnboardingApi({HttpClientAdapter? client}) : _client = client ?? http;

  final HttpClientAdapter _client;

  // The same options every other account-data call uses (bookings, saved trips).
  static const _signedIn = HttpRequestOptions(useMobileApiKey: true, requiresAuth: true);

  /// Everything stored under preferences, markers included.
  ///
  /// Nothing to ask for in a mock build: the demo user is signed in on the handset alone, so
  /// there is no account on any server to hold preferences. The request cannot succeed, and
  /// the startup gate reads a failure here as "the app cannot start" — which is how a demo
  /// APK came to dead-end on the very sign-in it had just completed, with a retry that could
  /// never work and a sign-out that led back to the same wall.
  Future<Map<String, dynamic>> getPreferences() async {
    if (kMockAuth) return <String, dynamic>{};
    final res = await _client.get('/api/v2/users/preferences', options: _signedIn);
    final prefs = (res as Map<String, dynamic>?)?['preferences'];
    return prefs is Map<String, dynamic> ? prefs : <String, dynamic>{};
  }

  /// Writes preferences back **whole**.
  ///
  /// api-v2 replaces rather than merges — `users.repository.ts` is explicit that "a key it
  /// omits is a key it deleted" — so every caller here passes the entire blob it wants stored.
  /// This is why [saveOnboarding] re-reads before writing: sending only the markers would
  /// silently delete the display currency somebody chose in the browser.
  Future<Map<String, dynamic>> savePreferences(Map<String, dynamic> preferences) async {
    // Accepted and kept in hand, for the same reason the read is skipped: there is nowhere
    // to write. Returning what was asked for keeps onboarding finishing rather than failing
    // on its last step.
    if (kMockAuth) return preferences;
    final res = await _client.patch(
      '/api/v2/users/preferences',
      body: preferences,
      options: _signedIn,
    );
    final prefs = (res as Map<String, dynamic>?)?['preferences'];
    return prefs is Map<String, dynamic> ? prefs : preferences;
  }

  /// Stores the chosen preferences and marks onboarding finished, in one write.
  ///
  /// Read first, then merge: what is on the server may include keys this app has never heard
  /// of, and they have to survive. The markers are merged last so the start the server wrote
  /// at account creation is carried through rather than dropped.
  Future<OnboardingMarkers> saveOnboarding(Map<String, dynamic> chosen) async {
    final existing = await getPreferences();
    final markers = OnboardingMarkers.fromPreferences(existing);

    final merged = <String, dynamic>{
      ...existing,
      ...chosen,
      OnboardingMarkers.key: markers.completedNow(),
    };

    return OnboardingMarkers.fromPreferences(await savePreferences(merged));
  }

  /// Birth date, phone and nationality held against the account.
  Future<Map<String, dynamic>> getDetails() async {
    if (kMockAuth) return <String, dynamic>{};
    final res = await _client.get('/api/v2/users/details', options: _signedIn);
    final details = (res as Map<String, dynamic>?)?['details'];
    return details is Map<String, dynamic> ? details : <String, dynamic>{};
  }

  /// Saves any subset of the details. A field left out is left as it was, not blanked.
  Future<void> saveDetails({String? birthDate, String? phone, String? nationality}) async {
    final body = <String, dynamic>{
      if (birthDate != null && birthDate.isNotEmpty) 'birthDate': birthDate,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (nationality != null && nationality.isNotEmpty) 'nationality': nationality,
    };
    // Nothing filled in is a legitimate outcome: the details step may be skipped. The server
    // refuses an empty update, so there is nothing to send. Nor is there anywhere to send it
    // in a mock build, where the account exists only on this handset.
    if (body.isEmpty || kMockAuth) return;

    await _client.patch('/api/v2/users/details', body: body, options: _signedIn);
  }
}

final OnboardingApi onboardingApi = OnboardingApi();

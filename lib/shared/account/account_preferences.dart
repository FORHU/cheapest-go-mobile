import 'package:cheapest_go_mobile/shared/lib/http.dart';

/// The account's preferences blob, as api-v2 keeps it.
///
/// In `shared/` because more than one feature stores something here — onboarding's markers
/// (#62) and which Tips an account has been shown (ADR-0006) — and a feature may not import
/// another. It is one JSON object per account, shared with the web.
///
/// **Replaced on write, never merged.** api-v2's `users.repository.ts` is explicit that "a key
/// it omits is a key it deleted", so anything writing one key has to send back everything
/// else it found. [update] does that rather than leaving each caller to remember.
class AccountPreferences {
  AccountPreferences({HttpClientAdapter? client}) : _client = client ?? http;

  final HttpClientAdapter _client;

  // The same options every other account-data call uses (bookings, saved trips).
  static const _signedIn = HttpRequestOptions(useMobileApiKey: true, requiresAuth: true);

  Future<Map<String, dynamic>> get() async {
    final res = await _client.get('/api/v2/users/preferences', options: _signedIn);
    final prefs = (res as Map<String, dynamic>?)?['preferences'];
    return prefs is Map<String, dynamic> ? prefs : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> save(Map<String, dynamic> preferences) async {
    final res = await _client.patch(
      '/api/v2/users/preferences',
      body: preferences,
      options: _signedIn,
    );
    final prefs = (res as Map<String, dynamic>?)?['preferences'];
    return prefs is Map<String, dynamic> ? prefs : preferences;
  }

  /// Reads, merges the given keys over what is there, and writes the whole thing back.
  ///
  /// The read is not optional. Sending only the key being changed would delete the display
  /// currency somebody chose in the browser, and nothing would report it.
  Future<Map<String, dynamic>> update(Map<String, dynamic> changes) async {
    final existing = await get();
    return save({...existing, ...changes});
  }
}

final AccountPreferences accountPreferences = AccountPreferences();

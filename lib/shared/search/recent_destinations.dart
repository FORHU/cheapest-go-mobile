import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// The last few places this person searched for, kept on their device.
///
/// Offered on the "where" step before anything is typed, beside the trending list. The two
/// answer different questions — trending is where everyone is going, this is where *they*
/// were going — and a traveller comparing two cities over a week is served by the second.
///
/// On the device and nowhere else. It is a convenience, not a record: there is no account
/// needed to benefit from it, nothing is sent anywhere, and signing out leaves it alone
/// because it was never tied to the account in the first place.
///
/// Storage failures are swallowed on purpose. A phone with no room left, or a platform
/// channel that is not ready yet, must cost a nicety and never the search itself.
class RecentDestinations {
  /// Positional, because a named parameter cannot be private and this one has to assign the
  /// private field directly — tests hand in `SharedPreferences.setMockInitialValues`' store.
  RecentDestinations([this._prefs]);

  static const _key = 'recent_destinations';

  /// How many to keep. Enough to recognise a trip being planned over several sittings, few
  /// enough that the chips do not push the field behind the keyboard — the same constraint
  /// that caps the suggestion list.
  static const max = 5;

  SharedPreferences? _prefs;

  Future<SharedPreferences?> _store() async {
    try {
      return _prefs ??= await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> read() async {
    try {
      final raw = (await _store())?.getString(_key);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded.whereType<String>().where((s) => s.trim().isNotEmpty).toList();
    } catch (_) {
      // Including a value written by an older version in another shape.
      return const [];
    }
  }

  /// Most recent first, and never twice.
  ///
  /// Matched without case so "Cebu" typed today does not sit under "cebu" from yesterday —
  /// the spelling that is kept is the newest one, because that is the one just confirmed.
  Future<List<String>> remember(String city) async {
    final name = city.trim();
    if (name.isEmpty) return read();

    final kept = await read();
    final next = <String>[
      name,
      ...kept.where((c) => c.toLowerCase() != name.toLowerCase()),
    ].take(max).toList();

    try {
      await (await _store())?.setString(_key, jsonEncode(next));
    } catch (_) {
      // Remembered for this session regardless; the list returned is what the caller shows.
    }
    return next;
  }

  Future<void> clear() async {
    try {
      await (await _store())?.remove(_key);
    } catch (_) {
      // Nothing to do.
    }
  }
}

/// Swapped in tests, like `destinationsApi` beside it.
RecentDestinations recentDestinations = RecentDestinations();

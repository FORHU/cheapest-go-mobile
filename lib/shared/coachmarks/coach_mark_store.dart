import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the first-run tour still has to be shown. See #63.
///
/// Held on the device, not against the account — deliberately, and the opposite of where
/// onboarding's markers live (#62, ADR-0005). Onboarding stores answers that belong to the
/// person: asking a second time for a birth date already given is a mistake. A tour teaches a
/// screen on a device, and being shown it again after a reinstall or on a new phone costs
/// three taps and is arguably right, since the screen is new on that device too.
///
/// It also means the tour costs no request, so it can run the instant Home appears instead of
/// waiting on a round trip at the one moment somebody is deciding whether this app is worth it.
class CoachMarkStore extends ChangeNotifier {
  static const String _seenKey = 'cheapestgo_coach_marks_seen';

  bool _seen = true;

  /// True once the tour has been finished or dismissed — and true before [init] has run, so
  /// nothing flashes over Home on the frame before the answer is known.
  bool get seen => _seen;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _seen = prefs.getBool(_seenKey) ?? false;
    } catch (_) {
      // Unreadable storage means the tour does not run. A traveller who cannot be told we
      // already showed it is better served by silence than by a tour on every launch.
      _seen = true;
    }
    notifyListeners();
  }

  /// Finished, or skipped. The two are the same to this: either way it is not shown again.
  Future<void> markSeen() async {
    if (_seen) return;
    _seen = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_seenKey, true);
    } catch (_) {}
  }

  /// Only for tests, and for a debug build that wants to look at it again.
  @visibleForTesting
  Future<void> reset() async {
    _seen = false;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_seenKey);
    } catch (_) {}
  }
}

final CoachMarkStore coachMarkStore = CoachMarkStore();

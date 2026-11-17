import 'package:flutter/foundation.dart';

import 'package:cheapest_go_mobile/shared/account/account_preferences.dart';

/// Which **Tips** an account has been shown, and whether it still wants them. See #62,
/// ADR-0006.
///
/// Against the account, not the device. It began the other way round — a Tip teaches a screen
/// on a phone, and a screen is new again on a new phone — and the gate (#62) made that wrong:
/// the app now requires an account, so a second person signing in on a shared handset was
/// offered no help at all, and one person's Skip silenced everybody who touched that phone.
/// Testing found it first, by creating account after account and being shown nothing.
///
/// The cost is a request before any Tip can appear. Accepted deliberately: being shown help
/// meant for somebody else is worse than being shown it a moment later.
class TipStore extends ChangeNotifier {
  TipStore({AccountPreferences? preferences}) : _prefs = preferences ?? accountPreferences;

  final AccountPreferences _prefs;

  /// Where this sits inside the account's preferences blob.
  static const String key = 'tips';

  Set<String> _shown = const {};
  bool _ended = false;
  bool _loaded = false;

  /// True until an account's answer has arrived, so nothing flashes on a screen before it is
  /// known whether this traveller has already seen it.
  bool get isSilenced => !_loaded || _ended;

  bool get ended => _ended;

  /// Whether this Tip still has something to say to the account signed in now.
  bool shouldShow(String id) => !isSilenced && !_shown.contains(id);

  /// Asks the server what this account has been shown. Call on sign-in.
  Future<void> load() async {
    try {
      _read(await _prefs.get());
      _loaded = true;
    } catch (_) {
      // No answer means no Tips. Guessing would either repeat help somebody has dismissed or
      // withhold it from somebody who has never seen it, and the second is the quieter
      // failure — nobody is interrupted by help that does not arrive.
      _loaded = false;
    }
    notifyListeners();
  }

  /// Forgets everything on sign-out, so the next account starts its own.
  void reset() {
    _shown = const {};
    _ended = false;
    _loaded = false;
    notifyListeners();
  }

  /// Shown and finished with — read, or acted on.
  Future<void> markShown(String id) async {
    if (_shown.contains(id)) return;
    _shown = {..._shown, id};
    notifyListeners();
    await _write();
  }

  /// Stops the Tips outright: no further one, on any screen, for this account.
  Future<void> endTutorial() async {
    if (_ended) return;
    _ended = true;
    notifyListeners();
    await _write();
  }

  void _read(Map<String, dynamic> preferences) {
    final raw = preferences[key];
    if (raw is! Map) {
      _shown = const {};
      _ended = false;
      return;
    }
    final shown = raw['shown'];
    _shown = shown is List ? shown.whereType<String>().toSet() : const {};
    _ended = raw['ended'] == true;
  }

  /// Merged into the blob rather than replacing it — the currency and language live there too.
  Future<void> _write() async {
    try {
      await _prefs.update({
        key: {'shown': _shown.toList(), 'ended': _ended},
      });
    } catch (_) {
      // The traveller saw the Tip; failing to record that is not worth interrupting them for.
      // The worst case is being shown it once more.
    }
  }

  /// Only for tests, and for a debug build that wants to see them again.
  @visibleForTesting
  void debugLoad({Set<String> shown = const {}, bool ended = false}) {
    _shown = shown;
    _ended = ended;
    _loaded = true;
    notifyListeners();
  }
}

final TipStore tipStore = TipStore();

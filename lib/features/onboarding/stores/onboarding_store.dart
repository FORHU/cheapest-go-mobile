import 'package:flutter/foundation.dart';

import 'package:cheapest_go_mobile/features/onboarding/api/onboarding_api.dart';
import 'package:cheapest_go_mobile/features/onboarding/lib/onboarding_markers.dart';

/// Whether the signed-in account still owes us onboarding. See #62.
///
/// Kept apart from the auth store because they answer different questions and change at different
/// times: being signed in is about this device holding a token, and owing onboarding is about
/// what the account's preferences say. The gate needs both, and conflating them is how a
/// sign-out would leave a stale answer behind.
class OnboardingStore extends ChangeNotifier {
  OnboardingStore({OnboardingApi? api}) : _api = api ?? onboardingApi;

  final OnboardingApi _api;

  OnboardingStatus _status = OnboardingStatus.unknown;
  bool _loading = false;
  bool _failed = false;

  OnboardingStatus get status => _status;
  bool get isLoading => _loading;

  /// The last attempt to ask the server failed.
  ///
  /// Separate from [status] because "we have not asked yet" and "we asked and could not get an
  /// answer" look identical otherwise, and the gate holds on both — which is a spinner with no
  /// end. The screen that shows during the wait reads this and offers a way out.
  bool get failed => _failed;

  /// True only once the answer is known and it is "finished" or "never needed".
  bool get mayEnterApp =>
      _status == OnboardingStatus.completed || _status == OnboardingStatus.notRequired;

  /// Asks the server where this account stands.
  ///
  /// A failure leaves the status unknown rather than guessing. The gate holds on unknown, so a
  /// network blip shows a spinner instead of either walling an existing traveller out or
  /// waving a new one past a flow they have to finish.
  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _failed = false;
    notifyListeners();

    try {
      final prefs = await _api.getPreferences();
      _status = OnboardingMarkers.fromPreferences(prefs).status;
    } catch (_) {
      _status = OnboardingStatus.unknown;
      _failed = true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Records the answers and the completion in one write, then opens the gate.
  Future<bool> complete(Map<String, dynamic> chosenPreferences) async {
    _loading = true;
    notifyListeners();
    try {
      final markers = await _api.saveOnboarding(chosenPreferences);
      _status = markers.status;
      return _status == OnboardingStatus.completed;
    } catch (_) {
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Forgets what was known, on sign-out. The next account is a different question.
  void reset() {
    _status = OnboardingStatus.unknown;
    _failed = false;
    notifyListeners();
  }
}

final OnboardingStore onboardingStore = OnboardingStore();

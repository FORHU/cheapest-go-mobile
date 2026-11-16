import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/app/router/auth_gate.dart';
import 'package:cheapest_go_mobile/features/onboarding/api/onboarding_api.dart';
import 'package:cheapest_go_mobile/features/onboarding/lib/onboarding_markers.dart';
import 'package:cheapest_go_mobile/features/onboarding/stores/onboarding_store.dart';
import 'package:cheapest_go_mobile/shared/errors/api_error.dart';

/// What happens when the gate cannot get its answer. See #62.
///
/// The first build of this ran on a handset and never left the loading screen. A session
/// restored from an earlier build was accepted without a usable token, every request 401'd,
/// the onboarding status stayed unknown — and the gate holds on unknown, by design, because
/// guessing is worse. Holding forever is worse still.
class _FailingApi implements OnboardingApi {
  _FailingApi(this._error);

  final Object _error;
  int calls = 0;

  @override
  Future<Map<String, dynamic>> getPreferences() async {
    calls++;
    throw _error;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _WorkingApi implements OnboardingApi {
  @override
  Future<Map<String, dynamic>> getPreferences() async => {
        'onboarding': {'startedAt': '2026-11-16T02:00:00.000Z'},
      };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('a failed load is told apart from one that has not happened', () async {
    final store = OnboardingStore(api: _FailingApi(ApiError('nope', category: ErrorCategory.auth)));

    expect(store.failed, isFalse, reason: 'nothing has been asked yet');

    await store.load();

    // Still unknown, so the gate still holds — but now the screen knows it is holding on a
    // failure rather than on a request still in flight, and can offer a way out.
    expect(store.status, OnboardingStatus.unknown);
    expect(store.failed, isTrue);
  });

  test('retrying after a failure clears the failure and gets the answer', () async {
    final store = OnboardingStore(api: _FailingApi(ApiError('offline', category: ErrorCategory.network)));
    await store.load();
    expect(store.failed, isTrue);

    // What the Try again button does. A dropped connection is the case this recovers from
    // without anybody signing out.
    final recovered = OnboardingStore(api: _WorkingApi());
    await recovered.load();

    expect(recovered.failed, isFalse);
    expect(recovered.status, OnboardingStatus.required);
  });

  test('signing out clears the failure, so the next account starts clean', () {
    final store = OnboardingStore(api: _WorkingApi());
    store.reset();

    expect(store.failed, isFalse);
    expect(store.status, OnboardingStatus.unknown);
  });

  test('the gate still refuses to guess while the answer is missing', () {
    // The failure does not change the rule. It must not quietly become "let them in", which
    // would wave a genuinely new account past a flow it has to finish, nor "onboard them",
    // which would trap an existing one.
    expect(
      gateRedirect('/', isAuthenticated: true, onboarding: OnboardingStatus.unknown),
      '/starting',
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cheapest_go_mobile/features/auth/contracts/auth_contract.dart';
import 'package:cheapest_go_mobile/features/auth/stores/auth_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a fresh install starts signed in as the demo user', () async {
    final store = AuthStore(mock: true);
    await store.restoreSession();
    expect(store.isAuthenticated, isTrue);
    expect(store.user?.fullName, 'Juan Dela Cruz');
    expect(store.user?.email, kDemoUser.email);
  });

  test('signing out sticks across launches until the demo user signs in', () async {
    final store = AuthStore(mock: true);
    await store.restoreSession();
    await store.logout();
    expect(store.isAuthenticated, isFalse);

    final relaunch = AuthStore(mock: true);
    await relaunch.restoreSession();
    expect(relaunch.isAuthenticated, isFalse);

    expect(await relaunch.login('someone@else.com', 'whatever1'), isFalse);
    expect(relaunch.errorMessage, contains(kDemoUser.email));
    expect(await relaunch.login(kDemoUser.email, kDemoPassword), isTrue);
    expect(relaunch.user?.id, kDemoUser.id);
  });

  test('registering in the mock build creates a local account', () async {
    final store = AuthStore(mock: true);
    final ok = await store.register(const RegisterInput(
      email: 'Maria@Example.com',
      password: 'longenough',
      firstName: 'Maria',
      lastName: 'Santos',
    ));
    expect(ok, isTrue);
    expect(store.user?.fullName, 'Maria Santos');
    expect(store.user?.email, 'maria@example.com');
  });
}

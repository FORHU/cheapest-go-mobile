import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cheapest_go_mobile/features/auth/api/auth_api.dart';
import 'package:cheapest_go_mobile/features/auth/api/google_identity.dart';
import 'package:cheapest_go_mobile/features/auth/contracts/auth_contract.dart';
import 'package:cheapest_go_mobile/shared/auth/permissions.dart';
import 'package:cheapest_go_mobile/shared/auth/rbac.dart';
import 'package:cheapest_go_mobile/shared/auth/roles.dart';
import 'package:cheapest_go_mobile/shared/errors/error_router.dart';

/// While the app runs on mock data, auth stays on the device: a demo user is
/// signed in by default and nothing calls the API. Build with
/// `--dart-define=MOCK_AUTH=false` to use the real `/api/v2/auth` endpoints.
const bool kMockAuth = bool.fromEnvironment('MOCK_AUTH', defaultValue: true);

/// The default account in the mock build.
const AuthUser kDemoUser = AuthUser(
  id: 'demo-juan-dela-cruz',
  email: 'juan.delacruz@cheapestgo.dev',
  firstName: 'Juan',
  lastName: 'Dela Cruz',
  role: Role.user,
);

/// Password for [kDemoUser] in the mock build.
const String kDemoPassword = 'cheapestgo123';

class AuthStore extends ChangeNotifier {
  AuthStore({this.mock = kMockAuth});

  /// Keep auth on the device instead of calling the API.
  final bool mock;

  static const String _cachedUserKey = 'cheapestgo_cached_user';

  /// Set when the traveler signs out, so the demo user isn't signed back in
  /// on the next launch.
  static const String _signedOutKey = 'cheapestgo_signed_out';

  AuthUser? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  Role get currentRole => _user?.role ?? Role.guest;
  String? get errorMessage => _errorMessage;

  /// Clears a stale error so it doesn't carry over between auth screens.
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> restoreSession() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cachedUserKey);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _user = AuthUser.fromJson(map);
        notifyListeners();
      }
      if (mock) {
        if (_user == null && !(prefs.getBool(_signedOutKey) ?? false)) {
          await _signIn(kDemoUser);
        }
        return;
      }
      final fresh = await authApi.fetchCurrentUser();
      if (fresh != null) {
        _user = fresh;
        await prefs.setString(_cachedUserKey, jsonEncode(fresh.toJson()));
      }
    } catch (_) {
      // Keep cached user or guest state if offline/unauthenticated
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Signs in the demo account (mock build).
  Future<void> signInDemo() async {
    _errorMessage = null;
    await _signIn(kDemoUser);
    notifyListeners();
  }

  Future<void> _signIn(AuthUser u) async {
    _user = u;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedUserKey, jsonEncode(u.toJson()));
      await prefs.remove(_signedOutKey);
    } catch (_) {}
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    if (mock) {
      final ok = email.trim().toLowerCase() == kDemoUser.email && password == kDemoPassword;
      if (ok) {
        await _signIn(kDemoUser);
      } else {
        _errorMessage = 'In this test build, sign in as ${kDemoUser.email} with password $kDemoPassword.';
      }
      _isLoading = false;
      notifyListeners();
      return ok;
    }
    try {
      final u = await authApi.login(email: email, password: password);
      _user = u;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cachedUserKey, jsonEncode(u.toJson()));
      } catch (_) {}
      return true;
    } catch (err) {
      final routed = routeError(err);
      _errorMessage = routed.toast ?? err.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(RegisterInput input) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    if (mock) {
      try {
        input.validate();
        final email = input.email.trim().toLowerCase();
        await _signIn(AuthUser(
          id: 'local-$email',
          email: email,
          firstName: input.firstName.trim(),
          lastName: input.lastName.trim(),
          role: Role.user,
        ));
        return true;
      } catch (err) {
        _errorMessage = routeError(err).toast ?? err.toString();
        return false;
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
    try {
      final u = await authApi.register(input);
      _user = u;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cachedUserKey, jsonEncode(u.toJson()));
      } catch (_) {}
      return true;
    } catch (err) {
      final routed = routeError(err);
      _errorMessage = routed.toast ?? err.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    if (mock) {
      // Nothing to send in the test build; behave as if the email went out.
      _isLoading = false;
      notifyListeners();
      return true;
    }
    try {
      await authApi.resetPassword(email);
      return true;
    } catch (err) {
      final routed = routeError(err);
      _errorMessage = routed.toast ?? err.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Signs in with Google. See #45.
  ///
  /// Returns false when the traveller backed out of the account picker — their decision, so
  /// no error is set and nothing is said. A genuine failure sets [errorMessage] as the
  /// password path does.
  ///
  /// Available in a mock build too: unlike a password, there is no fake Google to stand in
  /// for, so this always goes to api-v2. A build without a client id has no button at all.
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final idToken = await googleIdentity.idToken();
      if (idToken == null || idToken.isEmpty) return false;

      final user = await authApi.signInWithGoogle(idToken);
      _user = user;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cachedUserKey, jsonEncode(user.toJson()));
        await prefs.remove(_signedOutKey);
      } catch (_) {}
      return true;
    } on GoogleNotConfigured {
      _errorMessage = 'Google sign-in is not configured in this build.';
      return false;
    } catch (err) {
      _errorMessage = routeError(err).toast ?? err.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      if (!mock) await authApi.logout();
      // Also let go of the Google account, or the next sign-in silently picks the same one
      // with no chance to choose another.
      await googleIdentity.forget();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedUserKey);
      if (mock) await prefs.setBool(_signedOutKey, true);
    } catch (_) {}
    _user = null;
    _isLoading = false;
    notifyListeners();
  }

  bool can(
    Permission permission, {
    PermissionContext context = const PermissionContext(),
  }) {
    return hasPermission(
      currentRole,
      permission,
      context: context,
      userId: _user?.id,
    );
  }
}

final AuthStore authStore = AuthStore();

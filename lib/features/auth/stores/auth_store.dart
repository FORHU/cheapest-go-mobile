import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cheapest_go_mobile/features/auth/api/auth_api.dart';
import 'package:cheapest_go_mobile/features/auth/contracts/auth_contract.dart';
import 'package:cheapest_go_mobile/shared/auth/permissions.dart';
import 'package:cheapest_go_mobile/shared/auth/rbac.dart';
import 'package:cheapest_go_mobile/shared/auth/roles.dart';
import 'package:cheapest_go_mobile/shared/errors/error_router.dart';

class AuthStore extends ChangeNotifier {
  static const String _cachedUserKey = 'cheapestgo_cached_user';

  AuthUser? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  Role get currentRole => _user?.role ?? Role.guest;
  String? get errorMessage => _errorMessage;

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

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
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

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await authApi.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedUserKey);
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

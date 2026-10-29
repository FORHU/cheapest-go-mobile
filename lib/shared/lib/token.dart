import 'package:shared_preferences/shared_preferences.dart';

/// FAOS — Auth token & session cookie storage (Single Source of Truth)
///
/// Combines in-memory fast reads with `SharedPreferences` persistence so
/// both JWT tokens and Lucia session cookies work seamlessly on mobile.

class TokenStorage {
  static const String _accessTokenKey = 'cheapestgo_access_token';
  static const String _refreshTokenKey = 'cheapestgo_refresh_token';
  static const String _sessionCookieKey = 'cheapestgo_session_cookie';

  String? _inMemoryAccessToken;
  String? _inMemoryRefreshToken;
  String? _inMemorySessionCookie;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _inMemoryAccessToken = prefs.getString(_accessTokenKey);
      _inMemoryRefreshToken = prefs.getString(_refreshTokenKey);
      _inMemorySessionCookie = prefs.getString(_sessionCookieKey);
    } catch (_) {
      // Fallback to in-memory only (e.g., in unit test environments)
    }
  }

  String? getAccessToken() => _inMemoryAccessToken;

  Future<void> setAccessToken(String token) async {
    _inMemoryAccessToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, token);
    } catch (_) {}
  }

  String? getRefreshToken() => _inMemoryRefreshToken;

  Future<void> setRefreshToken(String token) async {
    _inMemoryRefreshToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_refreshTokenKey, token);
    } catch (_) {}
  }

  String? getSessionCookie() => _inMemorySessionCookie;

  Future<void> setSessionCookie(String cookie) async {
    _inMemorySessionCookie = cookie;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionCookieKey, cookie);
    } catch (_) {}
  }

  Future<void> setTokens(String accessToken, [String? refreshToken]) async {
    await setAccessToken(accessToken);
    if (refreshToken != null) {
      await setRefreshToken(refreshToken);
    }
  }

  Future<void> clearTokens() async {
    _inMemoryAccessToken = null;
    _inMemoryRefreshToken = null;
    _inMemorySessionCookie = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_sessionCookieKey);
    } catch (_) {}
  }

  bool hasToken() =>
      (_inMemoryAccessToken != null && _inMemoryAccessToken!.isNotEmpty) ||
      (_inMemorySessionCookie != null && _inMemorySessionCookie!.isNotEmpty);
}

final TokenStorage tokenStorage = TokenStorage();

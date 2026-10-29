import 'package:cheapest_go_mobile/features/auth/contracts/auth_contract.dart';
import 'package:cheapest_go_mobile/shared/lib/http.dart';
import 'package:cheapest_go_mobile/shared/lib/token.dart';

class AuthApi {
  Future<AuthUser?> fetchCurrentUser() async {
    final data = await http.get('/api/v2/auth/me');
    if (data is Map<String, dynamic> && data['user'] is Map<String, dynamic>) {
      return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    }
    return null;
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final data = await http.post(
      '/api/v2/auth/login',
      body: {
        'email': email.trim(),
        'password': password,
      },
      options: const HttpRequestOptions(requiresAuth: false),
    );
    if (data is Map<String, dynamic>) {
      final accessToken = data['accessToken']?.toString();
      final refreshToken = data['refreshToken']?.toString();
      if (accessToken != null && accessToken.isNotEmpty) {
        await tokenStorage.setTokens(accessToken, refreshToken);
      }
      final rawUser = (data['user'] as Map<String, dynamic>?) ?? data;
      return AuthUser.fromJson(rawUser, fallbackEmail: email);
    }
    throw StateError('Unexpected login response');
  }

  Future<AuthUser> register(RegisterInput input) async {
    input.validate();
    final data = await http.post(
      '/api/v2/auth/register',
      body: input.toJson(),
      options: const HttpRequestOptions(requiresAuth: false),
    );
    if (data is Map<String, dynamic>) {
      final accessToken = data['accessToken']?.toString();
      final refreshToken = data['refreshToken']?.toString();
      if (accessToken != null && accessToken.isNotEmpty) {
        await tokenStorage.setTokens(accessToken, refreshToken);
      }
      final rawUser = (data['user'] as Map<String, dynamic>?) ?? data;
      return AuthUser.fromJson(
        rawUser,
        fallbackEmail: input.email,
        fallbackFirstName: input.firstName,
        fallbackLastName: input.lastName,
      );
    }
    throw StateError('Unexpected signup response');
  }

  Future<void> resetPassword(String email) async {
    await http.post(
      '/api/v2/auth/request-reset',
      body: {'email': email.trim()},
      options: const HttpRequestOptions(requiresAuth: false),
    );
  }

  Future<void> logout() async {
    try {
      await http.post('/api/v2/auth/logout');
    } catch (_) {}
    await tokenStorage.clearTokens();
  }
}

final AuthApi authApi = AuthApi();

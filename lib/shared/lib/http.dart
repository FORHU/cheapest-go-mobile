import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http_pkg;
import 'package:cheapest_go_mobile/shared/errors/api_error.dart';
import 'package:cheapest_go_mobile/shared/lib/env.dart';
import 'package:cheapest_go_mobile/shared/lib/token.dart';

ErrorCategory _classify(int status) {
  if (status == 401) return ErrorCategory.auth;
  if (status == 403) return ErrorCategory.forbidden;
  if (status == 404) return ErrorCategory.notFound;
  if (status == 422) return ErrorCategory.validation;
  if (status >= 500) return ErrorCategory.server;
  return ErrorCategory.unknown;
}

class HttpRequestOptions {
  const HttpRequestOptions({
    this.requiresAuth = true,
    this.useMobileApiKey = false,
    this.headers,
    this.timeout = const Duration(seconds: 30),
  });

  final bool requiresAuth;
  final bool useMobileApiKey;
  final Map<String, String>? headers;
  final Duration timeout;
}

class HttpClientAdapter {
  HttpClientAdapter({http_pkg.Client? client})
      : _client = client ?? http_pkg.Client();

  final http_pkg.Client _client;

  Future<dynamic> request(
    String method,
    String url, {
    Object? body,
    HttpRequestOptions options = const HttpRequestOptions(),
  }) async {
    try {
      final isRefreshRequest =
          url.contains('/auth/refresh') || url.contains('/auth/refresh-token');
      final token = isRefreshRequest
          ? tokenStorage.getRefreshToken()
          : tokenStorage.getAccessToken();
      final cookie = tokenStorage.getSessionCookie();

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'X-Requested-By': 'cheapestgo-client',
        if (token != null && token.isNotEmpty && options.requiresAuth)
          'Authorization': 'Bearer $token',
        if (cookie != null && cookie.isNotEmpty && options.requiresAuth)
          'Cookie': cookie,
        if (options.useMobileApiKey && env.mobileApiKey.isNotEmpty)
          'X-Mobile-Api-Key': env.mobileApiKey,
        ...?options.headers,
      };

      final formattedUrl = url.startsWith('http')
          ? url
          : '${env.webApiUrl}${url.startsWith('/') ? url : '/$url'}';
      final uri = Uri.parse(formattedUrl);
      final encodedBody = body != null ? jsonEncode(body) : null;

      late final http_pkg.Response res;
      switch (method.toUpperCase()) {
        case 'GET':
          res = await _client.get(uri, headers: headers).timeout(options.timeout);
          break;
        case 'POST':
          res = await _client
              .post(uri, headers: headers, body: encodedBody)
              .timeout(options.timeout);
          break;
        case 'PUT':
          res = await _client
              .put(uri, headers: headers, body: encodedBody)
              .timeout(options.timeout);
          break;
        case 'PATCH':
          res = await _client
              .patch(uri, headers: headers, body: encodedBody)
              .timeout(options.timeout);
          break;
        case 'DELETE':
          res = await _client
              .delete(uri, headers: headers, body: encodedBody)
              .timeout(options.timeout);
          break;
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }

      // Persist Set-Cookie header & JWT tokens for cheapestgo-api-v2 sessions
      // (`__Host-access_token` / `access_token` + `refresh_token`)
      final setCookie = res.headers['set-cookie'];
      if (setCookie != null && setCookie.isNotEmpty) {
        final cookiePair = setCookie.split(';').first.trim();
        if (cookiePair.isNotEmpty) {
          await tokenStorage.setSessionCookie(cookiePair);
        }
        final accessMatch = RegExp(
          r'(?:__Host-access_token|access_token)=([^;,\s]+)',
        ).firstMatch(setCookie);
        final refreshMatch = RegExp(
          r'refresh_token=([^;,\s]+)',
        ).firstMatch(setCookie);
        if (accessMatch != null) {
          final parsedAccess = accessMatch.group(1) ?? '';
          final parsedRefresh =
              refreshMatch?.group(1) ?? tokenStorage.getRefreshToken();
          if (parsedAccess.isNotEmpty) {
            await tokenStorage.setTokens(parsedAccess, parsedRefresh);
          }
        }
      }

      if (res.statusCode == 204 || res.contentLength == 0) {
        return null;
      }

      final text = res.body.trim();
      Map<String, dynamic>? payloadMap;
      dynamic decoded;

      if (text.isNotEmpty) {
        try {
          decoded = jsonDecode(text);
          if (decoded is Map<String, dynamic>) {
            payloadMap = decoded;
          }
        } catch (_) {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            throw ApiError(
              'The server returned an unexpected response. Please try again.',
              category: ErrorCategory.server,
              status: res.statusCode,
            );
          }
        }
      }

      final isSuccessFlagFalse = payloadMap != null && payloadMap['success'] == false;
      if (res.statusCode < 200 || res.statusCode >= 300 || isSuccessFlagFalse) {
        final category = _classify(res.statusCode);
        // api-v2's AppError answers `{ error: 'OFFER_EXPIRED', message: '…' }`: the code in
        // `error` and the sentence in `message`. Read as a message, `error` put the code on
        // screen and left `code` null, so no caller could tell a fare that had gone from any
        // other failure. Older routes send `{ error: '<sentence>' }`, which still reads as text.
        final rawError = payloadMap?['error']?.toString();
        final errorIsCode = rawError != null && RegExp(r'^[A-Z][A-Z0-9_]+$').hasMatch(rawError);
        final message = ((errorIsCode ? null : rawError) ??
                payloadMap?['message'] ??
                rawError ??
                'Request failed (HTTP ${res.statusCode})')
            .toString();
        final code = payloadMap?['code']?.toString() ?? (errorIsCode ? rawError : null);

        Map<String, List<String>>? details;
        final rawDetails = payloadMap?['details'];
        if (rawDetails is Map) {
          details = rawDetails.map(
            (key, value) => MapEntry(
              key.toString(),
              value is List
                  ? value.map((e) => e.toString()).toList()
                  : [value.toString()],
            ),
          );
        }

        throw ApiError(
          message,
          category: category,
          status: res.statusCode,
          code: code,
          body: payloadMap,
          details: details,
          priceChanged: payloadMap?['priceChanged'] as bool?,
          newPrice: (payloadMap?['newPrice'] as num?)?.toDouble(),
        );
      }

      if (text.isEmpty) {
        throw ApiError(
          'The server returned an empty response. Please try again.',
          category: ErrorCategory.server,
          status: res.statusCode,
        );
      }

      return decoded;
    } on TimeoutException {
      throw ApiError(
        'Request timed out. Please check your connection and try again.',
        category: ErrorCategory.network,
      );
    } on ApiError {
      rethrow;
    } catch (_) {
      throw ApiError('Network error', category: ErrorCategory.network);
    }
  }

  Future<dynamic> get(
    String url, {
    HttpRequestOptions options = const HttpRequestOptions(),
  }) =>
      request('GET', url, options: options);

  /// A GET whose answer is a file rather than JSON — the invoice PDF. Signed in the same way
  /// as [request], so the API recognises whose booking it is.
  Future<List<int>> getBytes(
    String url, {
    HttpRequestOptions options = const HttpRequestOptions(),
  }) async {
    final token = tokenStorage.getAccessToken();
    final cookie = tokenStorage.getSessionCookie();
    final headers = <String, String>{
      'X-Requested-By': 'cheapestgo-client',
      if (token != null && token.isNotEmpty && options.requiresAuth)
        'Authorization': 'Bearer $token',
      if (cookie != null && cookie.isNotEmpty && options.requiresAuth)
        'Cookie': cookie,
      if (options.useMobileApiKey && env.mobileApiKey.isNotEmpty)
        'X-Mobile-Api-Key': env.mobileApiKey,
      ...?options.headers,
    };
    final uri = Uri.parse(url.startsWith('http')
        ? url
        : '${env.webApiUrl}${url.startsWith('/') ? url : '/$url'}');
    try {
      final res = await _client.get(uri, headers: headers).timeout(options.timeout);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw ApiError(
          'Request failed (HTTP ${res.statusCode})',
          category: _classify(res.statusCode),
          status: res.statusCode,
        );
      }
      return res.bodyBytes;
    } on TimeoutException {
      throw ApiError(
        'Request timed out. Please check your connection and try again.',
        category: ErrorCategory.network,
      );
    } on ApiError {
      rethrow;
    } catch (_) {
      throw ApiError('Network error', category: ErrorCategory.network);
    }
  }

  Future<dynamic> post(
    String url, {
    Object? body,
    HttpRequestOptions options = const HttpRequestOptions(),
  }) =>
      request('POST', url, body: body, options: options);

  Future<dynamic> put(
    String url, {
    Object? body,
    HttpRequestOptions options = const HttpRequestOptions(),
  }) =>
      request('PUT', url, body: body, options: options);

  Future<dynamic> patch(
    String url, {
    Object? body,
    HttpRequestOptions options = const HttpRequestOptions(),
  }) =>
      request('PATCH', url, body: body, options: options);

  Future<dynamic> delete(
    String url, {
    Object? body,
    HttpRequestOptions options = const HttpRequestOptions(),
  }) =>
      request('DELETE', url, body: body, options: options);
}

final HttpClientAdapter http = HttpClientAdapter();

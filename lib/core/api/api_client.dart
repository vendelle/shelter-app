import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Centralised HTTP client for all API calls.
///
/// On web, requests go to the same origin (`/api/...`).
/// On mobile local dev, point to your local machine or Vercel URL.
///
/// When signed in, [idToken] supplies the Firebase ID token sent as
/// `Authorization: Bearer …`; the API uses it for edit permissions.
class ApiClient {
  ApiClient({
    String? baseUrl,
    Future<String?> Function()? idToken,
    http.Client? client,
  })  : _baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL'),
        _idToken = idToken,
        _client = client ?? http.Client();

  final String _baseUrl;
  final Future<String?> Function()? _idToken;
  final http.Client _client;

  Future<Map<String, String>> _headers() async {
    final token = await _idToken?.call();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path, [Map<String, String>? queryParams]) {
    final url = '$_baseUrl$path';
    final uri = Uri.parse(url);
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  Future<dynamic> get(String path,
      {Map<String, String>? queryParams}) async {
    final response = await _client.get(
      _uri(path, queryParams),
      headers: await _headers(),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<dynamic> post(String path,
      {Map<String, String>? queryParams, Object? body}) async {
    final response = await _client.post(
      _uri(path, queryParams),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<dynamic> patch(String path, {Object? body}) async {
    final response = await _client.patch(
      _uri(path),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<dynamic> put(String path,
      {Map<String, String>? queryParams, Object? body}) async {
    final response = await _client.put(
      _uri(path, queryParams),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<void> delete(String path,
      {Map<String, String>? queryParams}) async {
    final response = await _client.delete(
      _uri(path, queryParams),
      headers: await _headers(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// The correct base URL for the current platform.
  ///
  /// - **Deployed web** (Vercel): empty string — same-origin relative URLs.
  /// - **Local dev** (`flutter run`): uses the Vercel deployment so API
  ///   calls work without running a local Node server.
  /// - **Override**: `--dart-define=API_BASE_URL=https://custom.example.com`
  static String get defaultBaseUrl {
    const env = String.fromEnvironment('API_BASE_URL');
    if (env.isNotEmpty) return env;

    // In debug mode, Flutter's dev server doesn't serve /api/ routes,
    // so we proxy to the deployed Vercel instance.
    if (kDebugMode) return 'https://shelter-app-plum.vercel.app';

    // In release (deployed on Vercel), use same-origin.
    return '';
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;

  ApiException(this.statusCode, this.body);

  /// The API's `{"error": "..."}` message, falling back to the raw body.
  String get message {
    try {
      final error = (jsonDecode(body) as Map<String, dynamic>)['error'];
      if (error is String) return error;
    } catch (_) {}
    return body;
  }

  @override
  String toString() => 'ApiException($statusCode): $body';
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Centralised HTTP client for all API calls.
///
/// On web, requests go to the same origin (`/api/...`).
/// On mobile local dev, point to your local machine or Vercel URL.
class ApiClient {
  ApiClient({String? baseUrl})
      : _baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL');

  final String _baseUrl;
  final http.Client _client = http.Client();

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
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final response = await _client.post(
      _uri(path),
      headers: {'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<void> delete(String path,
      {Map<String, String>? queryParams}) async {
    final response = await _client.delete(
      _uri(path, queryParams),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// The correct base URL for the current platform.
  ///
  /// - **Web**: empty string (same-origin relative URLs work).
  /// - **Mobile/desktop local dev**: override via `--dart-define=API_BASE_URL=https://shelter-app.vercel.app`.
  static String get defaultBaseUrl {
    if (kIsWeb) return ''; // same origin
    // For local mobile dev, override via dart-define
    const env = String.fromEnvironment('API_BASE_URL');
    return env.isNotEmpty ? env : '';
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;

  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}

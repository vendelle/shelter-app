import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shelter_app/core/api/api_client.dart';

void main() {
  group('ApiClient', () {
    test('constructs with explicit baseUrl', () {
      final client = ApiClient(baseUrl: 'https://example.com');
      // Verify it doesn't throw
      expect(client, isNotNull);
    });

    test('constructs with empty baseUrl for same-origin', () {
      final client = ApiClient(baseUrl: '');
      expect(client, isNotNull);
    });
  });

  group('ApiException', () {
    test('stores status code and body', () {
      final exception = ApiException(404, 'Not found');

      expect(exception.statusCode, 404);
      expect(exception.body, 'Not found');
    });

    test('toString includes status code', () {
      final exception = ApiException(500, 'Server error');

      expect(exception.toString(), contains('500'));
      expect(exception.toString(), contains('Server error'));
    });
  });

  group('ApiClient auth', () {
    late List<http.Request> requests;
    final mock = MockClient((request) async {
      requests.add(request);
      return http.Response(jsonEncode({'ok': true}), 200);
    });

    setUp(() => requests = []);

    test('sends the ID token as a Bearer header', () async {
      final client = ApiClient(
        baseUrl: 'https://example.com',
        idToken: () async => 'abc',
        client: mock,
      );
      await client.get('/api/dogs');
      await client.post('/api/dayplan', body: {});
      expect(
        requests.map((r) => r.headers['Authorization']),
        everyElement('Bearer abc'),
      );
    });

    test('omits the header when signed out', () async {
      final client = ApiClient(
        baseUrl: 'https://example.com',
        idToken: () async => null,
        client: mock,
      );
      await client.get('/api/dogs');
      expect(requests.single.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('ApiException.message', () {
    test('extracts the API error message', () {
      expect(
        ApiException(403, '{"error":"Insufficient permissions"}').message,
        'Insufficient permissions',
      );
    });

    test('falls back to the raw body', () {
      expect(ApiException(500, 'Gateway timeout').message, 'Gateway timeout');
    });
  });
}

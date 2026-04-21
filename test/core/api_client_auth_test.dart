import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/core/api/api_client.dart';

void main() {
  group('ApiClient auth token', () {
    test('constructs with authTokenProvider', () {
      final client = ApiClient(
        baseUrl: 'https://example.com',
        authTokenProvider: () async => 'test-token',
      );

      expect(client, isNotNull);
      expect(client.authTokenProvider, isNotNull);
    });

    test('constructs without authTokenProvider', () {
      final client = ApiClient(baseUrl: 'https://example.com');

      expect(client, isNotNull);
      expect(client.authTokenProvider, isNull);
    });

    test('authTokenProvider can be set after construction', () {
      final client = ApiClient(baseUrl: 'https://example.com');
      expect(client.authTokenProvider, isNull);

      client.authTokenProvider = () async => 'lazy-token';
      expect(client.authTokenProvider, isNotNull);
    });
  });
}

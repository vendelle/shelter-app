import 'package:flutter_test/flutter_test.dart';
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
}

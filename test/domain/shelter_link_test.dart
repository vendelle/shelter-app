import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/shared/domain/shelter_link.dart';

void main() {
  group('buildShelterUrl', () {
    test('pads a short number to 4 digits', () {
      expect(
        buildShelterUrl('573/26'),
        'https://napaluchu.waw.pl/animal/0573-26p/',
      );
    });

    test('leaves an already 4-digit number as-is', () {
      expect(
        buildShelterUrl('2222/26'),
        'https://napaluchu.waw.pl/animal/2222-26p/',
      );
    });

    test('trims surrounding whitespace', () {
      expect(
        buildShelterUrl(' 573/26 '),
        'https://napaluchu.waw.pl/animal/0573-26p/',
      );
    });

    test('returns null for null or empty', () {
      expect(buildShelterUrl(null), isNull);
      expect(buildShelterUrl(''), isNull);
      expect(buildShelterUrl('   '), isNull);
    });

    test('returns null when shelterId does not match the number/year shape', () {
      expect(buildShelterUrl('S010'), isNull);
      expect(buildShelterUrl('573-26'), isNull);
      expect(buildShelterUrl('573/26/1'), isNull);
    });
  });
}

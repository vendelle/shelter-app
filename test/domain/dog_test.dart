import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/shared/domain/dog.dart';

void main() {
  group('Dog', () {
    test('creates with required fields', () {
      const dog = Dog(
        id: 1,
        name: 'Burek',
        shelterId: 'S001',
        kennel: 'A1',
      );

      expect(dog.id, 1);
      expect(dog.name, 'Burek');
      expect(dog.shelterId, 'S001');
      expect(dog.kennel, 'A1');
      expect(dog.region, isNull);
      expect(dog.archived, false);
    });

    test('fromJson parses all fields', () {
      final dog = Dog.fromJson({
        'id': 5,
        'name': 'Luna',
        'shelterid': 'S042',
        'kennel': 'B3',
        'region': 'North',
        'archived': true,
      });

      expect(dog.id, 5);
      expect(dog.name, 'Luna');
      expect(dog.shelterId, 'S042');
      expect(dog.kennel, 'B3');
      expect(dog.region, 'North');
      expect(dog.archived, true);
    });

    test('fromJson defaults archived to false when null', () {
      final dog = Dog.fromJson({
        'id': 1,
        'name': 'Rex',
        'shelterid': 'S001',
        'kennel': 'A1',
        'archived': null,
      });

      expect(dog.archived, false);
    });

    test('fromJson handles missing optional fields', () {
      final dog = Dog.fromJson({
        'id': 1,
        'name': 'Rex',
        'shelterid': 'S001',
        'kennel': 'A1',
      });

      expect(dog.region, isNull);
      expect(dog.archived, false);
    });
  });
}

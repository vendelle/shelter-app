import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/dog_detail/domain/dog_relationship.dart';

void main() {
  group('DogRelationshipLevel', () {
    test('parseRelationshipLevel parses all levels', () {
      expect(parseRelationshipLevel('yard'), DogRelationshipLevel.yard);
      expect(parseRelationshipLevel('contact_good'),
          DogRelationshipLevel.contactGood);
      expect(parseRelationshipLevel('contact_caution'),
          DogRelationshipLevel.contactCaution);
      expect(parseRelationshipLevel('parallel_good'),
          DogRelationshipLevel.parallelGood);
      expect(parseRelationshipLevel('parallel_caution'),
          DogRelationshipLevel.parallelCaution);
      expect(parseRelationshipLevel('incompatible'),
          DogRelationshipLevel.incompatible);
    });

    test('parseRelationshipLevel defaults to incompatible for unknown', () {
      expect(parseRelationshipLevel('unknown'),
          DogRelationshipLevel.incompatible);
      expect(
          parseRelationshipLevel(''), DogRelationshipLevel.incompatible);
    });

    test('relationshipLevelToString round-trips', () {
      for (final level in DogRelationshipLevel.values) {
        expect(
          parseRelationshipLevel(relationshipLevelToString(level)),
          level,
        );
      }
    });

    test('relationshipLevelDisplayName returns English labels', () {
      expect(relationshipLevelDisplayName(DogRelationshipLevel.yard),
          'Yard pair');
      expect(
          relationshipLevelDisplayName(DogRelationshipLevel.contactGood),
          'Contact+');
      expect(
          relationshipLevelDisplayName(DogRelationshipLevel.contactCaution),
          'Contact-');
      expect(
          relationshipLevelDisplayName(DogRelationshipLevel.parallelGood),
          'Parallel+');
      expect(
          relationshipLevelDisplayName(
              DogRelationshipLevel.parallelCaution),
          'Parallel-');
      expect(
          relationshipLevelDisplayName(DogRelationshipLevel.incompatible),
          'Incompatible');
    });
  });

  group('DogRelationship', () {
    test('fromJson parses correctly', () {
      final r = DogRelationship.fromJson({
        'id': 1,
        'dog_id_1': 10,
        'dog_id_2': 20,
        'dog_name_1': 'Burek',
        'dog_name_2': 'Azor',
        'level': 'yard',
        'notes': 'Good friends',
      });

      expect(r.id, 1);
      expect(r.dogId1, 10);
      expect(r.dogId2, 20);
      expect(r.dogName1, 'Burek');
      expect(r.dogName2, 'Azor');
      expect(r.level, DogRelationshipLevel.yard);
      expect(r.notes, 'Good friends');
    });

    test('fromJson handles null notes', () {
      final r = DogRelationship.fromJson({
        'id': 1,
        'dog_id_1': 10,
        'dog_id_2': 20,
        'dog_name_1': 'Burek',
        'dog_name_2': 'Azor',
        'level': 'incompatible',
        'notes': null,
      });

      expect(r.notes, isNull);
      expect(r.level, DogRelationshipLevel.incompatible);
    });

    test('otherDogName returns correct name', () {
      const r = DogRelationship(
        id: 1,
        dogId1: 10,
        dogId2: 20,
        dogName1: 'Burek',
        dogName2: 'Azor',
        level: DogRelationshipLevel.yard,
      );

      expect(r.otherDogName(10), 'Azor');
      expect(r.otherDogName(20), 'Burek');
    });

    test('otherDogId returns correct id', () {
      const r = DogRelationship(
        id: 1,
        dogId1: 10,
        dogId2: 20,
        dogName1: 'Burek',
        dogName2: 'Azor',
        level: DogRelationshipLevel.contactGood,
      );

      expect(r.otherDogId(10), 20);
      expect(r.otherDogId(20), 10);
    });
  });
}

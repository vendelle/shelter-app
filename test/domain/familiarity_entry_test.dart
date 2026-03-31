import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/manage/data/manage_repository.dart';
import 'package:shelter_app/features/planner/domain/planner_dog.dart';

void main() {
  group('FamiliarityEntry', () {
    test('fromJson parses good level', () {
      final entry = FamiliarityEntry.fromJson({
        'volunteer_id': 1,
        'dog_id': 2,
        'level': 'good',
      });

      expect(entry.volunteerId, 1);
      expect(entry.dogId, 2);
      expect(entry.level, DogFamiliarityLevel.good);
    });

    test('fromJson parses difficult level', () {
      final entry = FamiliarityEntry.fromJson({
        'volunteer_id': 3,
        'dog_id': 4,
        'level': 'difficult',
      });

      expect(entry.level, DogFamiliarityLevel.difficult);
    });

    test('fromJson parses never level', () {
      final entry = FamiliarityEntry.fromJson({
        'volunteer_id': 1,
        'dog_id': 1,
        'level': 'never',
      });

      expect(entry.level, DogFamiliarityLevel.never);
    });

    test('fromJson defaults unknown level string to unknown', () {
      final entry = FamiliarityEntry.fromJson({
        'volunteer_id': 1,
        'dog_id': 1,
        'level': 'something_else',
      });

      expect(entry.level, DogFamiliarityLevel.unknown);
    });

    test('familiarityToString converts levels correctly', () {
      expect(FamiliarityEntry.familiarityToString(DogFamiliarityLevel.good), 'good');
      expect(FamiliarityEntry.familiarityToString(DogFamiliarityLevel.difficult), 'difficult');
      expect(FamiliarityEntry.familiarityToString(DogFamiliarityLevel.never), 'never');
      expect(FamiliarityEntry.familiarityToString(DogFamiliarityLevel.unknown), 'unknown');
    });
  });
}

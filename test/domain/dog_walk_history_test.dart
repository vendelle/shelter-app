import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/dog_detail/domain/dog_walk_history.dart';

void main() {
  group('DogWalkHistory', () {
    test('fromJson parses walk with group dogs', () {
      final w = DogWalkHistory.fromJson({
        'walk_date': '2025-01-15',
        'volunteer_name': 'Anna',
        'group_index': 1,
        'notes': 'Good walk',
        'group_dogs': [
          {'dog_id': 5, 'dog_name': 'Azor'},
          {'dog_id': 8, 'dog_name': 'Rex'},
        ],
      });

      expect(w.walkDate, '2025-01-15');
      expect(w.volunteerName, 'Anna');
      expect(w.groupIndex, 1);
      expect(w.notes, 'Good walk');
      expect(w.groupDogs, hasLength(2));
      expect(w.groupDogs[0].dogId, 5);
      expect(w.groupDogs[0].dogName, 'Azor');
      expect(w.groupDogs[1].dogId, 8);
      expect(w.groupDogs[1].dogName, 'Rex');
    });

    test('fromJson handles solo walk', () {
      final w = DogWalkHistory.fromJson({
        'walk_date': '2025-01-10',
        'volunteer_name': 'Jan',
        'group_index': 0,
        'notes': null,
        'group_dogs': [],
      });

      expect(w.walkDate, '2025-01-10');
      expect(w.volunteerName, 'Jan');
      expect(w.groupIndex, 0);
      expect(w.notes, isNull);
      expect(w.groupDogs, isEmpty);
    });

    test('fromJson handles missing group_dogs key', () {
      final w = DogWalkHistory.fromJson({
        'walk_date': '2025-01-10',
        'volunteer_name': 'Jan',
        'group_index': 0,
        'notes': null,
      });

      expect(w.groupDogs, isEmpty);
    });
  });

  group('GroupDog', () {
    test('fromJson parses correctly', () {
      final g = GroupDog.fromJson({
        'dog_id': 42,
        'dog_name': 'Fido',
      });

      expect(g.dogId, 42);
      expect(g.dogName, 'Fido');
    });
  });
}

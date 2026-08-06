import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/dog_detail/domain/dog_relationship.dart';
import 'package:shelter_app/features/dog_detail/domain/walk_partner.dart';

void main() {
  group('WalkPartner', () {
    test('fromJson parses all fields', () {
      final p = WalkPartner.fromJson({
        'dog_id': 5,
        'dog_name': 'Boczek',
        'last_shared_walk': '2026-05-27',
        'level': 'contact_good',
        'notes': 'Friendly pair',
      });

      expect(p.dogId, 5);
      expect(p.dogName, 'Boczek');
      expect(p.lastSharedWalk, '2026-05-27');
      expect(p.level, DogRelationshipLevel.contactGood);
      expect(p.notes, 'Friendly pair');
    });

    test('fromJson handles null level and notes', () {
      final p = WalkPartner.fromJson({
        'dog_id': 8,
        'dog_name': 'Burbon',
        'last_shared_walk': '2026-05-16',
        'level': null,
        'notes': null,
      });

      expect(p.dogId, 8);
      expect(p.dogName, 'Burbon');
      expect(p.level, isNull);
      expect(p.notes, isNull);
    });

    test('fromJson strips time portion from ISO date', () {
      final p = WalkPartner.fromJson({
        'dog_id': 1,
        'dog_name': 'Rex',
        'last_shared_walk': '2026-05-27T00:00:00.000Z',
        'level': null,
        'notes': null,
      });

      expect(p.lastSharedWalk, '2026-05-27');
    });

    test('levelSortPriority orders from strongest to weakest', () {
      final yard = WalkPartner(
        dogId: 1,
        dogName: 'A',
        lastSharedWalk: '2026-01-01',
        level: DogRelationshipLevel.yard,
      );
      final contactGood = WalkPartner(
        dogId: 2,
        dogName: 'B',
        lastSharedWalk: '2026-01-01',
        level: DogRelationshipLevel.contactGood,
      );
      final incompatible = WalkPartner(
        dogId: 3,
        dogName: 'C',
        lastSharedWalk: '2026-01-01',
        level: DogRelationshipLevel.incompatible,
      );
      final noLevel = WalkPartner(
        dogId: 4,
        dogName: 'D',
        lastSharedWalk: '2026-01-01',
      );

      expect(yard.levelSortPriority, lessThan(contactGood.levelSortPriority));
      expect(contactGood.levelSortPriority,
          lessThan(incompatible.levelSortPriority));
      expect(incompatible.levelSortPriority,
          lessThan(noLevel.levelSortPriority));
    });
  });
}

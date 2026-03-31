import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/planner/domain/volunteer_assignment.dart';

void main() {
  group('DogEntry', () {
    test('creates with required fields', () {
      const dog = DogEntry(dogId: 1, dogName: 'Burek');

      expect(dog.dogId, 1);
      expect(dog.dogName, 'Burek');
      expect(dog.kennel, isNull);
      expect(dog.groupIndex, isNull);
      expect(dog.note, isNull);
    });

    test('creates with all fields', () {
      const dog = DogEntry(
        dogId: 1,
        dogName: 'Burek',
        kennel: 'A1',
        groupIndex: 2,
        note: 'shy dog',
      );

      expect(dog.kennel, 'A1');
      expect(dog.groupIndex, 2);
      expect(dog.note, 'shy dog');
    });

    test('copyWith updates note', () {
      const original = DogEntry(dogId: 1, dogName: 'Burek', note: 'old');
      final updated = original.copyWith(note: () => 'new note');

      expect(updated.note, 'new note');
      expect(original.note, 'old'); // immutable
    });

    test('copyWith clears note with null', () {
      const original = DogEntry(dogId: 1, dogName: 'Burek', note: 'has note');
      final updated = original.copyWith(note: () => null);

      expect(updated.note, isNull);
    });

    test('copyWith updates groupIndex', () {
      const original = DogEntry(dogId: 1, dogName: 'Burek');
      final updated = original.copyWith(groupIndex: () => 3);

      expect(updated.groupIndex, 3);
      expect(original.groupIndex, isNull);
    });

    test('copyWith clears groupIndex with null', () {
      const original = DogEntry(dogId: 1, dogName: 'Burek', groupIndex: 2);
      final updated = original.copyWith(groupIndex: () => null);

      expect(updated.groupIndex, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      const original = DogEntry(
        dogId: 1,
        dogName: 'Burek',
        kennel: 'A1',
        groupIndex: 2,
        note: 'shy',
      );
      final updated = original.copyWith(note: () => 'bold');

      expect(updated.dogId, 1);
      expect(updated.dogName, 'Burek');
      expect(updated.kennel, 'A1');
      expect(updated.groupIndex, 2);
      expect(updated.note, 'bold');
    });
  });

  group('VolunteerAssignment', () {
    test('creates with required fields and empty dogs list', () {
      final assignment = VolunteerAssignment(
        volunteerId: 1,
        volunteerName: 'Anna Kowalska',
      );

      expect(assignment.volunteerId, 1);
      expect(assignment.volunteerName, 'Anna Kowalska');
      expect(assignment.dogs, isEmpty);
      expect(assignment.note, isNull);
    });;

    test('creates with dogs and note', () {
      final assignment = VolunteerAssignment(
        volunteerId: 1,
        volunteerName: 'Anna Kowalska',
        dogs: [
          const DogEntry(dogId: 10, dogName: 'Burek'),
          const DogEntry(dogId: 11, dogName: 'Luna'),
        ],
        note: '10-13 only',
      );

      expect(assignment.dogs, hasLength(2));
      expect(assignment.note, '10-13 only');
    });

    test('dogs list is mutable (can add dogs after creation)', () {
      final assignment = VolunteerAssignment(
        volunteerId: 1,
        volunteerName: 'Anna Kowalska',
      );

      assignment.dogs.add(const DogEntry(dogId: 10, dogName: 'Burek'));

      expect(assignment.dogs, hasLength(1));
      expect(assignment.dogs.first.dogName, 'Burek');
    });

    test('copyWith updates note', () {
      final original = VolunteerAssignment(
        volunteerId: 1,
        volunteerName: 'Anna Kowalska',
        note: 'old',
      );
      final updated = original.copyWith(note: () => 'new');

      expect(updated.note, 'new');
      expect(original.note, 'old');
    });

    test('copyWith preserves dogs list', () {
      final original = VolunteerAssignment(
        volunteerId: 1,
        volunteerName: 'Anna Kowalska',
        dogs: [const DogEntry(dogId: 10, dogName: 'Burek')],
      );
      final updated = original.copyWith(note: () => 'added note');

      expect(updated.dogs, hasLength(1));
      expect(updated.dogs.first.dogId, 10);
    });
  });
}

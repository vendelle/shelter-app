import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/planner/domain/volunteer_assignment.dart';
import 'package:shelter_app/features/planner/presentation/providers/planner_providers.dart';

void main() {
  group('PlannerState', () {
    test('default state is loading with no assignments', () {
      const state = PlannerState();

      expect(state.assignments, isEmpty);
      expect(state.isSaving, isFalse);
      expect(state.isLoading, isTrue);
      expect(state.error, isNull);
    });

    test('copyWith updates fields independently', () {
      const original = PlannerState();
      final updated = original.copyWith(
        isLoading: false,
        isSaving: true,
      );

      expect(updated.isLoading, isFalse);
      expect(updated.isSaving, isTrue);
      expect(updated.assignments, isEmpty);
    });

    test('copyWith can clear error', () {
      final withError = const PlannerState().copyWith(error: 'oops');
      expect(withError.error, 'oops');

      final cleared = withError.copyWith(error: null);
      expect(cleared.error, isNull);
    });

    group('assignedDogIds', () {
      test('returns empty set for no assignments', () {
        const state = PlannerState(assignments: []);
        expect(state.assignedDogIds, isEmpty);
      });

      test('collects all dog IDs across volunteers', () {
        final state = PlannerState(
          isLoading: false,
          assignments: [
            VolunteerAssignment(
              volunteerId: 1,
              volunteerName: 'Anna',
              dogs: [
                const DogEntry(dogId: 10, dogName: 'Burek'),
                const DogEntry(dogId: 11, dogName: 'Luna'),
              ],
            ),
            VolunteerAssignment(
              volunteerId: 2,
              volunteerName: 'Jan',
              dogs: [
                const DogEntry(dogId: 12, dogName: 'Rex'),
              ],
            ),
          ],
        );

        expect(state.assignedDogIds, {10, 11, 12});
      });
    });

    group('maxGroupIndex', () {
      test('returns 0 when no groups assigned', () {
        final state = PlannerState(
          isLoading: false,
          assignments: [
            VolunteerAssignment(
              volunteerId: 1,
              volunteerName: 'Anna',
              dogs: [const DogEntry(dogId: 10, dogName: 'Burek')],
            ),
          ],
        );

        expect(state.maxGroupIndex, 0);
      });

      test('returns highest group index', () {
        final state = PlannerState(
          isLoading: false,
          assignments: [
            VolunteerAssignment(
              volunteerId: 1,
              volunteerName: 'Anna',
              dogs: [
                const DogEntry(dogId: 10, dogName: 'Burek', groupIndex: 1),
                const DogEntry(dogId: 11, dogName: 'Luna', groupIndex: 3),
              ],
            ),
            VolunteerAssignment(
              volunteerId: 2,
              volunteerName: 'Jan',
              dogs: [
                const DogEntry(dogId: 12, dogName: 'Rex', groupIndex: 2),
              ],
            ),
          ],
        );

        expect(state.maxGroupIndex, 3);
      });
    });

    group('isModified', () {
      test('returns false for identical state', () {
        final saved = [
          VolunteerAssignment(
            volunteerId: 1,
            volunteerName: 'Anna',
            dogs: [const DogEntry(dogId: 10, dogName: 'Burek')],
          ),
        ];
        final state = PlannerState(
          isLoading: false,
          assignments: [
            VolunteerAssignment(
              volunteerId: 1,
              volunteerName: 'Anna',
              dogs: [const DogEntry(dogId: 10, dogName: 'Burek')],
            ),
          ],
        );

        expect(state.isModified(saved), isFalse);
      });

      test('returns true when assignment count differs', () {
        final saved = <VolunteerAssignment>[];
        final state = PlannerState(
          isLoading: false,
          assignments: [
            VolunteerAssignment(volunteerId: 1, volunteerName: 'Anna'),
          ],
        );

        expect(state.isModified(saved), isTrue);
      });

      test('returns true when volunteer changed', () {
        final saved = [
          VolunteerAssignment(volunteerId: 1, volunteerName: 'Anna'),
        ];
        final state = PlannerState(
          isLoading: false,
          assignments: [
            VolunteerAssignment(volunteerId: 2, volunteerName: 'Jan'),
          ],
        );

        expect(state.isModified(saved), isTrue);
      });

      test('returns true when volunteer note changed', () {
        final saved = [
          VolunteerAssignment(
            volunteerId: 1,
            volunteerName: 'Anna',
            note: 'old',
          ),
        ];
        final state = PlannerState(
          isLoading: false,
          assignments: [
            VolunteerAssignment(
              volunteerId: 1,
              volunteerName: 'Anna',
              note: 'new',
            ),
          ],
        );

        expect(state.isModified(saved), isTrue);
      });

      test('returns true when dog count changed', () {
        final saved = [
          VolunteerAssignment(
            volunteerId: 1,
            volunteerName: 'Anna',
            dogs: [const DogEntry(dogId: 10, dogName: 'Burek')],
          ),
        ];
        final state = PlannerState(
          isLoading: false,
          assignments: [
            VolunteerAssignment(
              volunteerId: 1,
              volunteerName: 'Anna',
              dogs: [
                const DogEntry(dogId: 10, dogName: 'Burek'),
                const DogEntry(dogId: 11, dogName: 'Luna'),
              ],
            ),
          ],
        );

        expect(state.isModified(saved), isTrue);
      });

      test('returns true when dog group changed', () {
        final saved = [
          VolunteerAssignment(
            volunteerId: 1,
            volunteerName: 'Anna',
            dogs: [
              const DogEntry(dogId: 10, dogName: 'Burek', groupIndex: 1),
            ],
          ),
        ];
        final state = PlannerState(
          isLoading: false,
          assignments: [
            VolunteerAssignment(
              volunteerId: 1,
              volunteerName: 'Anna',
              dogs: [
                const DogEntry(dogId: 10, dogName: 'Burek', groupIndex: 2),
              ],
            ),
          ],
        );

        expect(state.isModified(saved), isTrue);
      });

      test('returns true when dog note changed', () {
        final saved = [
          VolunteerAssignment(
            volunteerId: 1,
            volunteerName: 'Anna',
            dogs: [const DogEntry(dogId: 10, dogName: 'Burek')],
          ),
        ];
        final state = PlannerState(
          isLoading: false,
          assignments: [
            VolunteerAssignment(
              volunteerId: 1,
              volunteerName: 'Anna',
              dogs: [
                const DogEntry(dogId: 10, dogName: 'Burek', note: 'shy'),
              ],
            ),
          ],
        );

        expect(state.isModified(saved), isTrue);
      });
    });
  });
}

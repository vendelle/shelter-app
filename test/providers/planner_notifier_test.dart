import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelter_app/core/locale/locale_provider.dart';
import 'package:shelter_app/features/planner/data/planner_repository.dart';
import 'package:shelter_app/features/planner/domain/planner_dog.dart';
import 'package:shelter_app/features/planner/domain/volunteer_assignment.dart';
import 'package:shelter_app/features/planner/presentation/providers/planner_providers.dart';
import 'package:shelter_app/features/shared/domain/volunteer.dart';

/// A fake PlannerRepository that returns predetermined data.
class FakePlannerRepository implements PlannerRepository {
  List<VolunteerAssignment> assignments = [];
  int saveCallCount = 0;
  List<VolunteerAssignment>? lastSavedAssignments;
  Completer<void>? saveCompleter;

  @override
  Future<List<VolunteerAssignment>> getAssignments(DateTime date) async {
    return assignments;
  }

  @override
  Future<void> saveAssignments(
      DateTime date, List<VolunteerAssignment> assignments) async {
    saveCallCount++;
    lastSavedAssignments = assignments;
    if (saveCompleter != null) {
      await saveCompleter!.future;
    }
  }

  @override
  Future<List<Volunteer>> getVolunteers() async => [];

  @override
  Future<List<PlannerDog>> getDogsForVolunteer(int volunteerId) async => [];

  @override
  Future<int> getDogCount() async => 0;
}

void main() {
  group('PlannerNotifier', () {
    late ProviderContainer container;
    late FakePlannerRepository fakeRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      fakeRepo = FakePlannerRepository();
      fakeRepo.assignments = [
        VolunteerAssignment(
          volunteerId: 1,
          volunteerName: 'Anna',
          dogs: [
            const DogEntry(dogId: 10, dogName: 'Burek'),
            const DogEntry(dogId: 11, dogName: 'Luna'),
            const DogEntry(dogId: 12, dogName: 'Rex'),
          ],
        ),
        VolunteerAssignment(
          volunteerId: 2,
          volunteerName: 'Jan',
          dogs: [
            const DogEntry(dogId: 20, dogName: 'Fido'),
          ],
        ),
      ];

      container = ProviderContainer(
        overrides: [
          plannerRepositoryProvider.overrideWithValue(fakeRepo),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    Future<void> waitForLoad() async {
      // Wait for the notifier to finish loading via microtask loop
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(Duration.zero);
        final state = container.read(plannerNotifierProvider);
        if (!state.isLoading) break;
      }
    }

    group('reorderDogs', () {
      test('moves a dog from position 0 to position 2', () async {
        await waitForLoad();
        final notifier = container.read(plannerNotifierProvider.notifier);
        final state = container.read(plannerNotifierProvider);

        expect(state.assignments[0].dogs.map((d) => d.dogName).toList(),
            ['Burek', 'Luna', 'Rex']);

        notifier.reorderDogs(1, 0, 2);

        final updated = container.read(plannerNotifierProvider);
        expect(updated.assignments[0].dogs.map((d) => d.dogName).toList(),
            ['Luna', 'Rex', 'Burek']);
      });

      test('moves a dog from position 2 to position 0', () async {
        await waitForLoad();
        final notifier = container.read(plannerNotifierProvider.notifier);

        notifier.reorderDogs(1, 2, 0);

        final updated = container.read(plannerNotifierProvider);
        expect(updated.assignments[0].dogs.map((d) => d.dogName).toList(),
            ['Rex', 'Burek', 'Luna']);
      });

      test('does nothing when oldIndex == newIndex', () async {
        await waitForLoad();
        final notifier = container.read(plannerNotifierProvider.notifier);

        notifier.reorderDogs(1, 1, 1);

        final updated = container.read(plannerNotifierProvider);
        expect(updated.assignments[0].dogs.map((d) => d.dogName).toList(),
            ['Burek', 'Luna', 'Rex']);
      });

      test('only affects the targeted volunteer', () async {
        await waitForLoad();
        final notifier = container.read(plannerNotifierProvider.notifier);

        notifier.reorderDogs(1, 0, 2);

        final updated = container.read(plannerNotifierProvider);
        // Volunteer 2 should be unchanged
        expect(updated.assignments[1].dogs.map((d) => d.dogName).toList(),
            ['Fido']);
      });
    });

    group('auto-save', () {
      test('triggers save after 2 seconds of inactivity', () async {
        await waitForLoad();
        final notifier = container.read(plannerNotifierProvider.notifier);

        notifier.reorderDogs(1, 0, 1);
        expect(fakeRepo.saveCallCount, 0);

        // Wait for debounce (2s + buffer)
        await Future<void>.delayed(const Duration(milliseconds: 2200));

        expect(fakeRepo.saveCallCount, 1);
        expect(fakeRepo.lastSavedAssignments, isNotNull);
      });

      test('resets timer on subsequent changes', () async {
        await waitForLoad();
        final notifier = container.read(plannerNotifierProvider.notifier);

        notifier.reorderDogs(1, 0, 1);
        await Future<void>.delayed(const Duration(milliseconds: 1000));

        // Another change before debounce fires
        notifier.reorderDogs(1, 0, 1);
        await Future<void>.delayed(const Duration(milliseconds: 1500));

        // Should not have fired yet (only 1.5s since last change)
        expect(fakeRepo.saveCallCount, 0);

        await Future<void>.delayed(const Duration(milliseconds: 700));

        // Now it should have fired (2.2s since last change)
        expect(fakeRepo.saveCallCount, 1);
      });

      test('sets saveStatus to saving then saved', () async {
        await waitForLoad();
        final notifier = container.read(plannerNotifierProvider.notifier);

        notifier.reorderDogs(1, 0, 1);

        // Wait for debounce
        await Future<void>.delayed(const Duration(milliseconds: 2200));

        final state = container.read(plannerNotifierProvider);
        expect(state.saveStatus, SaveStatus.saved);
      });

      test('sets saveStatus to error on save failure', () async {
        // Use a repo that throws on save
        final failingRepo = FakePlannerRepository();
        failingRepo.assignments = fakeRepo.assignments;

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final failContainer = ProviderContainer(
          overrides: [
            plannerRepositoryProvider.overrideWithValue(failingRepo),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
        );
        addTearDown(failContainer.dispose);

        // Wait for load
        for (var i = 0; i < 10; i++) {
          await Future<void>.delayed(Duration.zero);
          if (!failContainer.read(plannerNotifierProvider).isLoading) break;
        }

        // Make subsequent saves throw
        failingRepo.saveCompleter = Completer<void>();

        final notifier = failContainer.read(plannerNotifierProvider.notifier);
        notifier.reorderDogs(1, 0, 1);

        // Complete with error after the debounce starts the save
        await Future<void>.delayed(const Duration(milliseconds: 2100));
        failingRepo.saveCompleter!.completeError(Exception('Network error'));
        await Future<void>.delayed(const Duration(milliseconds: 200));

        final state = failContainer.read(plannerNotifierProvider);
        expect(state.saveStatus, SaveStatus.error);
      });
    });

    group('saveStatus', () {
      test('default saveStatus is idle', () async {
        await waitForLoad();
        final state = container.read(plannerNotifierProvider);
        expect(state.saveStatus, SaveStatus.idle);
      });

      test('saveStatus becomes unsaved immediately after mutation', () async {
        await waitForLoad();
        final notifier = container.read(plannerNotifierProvider.notifier);

        notifier.reorderDogs(1, 0, 1);

        final state = container.read(plannerNotifierProvider);
        expect(state.saveStatus, SaveStatus.unsaved);
      });
    });

    group('toggleAutoSave', () {
      test('defaults to autoSaveEnabled = true', () async {
        await waitForLoad();
        final state = container.read(plannerNotifierProvider);
        expect(state.autoSaveEnabled, isTrue);
      });

      test('toggleAutoSave disables auto-save and cancels pending timer',
          () async {
        await waitForLoad();
        final notifier = container.read(plannerNotifierProvider.notifier);

        notifier.reorderDogs(1, 0, 1);
        notifier.toggleAutoSave();

        // Wait past debounce — should NOT save
        await Future<void>.delayed(const Duration(milliseconds: 2500));
        expect(fakeRepo.saveCallCount, 0);

        final state = container.read(plannerNotifierProvider);
        expect(state.autoSaveEnabled, isFalse);
        expect(state.saveStatus, SaveStatus.unsaved);
      });

      test('toggleAutoSave re-enables and triggers save if unsaved', () async {
        await waitForLoad();
        final notifier = container.read(plannerNotifierProvider.notifier);

        // Disable auto-save, make a change
        notifier.toggleAutoSave();
        notifier.reorderDogs(1, 0, 1);

        // Re-enable — should schedule save
        notifier.toggleAutoSave();

        await Future<void>.delayed(const Duration(milliseconds: 2200));
        expect(fakeRepo.saveCallCount, 1);
      });

      test('manual save() works when auto-save is off', () async {
        await waitForLoad();
        final notifier = container.read(plannerNotifierProvider.notifier);

        notifier.toggleAutoSave(); // disable
        notifier.reorderDogs(1, 0, 1);

        expect(fakeRepo.saveCallCount, 0);
        await notifier.save();
        expect(fakeRepo.saveCallCount, 1);

        final state = container.read(plannerNotifierProvider);
        expect(state.saveStatus, SaveStatus.saved);
      });
    });
  });
}

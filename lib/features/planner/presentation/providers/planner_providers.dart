import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/volunteer.dart';
import '../../data/planner_repository.dart';
import '../../domain/planner_dog.dart';
import '../../domain/volunteer_assignment.dart';

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  return MockPlannerRepository();
});

// ---------------------------------------------------------------------------
// Selected date
// ---------------------------------------------------------------------------

final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

// ---------------------------------------------------------------------------
// Saved assignments (from "server") for the selected date
// ---------------------------------------------------------------------------

final savedAssignmentsProvider =
    FutureProvider<List<VolunteerAssignment>>((ref) {
  final repo = ref.watch(plannerRepositoryProvider);
  final date = ref.watch(selectedDateProvider);
  return repo.getAssignments(date);
});

// ---------------------------------------------------------------------------
// Editable state — a Notifier that starts from saved data
// ---------------------------------------------------------------------------

final plannerNotifierProvider =
    StateNotifierProvider<PlannerNotifier, PlannerState>((ref) {
  return PlannerNotifier(ref);
});

class PlannerState {
  final List<VolunteerAssignment> assignments;
  final bool isSaving;
  final bool isLoading;
  final String? error;

  const PlannerState({
    this.assignments = const [],
    this.isSaving = false,
    this.isLoading = true,
    this.error,
  });

  PlannerState copyWith({
    List<VolunteerAssignment>? assignments,
    bool? isSaving,
    bool? isLoading,
    String? error,
  }) {
    return PlannerState(
      assignments: assignments ?? this.assignments,
      isSaving: isSaving ?? this.isSaving,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// IDs of all dogs currently assigned across all volunteers.
  Set<int> get assignedDogIds {
    return {
      for (final a in assignments)
        for (final d in a.dogs) d.dogId,
    };
  }

  /// The highest group index currently in use across all assignments.
  int get maxGroupIndex {
    int max = 0;
    for (final a in assignments) {
      for (final d in a.dogs) {
        if (d.groupIndex != null && d.groupIndex! > max) {
          max = d.groupIndex!;
        }
      }
    }
    return max;
  }

  /// Whether the current plan has been modified since loading.
  bool isModified(List<VolunteerAssignment> saved) {
    if (assignments.length != saved.length) return true;
    for (var i = 0; i < assignments.length; i++) {
      final a = assignments[i];
      final s = saved[i];
      if (a.volunteerId != s.volunteerId) return true;
      if (a.note != s.note) return true;
      if (a.dogs.length != s.dogs.length) return true;
      for (var j = 0; j < a.dogs.length; j++) {
        if (a.dogs[j].dogId != s.dogs[j].dogId) return true;
        if (a.dogs[j].groupIndex != s.dogs[j].groupIndex) return true;
        if (a.dogs[j].note != s.dogs[j].note) return true;
      }
    }
    return false;
  }
}

class PlannerNotifier extends StateNotifier<PlannerState> {
  PlannerNotifier(this._ref) : super(const PlannerState()) {
    _loadForDate(_ref.read(selectedDateProvider));

    _ref.listen(selectedDateProvider, (_, date) {
      _loadForDate(date);
    });
  }

  final Ref _ref;

  Future<void> _loadForDate(DateTime date) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(plannerRepositoryProvider);
      final assignments = await repo.getAssignments(date);
      state = PlannerState(
        assignments: assignments,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void addVolunteer(Volunteer volunteer) {
    if (state.assignments.any((a) => a.volunteerId == volunteer.id)) return;
    state = state.copyWith(
      assignments: [
        ...state.assignments,
        VolunteerAssignment(
          volunteerId: volunteer.id,
          volunteerName: volunteer.fullName,
        ),
      ],
    );
  }

  void removeVolunteer(int volunteerId) {
    state = state.copyWith(
      assignments:
          state.assignments.where((a) => a.volunteerId != volunteerId).toList(),
    );
  }

  void addDogEntry(int volunteerId, DogEntry entry) {
    state = state.copyWith(
      assignments: state.assignments.map((a) {
        if (a.volunteerId != volunteerId) return a;
        if (a.dogs.any((d) => d.dogId == entry.dogId)) return a;
        return a.copyWith(dogs: [...a.dogs, entry]);
      }).toList(),
    );
  }

  void addDogEntries(int volunteerId, List<DogEntry> entries) {
    state = state.copyWith(
      assignments: state.assignments.map((a) {
        if (a.volunteerId != volunteerId) return a;
        final existingIds = a.dogs.map((d) => d.dogId).toSet();
        final newEntries =
            entries.where((e) => !existingIds.contains(e.dogId)).toList();
        return a.copyWith(dogs: [...a.dogs, ...newEntries]);
      }).toList(),
    );
  }

  void removeDogFromVolunteer(int volunteerId, int dogId) {
    state = state.copyWith(
      assignments: state.assignments.map((a) {
        if (a.volunteerId != volunteerId) return a;
        return a.copyWith(
            dogs: a.dogs.where((d) => d.dogId != dogId).toList());
      }).toList(),
    );
  }

  void updateDogGroup(int volunteerId, int dogId, int? groupIndex) {
    state = state.copyWith(
      assignments: state.assignments.map((a) {
        if (a.volunteerId != volunteerId) return a;
        return a.copyWith(
          dogs: a.dogs.map((d) {
            if (d.dogId != dogId) return d;
            return d.copyWith(groupIndex: () => groupIndex);
          }).toList(),
        );
      }).toList(),
    );
  }

  void updateDogNote(int volunteerId, int dogId, String? note) {
    state = state.copyWith(
      assignments: state.assignments.map((a) {
        if (a.volunteerId != volunteerId) return a;
        return a.copyWith(
          dogs: a.dogs.map((d) {
            if (d.dogId != dogId) return d;
            return d.copyWith(note: () => note);
          }).toList(),
        );
      }).toList(),
    );
  }

  void updateVolunteerNote(int volunteerId, String? note) {
    state = state.copyWith(
      assignments: state.assignments.map((a) {
        if (a.volunteerId != volunteerId) return a;
        return a.copyWith(note: () => note);
      }).toList(),
    );
  }

  Future<void> save() async {
    state = state.copyWith(isSaving: true);
    try {
      final repo = _ref.read(plannerRepositoryProvider);
      final date = _ref.read(selectedDateProvider);
      await repo.saveAssignments(date, state.assignments);
      // Refresh the "saved" baseline
      _ref.invalidate(savedAssignmentsProvider);
      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
    }
  }

  void reload() {
    _loadForDate(_ref.read(selectedDateProvider));
  }
}

// ---------------------------------------------------------------------------
// All volunteers (for the "add volunteer" dialog)
// ---------------------------------------------------------------------------

final allVolunteersProvider = FutureProvider<List<Volunteer>>((ref) {
  final repo = ref.watch(plannerRepositoryProvider);
  return repo.getVolunteers();
});

// ---------------------------------------------------------------------------
// Dogs for a specific volunteer (for the "add dog" dialog)
// ---------------------------------------------------------------------------

final dogsForVolunteerProvider =
    FutureProvider.family<List<PlannerDog>, int>((ref, volunteerId) {
  final repo = ref.watch(plannerRepositoryProvider);
  return repo.getDogsForVolunteer(volunteerId);
});

// ---------------------------------------------------------------------------
// Total dog count (for stats display)
// ---------------------------------------------------------------------------

final totalDogCountProvider = FutureProvider<int>((ref) {
  final repo = ref.watch(plannerRepositoryProvider);
  return repo.getDogCount();
});

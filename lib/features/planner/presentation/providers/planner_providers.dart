import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_providers.dart';
import '../../../../core/locale/locale_provider.dart';
import '../../../shared/domain/volunteer.dart';
import '../../data/planner_repository.dart';
import '../../domain/planner_dog.dart';
import '../../domain/volunteer_assignment.dart';

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  return ApiPlannerRepository(ref.watch(apiClientProvider));
});

// ---------------------------------------------------------------------------
// Selected date
// ---------------------------------------------------------------------------

final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

// ---------------------------------------------------------------------------
// Planner detail level toggle
// ---------------------------------------------------------------------------

/// Detail level for the planner view.
enum PlannerDetailLevel {
  /// Single-line dog rows (name + kennel). Default.
  compact,
  /// Two-line dog rows (name, then shelterId · kennel · region).
  detailed,
  /// Ultra-compact read-only-looking overview: hides add buttons, tighter
  /// spacing, and attempts more columns. Useful for screenshots.
  overview,
}

final plannerDetailLevelProvider =
    StateProvider<PlannerDetailLevel>((ref) => PlannerDetailLevel.compact);

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

/// Status of the auto-save mechanism.
enum SaveStatus { idle, unsaved, saving, saved, error }

class PlannerState {
  final List<VolunteerAssignment> assignments;
  final bool isSaving;
  final bool isLoading;
  final String? error;
  final SaveStatus saveStatus;
  final bool autoSaveEnabled;

  const PlannerState({
    this.assignments = const [],
    this.isSaving = false,
    this.isLoading = true,
    this.error,
    this.saveStatus = SaveStatus.idle,
    this.autoSaveEnabled = true,
  });

  PlannerState copyWith({
    List<VolunteerAssignment>? assignments,
    bool? isSaving,
    bool? isLoading,
    String? error,
    SaveStatus? saveStatus,
    bool? autoSaveEnabled,
  }) {
    return PlannerState(
      assignments: assignments ?? this.assignments,
      isSaving: isSaving ?? this.isSaving,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      saveStatus: saveStatus ?? this.saveStatus,
      autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
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
    _initAutoSave();
    _loadForDate(_ref.read(selectedDateProvider));

    _ref.listen(selectedDateProvider, (_, date) {
      _loadForDate(date);
    });
  }

  final Ref _ref;
  Timer? _autoSaveTimer;

  static const _prefsKey = 'planner_autosave';

  void _initAutoSave() {
    final prefs = _ref.read(sharedPreferencesProvider);
    final enabled = prefs.getBool(_prefsKey) ?? true;
    state = state.copyWith(autoSaveEnabled: enabled);
  }

  void toggleAutoSave() {
    final newValue = !state.autoSaveEnabled;
    state = state.copyWith(autoSaveEnabled: newValue);
    _ref.read(sharedPreferencesProvider).setBool(_prefsKey, newValue);
    if (newValue && state.saveStatus == SaveStatus.unsaved) {
      _scheduleAutoSave();
    } else if (!newValue) {
      _autoSaveTimer?.cancel();
    }
  }

  /// Schedule an auto-save after 2 seconds of inactivity.
  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    state = state.copyWith(saveStatus: SaveStatus.unsaved);
    if (!state.autoSaveEnabled) return;
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      _autoSave();
    });
  }

  Future<void> _autoSave() async {
    if (state.isLoading) return;
    state = state.copyWith(saveStatus: SaveStatus.saving);
    try {
      final repo = _ref.read(plannerRepositoryProvider);
      final date = _ref.read(selectedDateProvider);
      await repo.saveAssignments(date, state.assignments);
      _ref.invalidate(savedAssignmentsProvider);
      if (mounted) {
        state = state.copyWith(saveStatus: SaveStatus.saved);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(saveStatus: SaveStatus.error, error: e.toString());
      }
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadForDate(DateTime date) async {
    _autoSaveTimer?.cancel();
    state = state.copyWith(isLoading: true, error: null, saveStatus: SaveStatus.idle);
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
    _scheduleAutoSave();
  }

  void removeVolunteer(int volunteerId) {
    state = state.copyWith(
      assignments:
          state.assignments.where((a) => a.volunteerId != volunteerId).toList(),
    );
    _scheduleAutoSave();
  }

  void addDogEntry(int volunteerId, DogEntry entry) {
    state = state.copyWith(
      assignments: state.assignments.map((a) {
        if (a.volunteerId != volunteerId) return a;
        if (a.dogs.any((d) => d.dogId == entry.dogId)) return a;
        return a.copyWith(dogs: [...a.dogs, entry]);
      }).toList(),
    );
    _scheduleAutoSave();
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
    _scheduleAutoSave();
  }

  void removeDogFromVolunteer(int volunteerId, int dogId) {
    state = state.copyWith(
      assignments: state.assignments.map((a) {
        if (a.volunteerId != volunteerId) return a;
        return a.copyWith(
            dogs: a.dogs.where((d) => d.dogId != dogId).toList());
      }).toList(),
    );
    _scheduleAutoSave();
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
    _scheduleAutoSave();
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
    _scheduleAutoSave();
  }

  void updateVolunteerNote(int volunteerId, String? note) {
    state = state.copyWith(
      assignments: state.assignments.map((a) {
        if (a.volunteerId != volunteerId) return a;
        return a.copyWith(note: () => note);
      }).toList(),
    );
    _scheduleAutoSave();
  }

  /// Reorder dogs within a volunteer's list.
  void reorderDogs(int volunteerId, int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    state = state.copyWith(
      assignments: state.assignments.map((a) {
        if (a.volunteerId != volunteerId) return a;
        final dogs = List<DogEntry>.from(a.dogs);
        final item = dogs.removeAt(oldIndex);
        dogs.insert(newIndex, item);
        return a.copyWith(dogs: dogs);
      }).toList(),
    );
    _scheduleAutoSave();
  }

  Future<void> save() async {
    _autoSaveTimer?.cancel();
    state = state.copyWith(saveStatus: SaveStatus.saving);
    try {
      final repo = _ref.read(plannerRepositoryProvider);
      final date = _ref.read(selectedDateProvider);
      await repo.saveAssignments(date, state.assignments);
      _ref.invalidate(savedAssignmentsProvider);
      state = state.copyWith(saveStatus: SaveStatus.saved);
    } catch (e) {
      state = state.copyWith(saveStatus: SaveStatus.error, error: e.toString());
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

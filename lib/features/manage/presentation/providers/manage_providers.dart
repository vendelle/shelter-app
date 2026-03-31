import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_providers.dart';
import '../../../shared/domain/dog.dart';
import '../../../shared/domain/volunteer.dart';
import '../../../planner/domain/planner_dog.dart';
import '../../data/manage_repository.dart';

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

final manageRepositoryProvider = Provider<ManageRepository>((ref) {
  return ManageRepository(ref.watch(apiClientProvider));
});

// ---------------------------------------------------------------------------
// Show archived toggle
// ---------------------------------------------------------------------------

final showArchivedDogsProvider = StateProvider<bool>((ref) => false);
final showArchivedVolunteersProvider = StateProvider<bool>((ref) => false);

// ---------------------------------------------------------------------------
// Dogs list
// ---------------------------------------------------------------------------

final managedDogsProvider = FutureProvider<List<Dog>>((ref) {
  final repo = ref.watch(manageRepositoryProvider);
  final showArchived = ref.watch(showArchivedDogsProvider);
  return repo.getDogs(onlyArchived: showArchived);
});

// ---------------------------------------------------------------------------
// Volunteers list
// ---------------------------------------------------------------------------

final managedVolunteersProvider = FutureProvider<List<Volunteer>>((ref) {
  final repo = ref.watch(manageRepositoryProvider);
  final showArchived = ref.watch(showArchivedVolunteersProvider);
  return repo.getVolunteers(onlyArchived: showArchived);
});

// ---------------------------------------------------------------------------
// Familiarity for a specific volunteer
// ---------------------------------------------------------------------------

final familiarityProvider =
    FutureProvider.family<Map<int, DogFamiliarityLevel>, int>(
        (ref, volunteerId) async {
  final repo = ref.watch(manageRepositoryProvider);
  try {
    final entries = await repo.getFamiliarity(volunteerId);
    return {for (final e in entries) e.dogId: e.level};
  } catch (_) {
    // Gracefully handle if the familiarity table doesn't exist yet
    return {};
  }
});

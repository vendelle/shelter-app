import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_providers.dart';
import '../../../manage/presentation/providers/manage_providers.dart';
import '../../data/dog_detail_repository.dart';
import '../../domain/dog_relationship.dart';
import '../../domain/dog_walk_history.dart';
import '../../domain/shelter_profile.dart';
import '../../domain/walk_partner.dart';

final dogDetailRepositoryProvider = Provider<DogDetailRepository>((ref) {
  return ApiDogDetailRepository(ref.watch(apiClientProvider));
});

final dogRelationshipsProvider =
    FutureProvider.family<List<DogRelationship>, int>((ref, dogId) {
  return ref.watch(dogDetailRepositoryProvider).getRelationships(dogId);
});

final allRelationshipsProvider =
    FutureProvider<List<DogRelationship>>((ref) {
  return ref.watch(dogDetailRepositoryProvider).getAllRelationships();
});

final dogWalkHistoryProvider =
    FutureProvider.family<List<DogWalkHistory>, int>((ref, dogId) {
  return ref.watch(dogDetailRepositoryProvider).getWalkHistory(dogId);
});

final walkPartnersProvider =
    FutureProvider.family<List<WalkPartner>, int>((ref, dogId) {
  return ref.watch(dogDetailRepositoryProvider).getWalkPartners(dogId);
});

/// All relationships as a lookup map: canonical (min, max) pair → level.
final relationshipLookupProvider =
    FutureProvider<Map<(int, int), DogRelationship>>((ref) async {
  final all = await ref.watch(allRelationshipsProvider.future);
  return {
    for (final r in all)
      (r.dogId1 < r.dogId2 ? r.dogId1 : r.dogId2,
       r.dogId1 < r.dogId2 ? r.dogId2 : r.dogId1): r,
  };
});

// ---------------------------------------------------------------------------
// Shelter website data
// ---------------------------------------------------------------------------

final shelterProfileProvider = AsyncNotifierProvider.autoDispose
    .family<ShelterProfileNotifier, ShelterProfile, int>(
        ShelterProfileNotifier.new);

class ShelterProfileNotifier
    extends AutoDisposeFamilyAsyncNotifier<ShelterProfile, int> {
  DogDetailRepository get _repo => ref.read(dogDetailRepositoryProvider);

  @override
  Future<ShelterProfile> build(int dogId) {
    return ref.watch(dogDetailRepositoryProvider).getShelterProfile(dogId);
  }

  /// "Odśwież teraz". Check [ShelterProfile.refreshFailed] on the result.
  Future<ShelterProfile> refresh() async {
    final profile = await _repo.refreshShelterProfile(arg);
    state = AsyncData(profile);
    return profile;
  }

  /// Admin: take or dismiss the website's kennel/region.
  Future<void> resolveLocationSuggestion({required bool accept}) async {
    state = AsyncData(
        await _repo.resolveLocationSuggestion(arg, accept: accept));
    ref.invalidate(locationSuggestionDogIdsProvider);
    if (accept) ref.invalidate(managedDogsProvider);
  }
}

/// Photo URL per active dog id. Empty when they can't be loaded — lists
/// show a placeholder instead.
final dogPhotoUrlsProvider = FutureProvider<Map<int, String>>((ref) async {
  try {
    return await ref.watch(dogDetailRepositoryProvider).getDogPhotoUrls();
  } catch (_) {
    return const {};
  }
});

/// Active dogs whose website kennel/region differs from ours (admin view).
final locationSuggestionDogIdsProvider =
    FutureProvider.autoDispose<Set<int>>((ref) {
  return ref.watch(dogDetailRepositoryProvider).getLocationSuggestionDogIds();
});

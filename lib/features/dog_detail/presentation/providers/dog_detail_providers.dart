import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_providers.dart';
import '../../data/dog_detail_repository.dart';
import '../../domain/dog_relationship.dart';
import '../../domain/dog_walk_history.dart';

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

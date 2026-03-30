import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/overview_repository.dart';
import '../../domain/dog_walk_summary.dart';

/// Provides the repository instance. Swap to ApiOverviewRepository when ready.
final overviewRepositoryProvider = Provider<OverviewRepository>((ref) {
  return MockOverviewRepository();
});

/// Fetches and caches the dog walk summaries.
final dogWalkSummariesProvider = FutureProvider<List<DogWalkSummary>>((ref) {
  final repository = ref.watch(overviewRepositoryProvider);
  return repository.getDogWalkSummaries();
});

/// Derived stats for the summary cards.
final overviewStatsProvider = Provider<AsyncValue<OverviewStats>>((ref) {
  return ref.watch(dogWalkSummariesProvider).whenData((summaries) {
    return OverviewStats(
      totalDogs: summaries.length,
      totalWalksThisWeek: summaries.fold<int>(0, (sum, s) => sum + s.thisWeekWalks),
      dogsNeedingWalks: summaries.where((s) => s.thisWeekWalks == 0).length,
    );
  });
});

class OverviewStats {
  final int totalDogs;
  final int totalWalksThisWeek;
  final int dogsNeedingWalks;

  const OverviewStats({
    required this.totalDogs,
    required this.totalWalksThisWeek,
    required this.dogsNeedingWalks,
  });
}

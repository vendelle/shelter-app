import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_providers.dart';
import '../../data/overview_repository.dart';
import '../../domain/dog_walk_summary.dart';

final overviewRepositoryProvider = Provider<OverviewRepository>((ref) {
  return ApiOverviewRepository(ref.watch(apiClientProvider));
});

/// Fetches and caches the dog walk summaries.
final dogWalkSummariesProvider = FutureProvider<List<DogWalkSummary>>((ref) {
  final repository = ref.watch(overviewRepositoryProvider);
  return repository.getDogWalkSummaries();
});

/// Derived stats for the summary cards.
final overviewStatsProvider = Provider<AsyncValue<OverviewStats>>((ref) {
  return ref.watch(dogWalkSummariesProvider).whenData((summaries) {
    final thisWeekDays =
        summaries.fold<int>(0, (sum, s) => sum + s.thisWeekWalks);
    final lastWeekDays =
        summaries.fold<int>(0, (sum, s) => sum + s.lastWeekWalks);
    final goal = summaries.length * 4;
    return OverviewStats(
      totalDogs: summaries.length,
      thisWeekDays: thisWeekDays,
      lastWeekDays: lastWeekDays,
      goal: goal,
    );
  });
});

class OverviewStats {
  final int totalDogs;
  final int thisWeekDays;
  final int lastWeekDays;
  final int goal;

  const OverviewStats({
    required this.totalDogs,
    required this.thisWeekDays,
    required this.lastWeekDays,
    required this.goal,
  });

  int get thisWeekPercent => goal == 0 ? 0 : (thisWeekDays * 100 / goal).round();
  int get lastWeekPercent => goal == 0 ? 0 : (lastWeekDays * 100 / goal).round();
}

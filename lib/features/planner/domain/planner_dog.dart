/// A dog available for assignment in the planner, enriched with walk stats
/// and volunteer familiarity.
class PlannerDog {
  final int id;
  final String name;
  final String kennel;
  final int thisWeekWalks;
  final int lastWeekWalks;
  final DogFamiliarityLevel familiarity;

  const PlannerDog({
    required this.id,
    required this.name,
    required this.kennel,
    required this.thisWeekWalks,
    required this.lastWeekWalks,
    this.familiarity = DogFamiliarityLevel.unknown,
  });

  /// Sort priority: fewer walks = higher priority.
  /// If equal this week, compare last week (fewer = higher priority).
  int comparePriority(PlannerDog other) {
    final cmp = thisWeekWalks.compareTo(other.thisWeekWalks);
    if (cmp != 0) return cmp;
    return lastWeekWalks.compareTo(other.lastWeekWalks);
  }
}

/// Familiarity level between a specific volunteer and a specific dog.
enum DogFamiliarityLevel {
  /// No data — haven't walked together yet
  unknown,

  /// Green: "All good, I walk the dog without issues"
  good,

  /// Yellow: "I have problems, but I'll go out if necessary"
  difficult,

  /// Red: "No chance"
  never,
}

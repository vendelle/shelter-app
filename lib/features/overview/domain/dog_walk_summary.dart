class DogWalkSummary {
  final int dogId;
  final String dogName;
  final String kennel;
  final int thisWeekWalks;
  final int lastWeekWalks;

  const DogWalkSummary({
    required this.dogId,
    required this.dogName,
    required this.kennel,
    required this.thisWeekWalks,
    required this.lastWeekWalks,
  });

  factory DogWalkSummary.fromJson(Map<String, dynamic> json) {
    return DogWalkSummary(
      dogId: json['dog_id'] as int,
      dogName: json['dog_name'] as String,
      kennel: json['kennel'] as String? ?? '',
      thisWeekWalks: int.parse(json['this_week_walks'].toString()),
      lastWeekWalks: int.parse(json['last_week_walks'].toString()),
    );
  }

  /// How urgent it is for this dog to get a walk.
  /// Goal: 4 walk days per week.
  /// 0 days = urgent, 1-3 = moderate, 4+ = good.
  WalkUrgency get urgency {
    if (thisWeekWalks <= 1) return WalkUrgency.urgent;
    if (thisWeekWalks < 4) return WalkUrgency.moderate;
    return WalkUrgency.good;
  }

  /// Difference compared to last week: positive = more walks, negative = fewer.
  int get trend => thisWeekWalks - lastWeekWalks;
}

enum WalkUrgency { urgent, moderate, good }

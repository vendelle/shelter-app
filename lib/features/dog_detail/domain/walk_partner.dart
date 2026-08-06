import 'dog_relationship.dart';

/// A dog that has shared a walk group with another dog.
/// Includes the relationship level (if set) and last shared walk date.
class WalkPartner {
  final int dogId;
  final String dogName;
  final String lastSharedWalk;
  final DogRelationshipLevel? level;
  final String? notes;

  const WalkPartner({
    required this.dogId,
    required this.dogName,
    required this.lastSharedWalk,
    this.level,
    this.notes,
  });

  factory WalkPartner.fromJson(Map<String, dynamic> json) {
    final rawDate = json['last_shared_walk'] as String;
    return WalkPartner(
      dogId: json['dog_id'] as int,
      dogName: json['dog_name'] as String,
      lastSharedWalk: rawDate.contains('T') ? rawDate.substring(0, 10) : rawDate,
      level: json['level'] != null
          ? parseRelationshipLevel(json['level'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  /// Sort priority for relationship strength (lower = stronger bond).
  int get levelSortPriority => switch (level) {
    DogRelationshipLevel.yard => 0,
    DogRelationshipLevel.contactGood => 1,
    DogRelationshipLevel.contactCaution => 2,
    DogRelationshipLevel.parallelGood => 3,
    DogRelationshipLevel.parallelCaution => 4,
    DogRelationshipLevel.incompatible => 5,
    null => 6,
  };
}

import 'package:shelter_app/l10n/app_localizations.dart';

/// Relationship level between two dogs.
enum DogRelationshipLevel {
  /// Yard pair — can share the yard freely
  yard,

  /// Walk close, in contact, no serious fights
  contactGood,

  /// Parallel ok, sometimes contact, needs moderation
  contactCaution,

  /// Parallel walks relaxed, haven't tried contact yet
  parallelGood,

  /// Parallel walks show emotions, but has potential
  parallelCaution,

  /// Don't pair these dogs
  incompatible,
}

DogRelationshipLevel parseRelationshipLevel(String value) {
  return switch (value) {
    'yard' => DogRelationshipLevel.yard,
    'contact_good' => DogRelationshipLevel.contactGood,
    'contact_caution' => DogRelationshipLevel.contactCaution,
    'parallel_good' => DogRelationshipLevel.parallelGood,
    'parallel_caution' => DogRelationshipLevel.parallelCaution,
    'incompatible' => DogRelationshipLevel.incompatible,
    _ => DogRelationshipLevel.incompatible,
  };
}

String relationshipLevelToString(DogRelationshipLevel level) {
  return switch (level) {
    DogRelationshipLevel.yard => 'yard',
    DogRelationshipLevel.contactGood => 'contact_good',
    DogRelationshipLevel.contactCaution => 'contact_caution',
    DogRelationshipLevel.parallelGood => 'parallel_good',
    DogRelationshipLevel.parallelCaution => 'parallel_caution',
    DogRelationshipLevel.incompatible => 'incompatible',
  };
}

String relationshipLevelDisplayName(DogRelationshipLevel level, AppLocalizations l10n) {
  return switch (level) {
    DogRelationshipLevel.yard => l10n.levelYard,
    DogRelationshipLevel.contactGood => l10n.levelContactGood,
    DogRelationshipLevel.contactCaution => l10n.levelContactCaution,
    DogRelationshipLevel.parallelGood => l10n.levelParallelGood,
    DogRelationshipLevel.parallelCaution => l10n.levelParallelCaution,
    DogRelationshipLevel.incompatible => l10n.levelIncompatible,
  };
}

/// A relationship between two dogs.
class DogRelationship {
  final int id;
  final int dogId1;
  final int dogId2;
  final String dogName1;
  final String dogName2;
  final DogRelationshipLevel level;
  final String? notes;

  const DogRelationship({
    required this.id,
    required this.dogId1,
    required this.dogId2,
    required this.dogName1,
    required this.dogName2,
    required this.level,
    this.notes,
  });

  factory DogRelationship.fromJson(Map<String, dynamic> json) {
    return DogRelationship(
      id: json['id'] as int,
      dogId1: json['dog_id_1'] as int,
      dogId2: json['dog_id_2'] as int,
      dogName1: json['dog_name_1'] as String,
      dogName2: json['dog_name_2'] as String,
      level: parseRelationshipLevel(json['level'] as String),
      notes: json['notes'] as String?,
    );
  }

  /// Get the other dog's name given one dog's ID.
  String otherDogName(int myDogId) =>
      myDogId == dogId1 ? dogName2 : dogName1;

  /// Get the other dog's ID given one dog's ID.
  int otherDogId(int myDogId) =>
      myDogId == dogId1 ? dogId2 : dogId1;
}

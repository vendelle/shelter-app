import 'package:flutter/material.dart';

import '../domain/dog_relationship.dart';

/// Each relationship level has a distinct color.
Color relationshipColor(DogRelationshipLevel level) {
  return switch (level) {
    DogRelationshipLevel.yard => const Color(0xFF4CAF50),            // green
    DogRelationshipLevel.contactGood => const Color(0xFFC6A700),     // yellow-green/olive
    DogRelationshipLevel.contactCaution => const Color(0xFFFFB300),  // amber
    DogRelationshipLevel.parallelGood => const Color(0xFF90CAF9),    // light blue
    DogRelationshipLevel.parallelCaution => const Color(0xFF5C6BC0), // indigo/blue
    DogRelationshipLevel.incompatible => const Color(0xFFE53935),    // red
  };
}

/// Text color for a relationship level badge.
Color relationshipTextColor(DogRelationshipLevel level) {
  return switch (level) {
    DogRelationshipLevel.yard => Colors.white,
    DogRelationshipLevel.contactGood => Colors.black87,
    DogRelationshipLevel.contactCaution => Colors.black87,
    DogRelationshipLevel.parallelGood => Colors.black87,
    DogRelationshipLevel.parallelCaution => Colors.white,
    DogRelationshipLevel.incompatible => Colors.white,
  };
}

import 'package:flutter/material.dart';

import '../domain/dog_relationship.dart';

/// Each relationship level has a distinct color.
Color relationshipColor(DogRelationshipLevel level) {
  return switch (level) {
    DogRelationshipLevel.yard => const Color(0xFF388E3C),              // green
    DogRelationshipLevel.contactGood => const Color(0xFF7CB342),       // light green
    DogRelationshipLevel.contactCaution => const Color(0xFFFBC02D),    // yellow
    DogRelationshipLevel.parallelGood => const Color(0xFF42A5F5),      // light blue
    DogRelationshipLevel.parallelCaution => const Color(0xFF1565C0),   // blue
    DogRelationshipLevel.incompatible => const Color(0xFFD32F2F),      // red
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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/dog_detail/domain/dog_relationship.dart';
import 'package:shelter_app/features/dog_detail/presentation/relationship_colors.dart';

void main() {
  group('relationshipColor', () {
    test('returns a distinct color for each level', () {
      final colors = DogRelationshipLevel.values
          .map((l) => relationshipColor(l))
          .toSet();
      expect(colors.length, DogRelationshipLevel.values.length);
    });

    test('yard is green', () {
      expect(
        relationshipColor(DogRelationshipLevel.yard),
        const Color(0xFF388E3C),
      );
    });

    test('incompatible is red', () {
      expect(
        relationshipColor(DogRelationshipLevel.incompatible),
        const Color(0xFFD32F2F),
      );
    });
  });

  group('relationshipTextColor', () {
    test('returns a color for each level', () {
      for (final level in DogRelationshipLevel.values) {
        expect(relationshipTextColor(level), isA<Color>());
      }
    });
  });
}

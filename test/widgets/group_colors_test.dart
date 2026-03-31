import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/planner/presentation/widgets/group_colors.dart';
import 'package:flutter/material.dart';

void main() {
  group('groupColor', () {
    test('returns transparent for null group index', () {
      expect(groupColor(null), Colors.transparent);
    });

    test('returns transparent for group index 0', () {
      expect(groupColor(0), Colors.transparent);
    });

    test('returns transparent for negative group index', () {
      expect(groupColor(-1), Colors.transparent);
    });

    test('returns first color for group 1', () {
      expect(groupColor(1), groupColors[0]);
    });

    test('returns correct color for each group', () {
      for (var i = 1; i <= groupColors.length; i++) {
        expect(groupColor(i), groupColors[i - 1]);
      }
    });

    test('wraps around when group index exceeds palette size', () {
      final paletteSize = groupColors.length;
      expect(groupColor(paletteSize + 1), groupColors[0]);
      expect(groupColor(paletteSize + 2), groupColors[1]);
    });
  });

  group('groupColors', () {
    test('has at least 4 distinct colors', () {
      expect(groupColors.length, greaterThanOrEqualTo(4));
    });

    test('all colors are unique', () {
      final unique = groupColors.toSet();
      expect(unique.length, groupColors.length);
    });
  });
}

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

    test('returns a non-transparent color for group 1 (light)', () {
      expect(groupColor(1, Brightness.light), isNot(Colors.transparent));
    });

    test('returns a non-transparent color for group 1 (dark)', () {
      expect(groupColor(1, Brightness.dark), isNot(Colors.transparent));
    });

    test('light and dark colors differ for same group', () {
      expect(
        groupColor(1, Brightness.light),
        isNot(groupColor(1, Brightness.dark)),
      );
    });

    test('wraps around when group index exceeds palette size', () {
      // Both light and dark palettes have 8 colors
      expect(groupColor(9, Brightness.light), groupColor(1, Brightness.light));
      expect(groupColor(9, Brightness.dark), groupColor(1, Brightness.dark));
    });

    test('defaults to light brightness', () {
      expect(groupColor(1), groupColor(1, Brightness.light));
    });
  });

  group('groupTextColor', () {
    test('returns transparent for null group', () {
      expect(groupTextColor(null, Brightness.light), Colors.transparent);
    });

    test('returns dark text for light mode', () {
      final color = groupTextColor(1, Brightness.light);
      expect(color, isNot(Colors.transparent));
      // Dark text should have low luminance
      expect(color.computeLuminance(), lessThan(0.2));
    });

    test('returns light text for dark mode', () {
      final color = groupTextColor(1, Brightness.dark);
      expect(color, isNot(Colors.transparent));
      // Light text should have high luminance
      expect(color.computeLuminance(), greaterThan(0.5));
    });
  });
}

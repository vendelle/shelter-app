import 'package:flutter/material.dart';

/// Background color for a "dogs walked most often" pill, bucketed by walk
/// count over the tracked window. A single teal intensity ramp (matching
/// the app's Material 3 seed color) so it doesn't compete with the role
/// palette (`roleColor`) or the familiarity palette (`familiarity_dialog`).
Color walkCountColor(BuildContext context, int count) {
  if (count <= 0) return Theme.of(context).colorScheme.surfaceContainerHighest;
  if (count <= 2) return const Color(0xFFB2DFDB); // teal 100
  if (count <= 5) return const Color(0xFF4DB6AC); // teal 300
  if (count <= 10) return const Color(0xFF00897B); // teal 600
  return const Color(0xFF00695C); // teal 800
}

/// Text color for a pill with [walkCountColor] background at the given
/// [count].
Color walkCountTextColor(BuildContext context, int count) {
  if (count <= 0) return Theme.of(context).colorScheme.onSurfaceVariant;
  if (count <= 2) return const Color(0xFF00332E);
  if (count <= 5) return Colors.black87;
  return Colors.white;
}

/// Bucket label shown in the legend, e.g. "0", "1-2", "10+".
String walkCountBucketLabel(int count) {
  if (count <= 0) return '0';
  if (count <= 2) return '1-2';
  if (count <= 5) return '3-5';
  if (count <= 10) return '5-10';
  return '10+';
}

/// The five bucket thresholds, in order, for drawing a legend.
const walkCountBucketSamples = [0, 2, 5, 10, 11];

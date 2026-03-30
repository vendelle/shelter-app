import 'package:flutter/material.dart';

import '../../overview/domain/dog_walk_summary.dart';

/// Returns an urgency color based on how many walks a dog had this week.
Color urgencyColor(WalkUrgency urgency, ColorScheme colorScheme) {
  return switch (urgency) {
    WalkUrgency.urgent => colorScheme.error,
    WalkUrgency.moderate => const Color(0xFFE8A317),
    WalkUrgency.good => const Color(0xFF2A9D8F),
  };
}

/// Returns an icon for the trend arrow.
IconData trendIcon(int trend) {
  if (trend > 0) return Icons.trending_up_rounded;
  if (trend < 0) return Icons.trending_down_rounded;
  return Icons.trending_flat_rounded;
}

/// Returns a color for the trend.
Color trendColor(int trend, ColorScheme colorScheme) {
  if (trend > 0) return const Color(0xFF2A9D8F);
  if (trend < 0) return colorScheme.error;
  return colorScheme.outline;
}

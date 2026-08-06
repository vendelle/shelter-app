import 'package:flutter/material.dart';

/// Background color for a "dogs walked most often" pill, bucketed by walk
/// count over the tracked window.
///
/// A deliberately multi-hue ramp (gold → orange → terracotta → purple)
/// rather than a single-hue intensity scale — muted/pastel so it doesn't
/// compete with the role palette (`roleColor`) or the familiarity palette
/// (`familiarity_dialog`). Each step was checked with the dataviz skill's
/// palette validator run in `--ordinal` mode: lightness decreases
/// monotonically bucket-to-bucket (gaps ≥ 0.06 OKLCH L), the lightest step
/// still clears 2:1 against the app surface so it doesn't wash out, and
/// each fill's paired text color in [walkCountTextColor] clears 4.5:1. The
/// one check it intentionally fails is "single hue" — a multi-hue ramp was
/// the explicit ask here, traded in with the rest of the rigor kept.
Color walkCountColor(BuildContext context, int count) {
  if (count <= 0) return Theme.of(context).colorScheme.surfaceContainerHighest;
  if (count <= 2) return const Color(0xFFD2A62E); // muted gold
  if (count <= 5) return const Color(0xFFCD8347); // muted orange
  if (count <= 10) return const Color(0xFFBC5344); // muted terracotta/red
  return const Color(0xFF764AAE); // muted purple
}

/// Text color for a pill with [walkCountColor] background at the given
/// [count]. Each pairing clears 4.5:1 contrast against its fill.
Color walkCountTextColor(BuildContext context, int count) {
  if (count <= 0) return Theme.of(context).colorScheme.onSurfaceVariant;
  if (count <= 2) return const Color(0xFF4A3500); // dark amber
  if (count <= 5) return const Color(0xFF4A2200); // dark burnt orange
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

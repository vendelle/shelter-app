import 'package:flutter/material.dart';

/// Pastel colors for light mode — matches the Excel palette.
const _lightGroupColors = <Color>[
  Color(0xFFB6D7A8), // green
  Color(0xFFA4C2F4), // blue
  Color(0xFFFFE599), // yellow
  Color(0xFFEA9999), // red/pink
  Color(0xFFD5A6BD), // purple/mauve
  Color(0xFFB4A7D6), // lavender
  Color(0xFFF9CB9C), // orange
  Color(0xFF9FC5E8), // sky blue
];

/// Deeper muted tones for dark mode — same hues, better contrast.
const _darkGroupColors = <Color>[
  Color(0xFF3E6B35), // green
  Color(0xFF3A5F8A), // blue
  Color(0xFF8A7630), // yellow/gold
  Color(0xFF8A3B3B), // red
  Color(0xFF7A4068), // purple/mauve
  Color(0xFF5E4F8A), // lavender
  Color(0xFF8A5A2E), // orange
  Color(0xFF3A6A8A), // sky blue
];

/// Returns the group color appropriate for the current brightness.
/// Group 0 or null = no group (transparent).
Color groupColor(int? groupIndex, [Brightness brightness = Brightness.light]) {
  if (groupIndex == null || groupIndex <= 0) return Colors.transparent;
  final colors = brightness == Brightness.dark ? _darkGroupColors : _lightGroupColors;
  return colors[(groupIndex - 1) % colors.length];
}

/// Returns the appropriate text color for a group background.
Color groupTextColor(int? groupIndex, Brightness brightness) {
  if (groupIndex == null || groupIndex <= 0) return Colors.transparent;
  return brightness == Brightness.dark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A);
}

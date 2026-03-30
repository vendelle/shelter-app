import 'package:flutter/material.dart';

/// Pastel colors used to indicate walk groups (dogs that walk together).
/// Matches the Excel color palette the shelter volunteers are used to.
const groupColors = <Color>[
  Color(0xFFB6D7A8), // green
  Color(0xFFA4C2F4), // blue
  Color(0xFFFFE599), // yellow
  Color(0xFFEA9999), // red/pink
  Color(0xFFD5A6BD), // purple/mauve
  Color(0xFFB4A7D6), // lavender
  Color(0xFFF9CB9C), // orange
  Color(0xFF9FC5E8), // sky blue
];

/// Returns the pastel color for a given group index (1-based).
/// Group 0 or null = no group (transparent).
Color groupColor(int? groupIndex) {
  if (groupIndex == null || groupIndex <= 0) return Colors.transparent;
  return groupColors[(groupIndex - 1) % groupColors.length];
}

import 'package:flutter/material.dart';

import '../../planner/domain/planner_dog.dart';

/// Color for a dog-familiarity level — shared between the familiarity
/// editor (`FamiliarityDialog`) and any other place that shows familiarity
/// as a compact indicator (e.g. the volunteer profile's dog pills).
Color familiarityColor(DogFamiliarityLevel level) {
  return switch (level) {
    DogFamiliarityLevel.good => const Color(0xFF2A9D8F),
    DogFamiliarityLevel.difficult => const Color(0xFFE8A317),
    DogFamiliarityLevel.never => Colors.red,
    DogFamiliarityLevel.unknown => Colors.grey,
  };
}

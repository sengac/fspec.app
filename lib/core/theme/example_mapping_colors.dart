/// Shared Example Mapping color constants.
///
/// These colors follow Example Mapping conventions:
/// - Blue: Rules (business rules)
/// - Green: Examples (concrete scenarios)
/// - Pink/Red: Questions (unanswered questions)
/// - Cyan: Mentions (@references)
library;

import 'package:flutter/material.dart';

/// Example Mapping color palette
abstract final class ExampleMappingColors {
  /// Blue theme for Rules cards
  static const Color rule = Color(0xFF2196F3);

  /// Green theme for Examples cards
  static const Color example = Color(0xFF4CAF50);

  /// Pink/Red theme for Questions cards
  static const Color question = Color(0xFFE91E63);

  /// Cyan for @mention highlighting
  static const Color mention = Color(0xFF00BCD4);
}

/// Feature: spec/features/work-unit-detail-view.feature
///
/// Type badge widget displaying work unit type (Story/Bug/Task).
/// Uses shared WorkUnitTypeTheme for consistent styling.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/work_unit_type_theme.dart';
import '../../../board/data/models/board_data.dart';

/// Badge displaying work unit type with icon
class TypeBadge extends StatelessWidget {
  const TypeBadge({super.key, required this.type});

  final WorkUnitType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeTheme = WorkUnitTypeTheme.forType(type);

    return Container(
      key: typeTheme.badgeKey,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: typeTheme.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: typeTheme.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            typeTheme.icon,
            size: 16,
            color: typeTheme.color,
          ),
          const SizedBox(width: 4),
          Text(
            typeTheme.label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: typeTheme.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

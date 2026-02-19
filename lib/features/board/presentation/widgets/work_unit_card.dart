/// Feature: spec/features/kanban-board-view.feature
///
/// Work unit card widget for the Kanban board.
/// Displays work unit ID, title, type indicator, and story points.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/work_unit_type_theme.dart';
import '../../data/models/board_data.dart';

/// Widget displaying a single work unit card on the Kanban board
///
/// Shows:
/// - Type indicator (colored dot): blue for story, orange for bug, green for task
/// - Work unit ID
/// - Title
/// - Story points with type-specific icon (if estimated)
class WorkUnitCard extends StatelessWidget {
  const WorkUnitCard({
    super.key,
    required this.workUnit,
    this.onTap,
  });

  final WorkUnit workUnit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final typeTheme = WorkUnitTypeTheme.forType(workUnit.type);

    return Card(
      key: const Key('work_unit_card'),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: ID and type indicator
              Row(
                children: [
                  // Work unit ID
                  Text(
                    workUnit.id,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Spacer(),
                  // Type indicator (colored dot)
                  Container(
                    key: typeTheme.indicatorKey,
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: typeTheme.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Title
              Text(
                workUnit.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // Story points (if estimated)
              if (workUnit.estimate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      typeTheme.icon,
                      size: 16,
                      color: colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${workUnit.estimate} pts',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

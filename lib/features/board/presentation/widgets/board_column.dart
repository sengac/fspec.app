/// Feature: spec/features/kanban-board-view.feature
///
/// Board column widget for the Kanban board.
/// Displays a column header with name and count, and a scrollable list of work units.
library;

import 'package:flutter/material.dart';

import '../../data/models/board_data.dart';
import 'work_unit_card.dart';

/// Widget displaying a single column on the Kanban board
///
/// Shows:
/// - Column header with name and work unit count
/// - Vertically scrollable list of work unit cards
class BoardColumn extends StatelessWidget {
  const BoardColumn({
    super.key,
    required this.columnInfo,
    required this.workUnits,
    this.onWorkUnitTap,
  });

  final ColumnInfo columnInfo;
  final List<WorkUnit> workUnits;
  final void Function(WorkUnit)? onWorkUnitTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Column header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Column name
              Text(
                columnInfo.displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              // Work unit count badge
              Container(
                key: Key('column_count_${columnInfo.key}'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${workUnits.length}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Scrollable work unit list
        Expanded(
          child: workUnits.isEmpty
              ? Center(
                  child: Text(
                    'No work units',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                )
              : ListView.builder(
                  key: const Key('column_scroll_view'),
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: workUnits.length,
                  itemBuilder: (context, index) {
                    final workUnit = workUnits[index];
                    return WorkUnitCard(
                      workUnit: workUnit,
                      onTap: onWorkUnitTap != null
                          ? () => onWorkUnitTap!(workUnit)
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

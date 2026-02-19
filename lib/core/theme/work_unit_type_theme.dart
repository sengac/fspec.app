/// Feature: spec/features/work-unit-detail-view.feature
/// Feature: spec/features/kanban-board-view.feature
///
/// Shared work unit type theming (colors, icons, labels).
/// Reusable across Kanban board and detail views.
library;

import 'package:flutter/material.dart';

import '../../features/board/data/models/board_data.dart';

/// Work unit type visual properties
class WorkUnitTypeTheme {
  const WorkUnitTypeTheme._({
    required this.label,
    required this.color,
    required this.icon,
    required this.badgeKey,
    required this.indicatorKey,
  });

  /// Display label (e.g., 'Story', 'Bug', 'Task')
  final String label;

  /// Theme color for the type
  final Color color;

  /// Icon representing the type
  final IconData icon;

  /// Key for type badge (detail view)
  final Key badgeKey;

  /// Key for type indicator (board view)
  final Key indicatorKey;

  /// Get theme for a work unit type
  static WorkUnitTypeTheme forType(WorkUnitType type) {
    return switch (type) {
      WorkUnitType.story => _story,
      WorkUnitType.bug => _bug,
      WorkUnitType.task => _task,
    };
  }

  static const _story = WorkUnitTypeTheme._(
    label: 'Story',
    color: Colors.blue,
    icon: Icons.folder_outlined,
    badgeKey: Key('type_badge_story'),
    indicatorKey: Key('type_indicator_story'),
  );

  static const _bug = WorkUnitTypeTheme._(
    label: 'Bug',
    color: Colors.orange,
    icon: Icons.bug_report_outlined,
    badgeKey: Key('type_badge_bug'),
    indicatorKey: Key('type_indicator_bug'),
  );

  static const _task = WorkUnitTypeTheme._(
    label: 'Task',
    color: Colors.green,
    icon: Icons.check_box_outlined,
    badgeKey: Key('type_badge_task'),
    indicatorKey: Key('type_indicator_task'),
  );
}

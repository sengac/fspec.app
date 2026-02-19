/// Feature: spec/features/work-unit-detail-view.feature
///
/// Status badge widget displaying work unit status.
library;

import 'package:flutter/material.dart';

/// Badge displaying work unit status
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Capitalize first letter
    final displayStatus = status.isNotEmpty
        ? '${status[0].toUpperCase()}${status.substring(1)}'
        : status;

    return Container(
      key: const Key('status_badge'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            displayStatus,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

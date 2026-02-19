/// Feature: spec/features/work-unit-detail-view.feature
///
/// Story points badge widget displaying estimated points.
library;

import 'package:flutter/material.dart';

/// Badge displaying story points estimate
class StoryPointsBadge extends StatelessWidget {
  const StoryPointsBadge({super.key, required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      key: const Key('story_points_badge'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bolt,
            size: 16,
            color: colorScheme.outline,
          ),
          const SizedBox(width: 4),
          Text(
            '$points pts',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

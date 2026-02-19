/// Feature: spec/features/work-unit-detail-view.feature
///
/// Empty state widget for sections with no items.
library;

import 'package:flutter/material.dart';

/// Empty state placeholder for Example Mapping sections
class SectionEmptyState extends StatelessWidget {
  const SectionEmptyState({
    super.key,
    required this.message,
    required this.color,
  });

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.1),
            style: BorderStyle.solid,
          ),
        ),
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

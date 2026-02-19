/// Feature: spec/features/work-unit-detail-view.feature
///
/// Example card widget displaying a concrete example.
/// Uses green theming per Example Mapping conventions.
/// Shows type label (HAPPY PATH, EDGE CASE, etc.)
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/example_mapping_colors.dart';
import '../../data/models/work_unit_detail.dart';

/// Green-themed card displaying a concrete example
class ExampleCard extends StatelessWidget {
  const ExampleCard({
    super.key,
    required this.example,
    required this.cardKey,
  });

  final Example example;
  final Key cardKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = ExampleMappingColors.example;

    return Card(
      key: cardKey,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (example.type != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  example.type!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    size: 14,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    example.text,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

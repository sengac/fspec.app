/// Feature: spec/features/work-unit-detail-view.feature
///
/// Rule card widget displaying a business rule.
/// Uses blue theming per Example Mapping conventions.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/example_mapping_colors.dart';
import '../../data/models/work_unit_detail.dart';

/// Blue-themed card displaying a business rule
class RuleCard extends StatelessWidget {
  const RuleCard({
    super.key,
    required this.rule,
    required this.cardKey,
  });

  final Rule rule;
  final Key cardKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = ExampleMappingColors.rule;

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
        child: Row(
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
                Icons.check,
                size: 14,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                rule.text,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Feature: spec/features/work-unit-detail-view.feature
///
/// User story card widget displaying "As a... I want to... so that..." format.
/// Highlights role, action, and benefit keywords.
library;

import 'package:flutter/material.dart';

import '../../data/models/work_unit_detail.dart';

/// Card displaying user story with highlighted keywords
class UserStoryCard extends StatelessWidget {
  const UserStoryCard({
    super.key,
    required this.userStory,
  });

  final UserStory userStory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      key: const Key('user_story_section'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'USER STORY',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
                children: [
                  const TextSpan(text: 'As a '),
                  TextSpan(
                    text: userStory.role,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const TextSpan(text: ',\nI want to '),
                  TextSpan(
                    text: userStory.action,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const TextSpan(text: ',\nso that '),
                  TextSpan(
                    text: userStory.benefit,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

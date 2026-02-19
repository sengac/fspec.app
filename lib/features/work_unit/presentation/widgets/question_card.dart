/// Feature: spec/features/work-unit-detail-view.feature
///
/// Question card widget displaying a question.
/// Uses red/pink theming per Example Mapping conventions.
/// Highlights @mentions in distinct color.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/example_mapping_colors.dart';
import '../../data/models/work_unit_detail.dart';

/// Red-themed card displaying a question with @mention highlighting
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.question,
    required this.cardKey,
    this.mentionHighlightKey,
  });

  final Question question;
  final Key cardKey;
  final Key? mentionHighlightKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = ExampleMappingColors.question;

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
                Icons.help_outline,
                size: 14,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextWithMentions(context, theme),
                  if (question.mentions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: question.mentions.asMap().entries.map((entry) {
                        return Container(
                          key: entry.key == 0 ? mentionHighlightKey : null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ExampleMappingColors.mention.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            entry.value,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: ExampleMappingColors.mention,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextWithMentions(BuildContext context, ThemeData theme) {
    final text = question.text;
    final mentions = question.mentions;

    if (mentions.isEmpty) {
      return Text(
        text,
        style: theme.textTheme.bodyMedium,
      );
    }

    // Build rich text with highlighted mentions
    final spans = <InlineSpan>[];
    var currentIndex = 0;

    for (final mention in mentions) {
      final mentionIndex = text.indexOf(mention, currentIndex);
      if (mentionIndex >= 0) {
        // Add text before mention
        if (mentionIndex > currentIndex) {
          spans.add(TextSpan(
            text: text.substring(currentIndex, mentionIndex),
          ));
        }
        // Add highlighted mention
        spans.add(TextSpan(
          text: mention,
          style: const TextStyle(
            color: ExampleMappingColors.mention,
            fontWeight: FontWeight.bold,
          ),
        ));
        currentIndex = mentionIndex + mention.length;
      }
    }

    // Add remaining text
    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
      ));
    }

    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium,
        children: spans,
      ),
    );
  }
}

/// Feature: spec/features/work-unit-detail-view.feature
///
/// Work unit detail screen displaying full Example Mapping data.
/// Shows header with ID and back navigation, title, type/status badges,
/// user story, rules, examples, questions, and architecture notes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/example_mapping_colors.dart';
import '../../data/models/work_unit_detail.dart';
import '../../data/providers/work_unit_providers.dart';
import '../widgets/section_header.dart';
import '../widgets/section_empty_state.dart';
import '../widgets/type_badge.dart';
import '../widgets/status_badge.dart';
import '../widgets/story_points_badge.dart';
import '../widgets/user_story_card.dart';
import '../widgets/rule_card.dart';
import '../widgets/example_card.dart';
import '../widgets/question_card.dart';

/// Work unit detail screen
class WorkUnitDetailScreen extends ConsumerWidget {
  const WorkUnitDetailScreen({
    super.key,
    required this.instanceId,
    required this.workUnitId,
  });

  final String instanceId;
  final String workUnitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(
      workUnitDetailProvider(instanceId, workUnitId),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('back_button'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(workUnitId),
      ),
      body: detailAsync.when(
        loading: () => const Center(
          key: Key('detail_loading'),
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          key: const Key('detail_error'),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading work unit: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(
                  workUnitDetailProvider(instanceId, workUnitId),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (detail) => _WorkUnitDetailContent(detail: detail),
      ),
    );
  }
}

class _WorkUnitDetailContent extends StatelessWidget {
  const _WorkUnitDetailContent({required this.detail});

  final WorkUnitDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filter out deleted items
    final activeRules = detail.rules.where((r) => !r.deleted).toList();
    final activeExamples = detail.examples.where((e) => !e.deleted).toList();
    final activeQuestions = detail.questions.where((q) => !q.deleted).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              detail.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Type badge, status badge, story points row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TypeBadge(type: detail.type),
                StatusBadge(status: detail.status),
                if (detail.estimate != null)
                  StoryPointsBadge(points: detail.estimate!),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // User Story section
          if (detail.userStory != null)
            UserStoryCard(userStory: detail.userStory!),

          const SizedBox(height: 8),

          // Rules section
          SectionHeader(
            key: const Key('rules_section'),
            title: 'Rules',
            count: activeRules.length,
            color: ExampleMappingColors.rule,
            countBadgeKey: const Key('rules_count_badge'),
          ),
          if (activeRules.isEmpty)
            SectionEmptyState(
              key: const Key('rules_empty_state'),
              message: 'No rules defined yet',
              color: ExampleMappingColors.rule,
            )
          else
            ...activeRules.asMap().entries.map((entry) => RuleCard(
                  rule: entry.value,
                  cardKey: Key('rule_card_${entry.key}'),
                )),

          const SizedBox(height: 16),

          // Examples section
          SectionHeader(
            key: const Key('examples_section'),
            title: 'Examples',
            count: activeExamples.length,
            color: ExampleMappingColors.example,
            countBadgeKey: const Key('examples_count_badge'),
          ),
          if (activeExamples.isEmpty)
            SectionEmptyState(
              key: const Key('examples_empty_state'),
              message: 'No examples defined yet',
              color: ExampleMappingColors.example,
            )
          else
            ...activeExamples.asMap().entries.map((entry) => ExampleCard(
                  example: entry.value,
                  cardKey: Key('example_card_${entry.key}'),
                )),

          const SizedBox(height: 16),

          // Questions section
          SectionHeader(
            key: const Key('questions_section'),
            title: 'Questions',
            count: activeQuestions.length,
            color: ExampleMappingColors.question,
            countBadgeKey: const Key('questions_count_badge'),
          ),
          if (activeQuestions.isEmpty)
            SectionEmptyState(
              key: const Key('questions_empty_state'),
              message: 'No questions',
              color: ExampleMappingColors.question,
            )
          else
            ...activeQuestions.asMap().entries.map((entry) => QuestionCard(
                  question: entry.value,
                  cardKey: Key('question_card_${entry.key}'),
                  mentionHighlightKey:
                      entry.key == 0 ? const Key('mention_highlight_0') : null,
                )),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

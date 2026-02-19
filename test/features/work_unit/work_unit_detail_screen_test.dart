/// Feature: spec/features/work-unit-detail-view.feature
///
/// Tests for Work Unit Detail screen.
/// Validates header, status row, user story, rules, examples,
/// questions, architecture notes display, and navigation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fspec_mobile/features/work_unit/data/models/work_unit_detail.dart';
import 'package:fspec_mobile/features/work_unit/data/providers/work_unit_providers.dart';
import 'package:fspec_mobile/features/work_unit/presentation/screens/work_unit_detail_screen.dart';
import 'package:fspec_mobile/features/board/data/models/board_data.dart';
import 'package:fspec_mobile/features/connection/data/providers/connection_providers.dart';
import 'package:fspec_mobile/features/connection/data/services/relay_connection_service.dart';
import 'package:go_router/go_router.dart';

import '../../fixtures/work_unit_detail_fixtures.dart';
import '../../fixtures/in_memory_connection_repository.dart';
import '../../fixtures/fake_relay_connection_service.dart';

/// Recursively search TextSpan for text content
bool _textSpanContains(TextSpan span, String text) {
  if (span.text?.contains(text) == true) return true;
  if (span.children != null) {
    for (final child in span.children!) {
      if (child is TextSpan && _textSpanContains(child, text)) {
        return true;
      }
    }
  }
  return false;
}

/// Helper to find text within RichText widgets
Finder findRichTextContaining(String text) {
  return find.byWidgetPredicate((widget) {
    if (widget is RichText) {
      final textSpan = widget.text;
      if (textSpan is TextSpan) {
        return _textSpanContains(textSpan, text);
      }
    }
    return false;
  });
}

void main() {
  late InMemoryConnectionRepository repository;
  late FakeRelayConnectionService fakeService;

  setUp(() {
    repository = InMemoryConnectionRepository();
    fakeService = FakeRelayConnectionService(repository);
  });

  Widget createTestWidget({
    required String instanceId,
    required String workUnitId,
    WorkUnitDetail? initialDetailData,
    bool isLoading = false,
    String? errorMessage,
    bool simulateConnectionLost = false,
    GoRouter? router,
  }) {
    final testRouter = router ??
        GoRouter(
          initialLocation: '/work-unit/$instanceId/$workUnitId',
          routes: [
            GoRoute(
              path: '/work-unit/:instanceId/:workUnitId',
              builder: (context, state) => WorkUnitDetailScreen(
                instanceId: state.pathParameters['instanceId']!,
                workUnitId: state.pathParameters['workUnitId']!,
              ),
            ),
            GoRoute(
              path: '/board/:instanceId',
              builder: (context, state) => Scaffold(
                key: const Key('board_screen'),
                body: Text('Board: ${state.pathParameters['instanceId']}'),
              ),
            ),
          ],
        );

    return ProviderScope(
      overrides: [
        connectionRepositoryProvider.overrideWithValue(repository),
        relayConnectionServiceProvider.overrideWithValue(fakeService),
        // Override the work unit detail provider with test data
        workUnitDetailProvider(instanceId, workUnitId).overrideWith(() {
          return FakeWorkUnitDetailNotifier(
            initialData: initialDetailData,
            shouldLoad: isLoading,
            errorMessage: errorMessage,
            simulateConnectionLost: simulateConnectionLost,
          );
        }),
      ],
      child: MaterialApp.router(
        routerConfig: testRouter,
      ),
    );
  }

  group('Feature: Work Unit Detail View', () {
    group('Scenario: View work unit with full Example Mapping data', () {
      testWidgets('should display complete work unit detail with all sections',
          (tester) async {
        // @step Given I am connected to a relay instance
        final connection = WorkUnitDetailFixtures.connectedInstance();
        await repository.save(connection);

        // @step And the instance has a work unit "AUTH-001" with:
        //       | field       | value                       |
        //       | title       | Implement Biometric Login   |
        //       | type        | story                       |
        //       | status      | specifying                  |
        //       | estimate    | 5                           |
        //       | rules       | 2                           |
        //       | examples    | 2                           |
        //       | questions   | 1                           |
        final detailData = WorkUnitDetailFixtures.fullWorkUnitDetail();

        // @step When I tap on work unit "AUTH-001" from the Kanban board
        await tester.pumpWidget(createTestWidget(
          instanceId: connection.id,
          workUnitId: 'AUTH-001',
          initialDetailData: detailData,
        ));
        await tester.pumpAndSettle();

        // @step Then I should see the work unit detail view
        expect(find.byType(WorkUnitDetailScreen), findsOneWidget);

        // @step And I should see the header with "AUTH-001" and back navigation
        expect(find.text('AUTH-001'), findsOneWidget);
        expect(find.byKey(const Key('back_button')), findsOneWidget);

        // @step And I should see the title "Implement Biometric Login"
        expect(find.text('Implement Biometric Login'), findsOneWidget);

        // @step And I should see a "Story" type badge
        expect(find.byKey(const Key('type_badge_story')), findsOneWidget);
        expect(find.text('Story'), findsOneWidget);

        // @step And I should see a "Specifying" status badge
        expect(find.byKey(const Key('status_badge')), findsOneWidget);
        expect(find.text('Specifying'), findsOneWidget);

        // @step And I should see "5 pts" story points
        expect(find.text('5 pts'), findsOneWidget);

        // @step And I should see the user story section with highlighted keywords
        expect(find.byKey(const Key('user_story_section')), findsOneWidget);
        expect(findRichTextContaining('mobile user'), findsOneWidget);
        expect(findRichTextContaining('log in using FaceID'), findsOneWidget);

        // @step And I should see the rules section with count badge showing "2"
        expect(find.byKey(const Key('rules_section')), findsOneWidget);
        expect(find.byKey(const Key('rules_count_badge')), findsOneWidget);
        final rulesCountBadge = tester.widget<Text>(
          find.descendant(
            of: find.byKey(const Key('rules_count_badge')),
            matching: find.byType(Text),
          ),
        );
        expect(rulesCountBadge.data, contains('2'));

        // @step And I should see 2 blue-themed rule cards
        expect(find.byKey(const Key('rule_card_0')), findsOneWidget);
        expect(find.byKey(const Key('rule_card_1')), findsOneWidget);

        // @step And I should see the examples section with count badge showing "2"
        expect(find.byKey(const Key('examples_section')), findsOneWidget);
        expect(find.byKey(const Key('examples_count_badge')), findsOneWidget);

        // @step And I should see 2 green-themed example cards with type labels
        expect(find.byKey(const Key('example_card_0')), findsOneWidget);
        expect(find.byKey(const Key('example_card_1')), findsOneWidget);
        expect(find.text('HAPPY PATH'), findsOneWidget);
        expect(find.text('EDGE CASE'), findsOneWidget);

        // @step And I should see the questions section with count badge showing "1"
        expect(find.byKey(const Key('questions_section')), findsOneWidget);
        expect(find.byKey(const Key('questions_count_badge')), findsOneWidget);

        // @step And I should see 1 red-themed question card
        expect(find.byKey(const Key('question_card_0')), findsOneWidget);
      });
    });

    group('Scenario: View work unit without user story', () {
      testWidgets('should not display user story section when absent',
          (tester) async {
        // @step Given I am connected to a relay instance
        final connection = WorkUnitDetailFixtures.connectedInstance();
        await repository.save(connection);

        // @step And the instance has a work unit "TASK-001" without a user story
        final detailData = WorkUnitDetailFixtures.workUnitWithoutUserStory();

        // @step When I navigate to the work unit detail view for "TASK-001"
        await tester.pumpWidget(createTestWidget(
          instanceId: connection.id,
          workUnitId: 'TASK-001',
          initialDetailData: detailData,
        ));
        await tester.pumpAndSettle();

        // @step Then I should see the work unit detail view
        expect(find.byType(WorkUnitDetailScreen), findsOneWidget);

        // @step And I should not see the user story section
        expect(find.byKey(const Key('user_story_section')), findsNothing);
      });
    });

    group('Scenario: View work unit with zero rules', () {
      testWidgets('should display rules section with (0) badge and empty state',
          (tester) async {
        // @step Given I am connected to a relay instance
        final connection = WorkUnitDetailFixtures.connectedInstance();
        await repository.save(connection);

        // @step And the instance has a work unit "NEW-001" with zero rules
        final detailData = WorkUnitDetailFixtures.workUnitWithZeroRules();

        // @step When I navigate to the work unit detail view for "NEW-001"
        await tester.pumpWidget(createTestWidget(
          instanceId: connection.id,
          workUnitId: 'NEW-001',
          initialDetailData: detailData,
        ));
        await tester.pumpAndSettle();

        // @step Then I should see the rules section with count badge showing "0"
        expect(find.byKey(const Key('rules_section')), findsOneWidget);
        final rulesCountBadge = tester.widget<Text>(
          find.descendant(
            of: find.byKey(const Key('rules_count_badge')),
            matching: find.byType(Text),
          ),
        );
        expect(rulesCountBadge.data, contains('0'));

        // @step And I should see an empty state for the rules section
        expect(find.byKey(const Key('rules_empty_state')), findsOneWidget);
      });
    });

    group('Scenario: Question displays @mention highlighting', () {
      testWidgets('should highlight @mention text in question card',
          (tester) async {
        // @step Given I am connected to a relay instance
        final connection = WorkUnitDetailFixtures.connectedInstance();
        await repository.save(connection);

        // @step And the instance has a work unit "AUTH-001" with a question containing "@security-team"
        final detailData = WorkUnitDetailFixtures.workUnitWithMention();

        // @step When I navigate to the work unit detail view for "AUTH-001"
        await tester.pumpWidget(createTestWidget(
          instanceId: connection.id,
          workUnitId: 'AUTH-001',
          initialDetailData: detailData,
        ));
        await tester.pumpAndSettle();

        // @step Then I should see the question text with "@security-team" highlighted in a distinct color
        expect(find.byKey(const Key('question_card_0')), findsOneWidget);
        expect(find.byKey(const Key('mention_highlight_0')), findsOneWidget);
        expect(find.text('@security-team'), findsOneWidget);
      });
    });

    group('Scenario: View bug work unit type', () {
      testWidgets('should display Bug type badge with appropriate styling',
          (tester) async {
        // @step Given I am connected to a relay instance
        final connection = WorkUnitDetailFixtures.connectedInstance();
        await repository.save(connection);

        // @step And the instance has a work unit "BUG-001" of type "bug"
        final detailData = WorkUnitDetailFixtures.bugWorkUnit();

        // @step When I navigate to the work unit detail view for "BUG-001"
        await tester.pumpWidget(createTestWidget(
          instanceId: connection.id,
          workUnitId: 'BUG-001',
          initialDetailData: detailData,
        ));
        await tester.pumpAndSettle();

        // @step Then I should see a "Bug" type badge with appropriate styling
        expect(find.byKey(const Key('type_badge_bug')), findsOneWidget);
        expect(find.text('Bug'), findsOneWidget);
      });
    });

    group('Scenario: View work unit without estimate', () {
      testWidgets('should not display story points badge when absent',
          (tester) async {
        // @step Given I am connected to a relay instance
        final connection = WorkUnitDetailFixtures.connectedInstance();
        await repository.save(connection);

        // @step And the instance has a work unit "DRAFT-001" without an estimate
        final detailData = WorkUnitDetailFixtures.workUnitWithoutEstimate();

        // @step When I navigate to the work unit detail view for "DRAFT-001"
        await tester.pumpWidget(createTestWidget(
          instanceId: connection.id,
          workUnitId: 'DRAFT-001',
          initialDetailData: detailData,
        ));
        await tester.pumpAndSettle();

        // @step Then I should not see the story points badge
        expect(find.textContaining('pts'), findsNothing);
        expect(find.byKey(const Key('story_points_badge')), findsNothing);
      });
    });

    group('Scenario: Navigate back to Kanban board', () {
      testWidgets('should return to board when pressing back arrow',
          (tester) async {
        // @step Given I am viewing the work unit detail for "AUTH-001"
        final connection = WorkUnitDetailFixtures.connectedInstance();
        await repository.save(connection);
        final detailData = WorkUnitDetailFixtures.fullWorkUnitDetail();

        // Create router that starts from board, then navigates to detail
        final navigationRouter = GoRouter(
          initialLocation: '/board/${connection.id}',
          routes: [
            GoRoute(
              path: '/board/:instanceId',
              builder: (context, state) => Scaffold(
                key: const Key('board_screen'),
                body: Center(
                  child: ElevatedButton(
                    key: const Key('go_to_detail'),
                    onPressed: () => context.push(
                      '/work-unit/${connection.id}/AUTH-001',
                    ),
                    child: const Text('Go to Detail'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/work-unit/:instanceId/:workUnitId',
              builder: (context, state) => WorkUnitDetailScreen(
                instanceId: state.pathParameters['instanceId']!,
                workUnitId: state.pathParameters['workUnitId']!,
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              connectionRepositoryProvider.overrideWithValue(repository),
              relayConnectionServiceProvider.overrideWithValue(fakeService),
              workUnitDetailProvider(connection.id, 'AUTH-001').overrideWith(() {
                return FakeWorkUnitDetailNotifier(initialData: detailData);
              }),
            ],
            child: MaterialApp.router(routerConfig: navigationRouter),
          ),
        );
        await tester.pumpAndSettle();

        // Navigate to detail screen
        await tester.tap(find.byKey(const Key('go_to_detail')));
        await tester.pumpAndSettle();

        // Verify we're on the detail screen
        expect(find.byType(WorkUnitDetailScreen), findsOneWidget);

        // @step When I press the back arrow
        await tester.tap(find.byKey(const Key('back_button')));
        await tester.pumpAndSettle();

        // @step Then I should return to the Kanban board view
        expect(find.byKey(const Key('board_screen')), findsOneWidget);
      });
    });
  });
}

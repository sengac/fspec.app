/// Feature: spec/features/kanban-board-view.feature
///
/// Shared test fixtures for Kanban Board-related tests.
/// Provides reusable BoardData, WorkUnit, and Connection objects
/// for various board scenarios.
library;

import 'dart:async';

import 'package:fspec_mobile/features/board/data/models/board_data.dart';
import 'package:fspec_mobile/features/board/data/providers/board_providers.dart';
import 'package:fspec_mobile/features/connection/domain/models/connection.dart';

import 'connection_fixtures.dart';

/// Standard test fixtures for Kanban Board scenarios
class BoardFixtures {
  /// Connection that is online and ready for board fetch
  /// Delegates to shared ConnectionFixtures.connectedInstance
  static Connection connectedInstance({
    String name = 'MacBook Pro - fspec-mobile',
    String projectName = 'fspec-mobile',
    String channelId = 'channel-board',
  }) {
    return ConnectionFixtures.connectedInstance(
      name: name,
      projectName: projectName,
      channelId: channelId,
    );
  }

  /// Story work unit with estimate
  /// Used for: Story card display tests (blue dot)
  static WorkUnit storyWorkUnit({
    String id = 'AUTH-001',
    String title = 'Implement OAuth2 login flow with refresh tokens',
    int estimate = 5,
  }) {
    return WorkUnit(
      id: id,
      title: title,
      type: WorkUnitType.story,
      estimate: estimate,
    );
  }

  /// Bug work unit with estimate
  /// Used for: Bug card display tests (orange dot)
  static WorkUnit bugWorkUnit({
    String id = 'UI-103',
    String title = 'Fix dark mode contrast issues in settings panel',
    int estimate = 3,
  }) {
    return WorkUnit(
      id: id,
      title: title,
      type: WorkUnitType.bug,
      estimate: estimate,
    );
  }

  /// Task work unit with estimate
  /// Used for: Task card display tests (green dot)
  static WorkUnit taskWorkUnit({
    String id = 'API-204',
    String title = 'Update user profile endpoint schema for v2',
    int estimate = 2,
  }) {
    return WorkUnit(
      id: id,
      title: title,
      type: WorkUnitType.task,
      estimate: estimate,
    );
  }

  /// Work unit without estimate
  /// Used for: No-estimate display tests
  static WorkUnit workUnitWithoutEstimate({
    String id = 'SETUP-001',
    String title = 'Initial setup',
    WorkUnitType type = WorkUnitType.story,
  }) {
    return WorkUnit(
      id: id,
      title: title,
      type: type,
      estimate: null,
    );
  }

  /// Board with multiple work units in backlog
  /// Used for: Basic board display and navigation tests
  static BoardData boardWithBacklogItems({int count = 12}) {
    final backlogItems = List.generate(
      count,
      (i) => WorkUnit(
        id: 'ITEM-${i + 1}'.padLeft(8, '0'),
        title: 'Work item ${i + 1}',
        type: i % 3 == 0
            ? WorkUnitType.story
            : (i % 3 == 1 ? WorkUnitType.bug : WorkUnitType.task),
        estimate: (i % 4) + 1,
      ),
    );

    return BoardData(
      success: true,
      columns: BoardColumns(
        backlog: backlogItems,
        specifying: [],
        testing: [],
        implementing: [],
        validating: [],
        done: [],
        blocked: [],
      ),
      summary: '0 points in progress, 0 points completed',
    );
  }

  /// Board with work units spread across columns
  /// Used for: Multi-column navigation tests
  static BoardData boardWithMultipleColumns() {
    return BoardData(
      success: true,
      columns: BoardColumns(
        backlog: [
          storyWorkUnit(),
          bugWorkUnit(),
          taskWorkUnit(),
        ],
        specifying: [
          WorkUnit(
            id: 'SPEC-001',
            title: 'Design API schema',
            type: WorkUnitType.story,
            estimate: 3,
          ),
        ],
        testing: [
          WorkUnit(
            id: 'TEST-001',
            title: 'Write integration tests',
            type: WorkUnitType.task,
            estimate: 2,
          ),
        ],
        implementing: [
          WorkUnit(
            id: 'IMPL-001',
            title: 'Build dashboard widget',
            type: WorkUnitType.story,
            estimate: 5,
          ),
        ],
        validating: [],
        done: [
          WorkUnit(
            id: 'DONE-001',
            title: 'Setup project structure',
            type: WorkUnitType.task,
            estimate: 1,
          ),
          WorkUnit(
            id: 'DONE-002',
            title: 'Configure CI/CD',
            type: WorkUnitType.task,
            estimate: 2,
          ),
        ],
        blocked: [
          WorkUnit(
            id: 'BLOCK-001',
            title: 'Waiting for API docs',
            type: WorkUnitType.story,
            estimate: 8,
          ),
        ],
      ),
      summary: '10 points in progress, 3 points completed',
    );
  }

  /// Board with many items in one column for scroll testing
  static BoardData boardWithManyItems({int count = 15}) {
    final manyItems = List.generate(
      count,
      (i) => WorkUnit(
        id: 'SCROLL-${(i + 1).toString().padLeft(3, '0')}',
        title: 'Scrollable work item number ${i + 1}',
        type: WorkUnitType.story,
        estimate: 3,
      ),
    );

    return BoardData(
      success: true,
      columns: BoardColumns(
        backlog: manyItems,
      ),
      summary: '${count * 3} points in backlog',
    );
  }

  /// Empty board
  /// Used for: Empty state tests
  static BoardData emptyBoard() {
    return const BoardData(
      success: true,
      columns: BoardColumns(),
      summary: '0 points in progress, 0 points completed',
    );
  }

  /// Board JSON response as Map (simulates relay response)
  static Map<String, dynamic> boardJsonResponse() {
    return {
      'success': true,
      'columns': {
        'backlog': [
          {
            'id': 'AUTH-001',
            'title': 'Implement OAuth2 login flow with refresh tokens',
            'type': 'story',
            'estimate': 5,
          },
          {
            'id': 'UI-103',
            'title': 'Fix dark mode contrast issues in settings panel',
            'type': 'bug',
            'estimate': 3,
          },
          {
            'id': 'API-204',
            'title': 'Update user profile endpoint schema for v2',
            'type': 'task',
            'estimate': 2,
          },
        ],
        'specifying': [],
        'testing': [],
        'implementing': [],
        'validating': [],
        'done': [],
        'blocked': [],
      },
      'summary': '0 points in progress, 0 points completed',
    };
  }
}

/// Fake BoardNotifier for testing
///
/// Allows control over loading/error/data states without actual
/// WebSocket communication. Use to simulate various board states.
class FakeBoardNotifier extends BoardNotifier {
  final BoardData? initialData;
  final bool shouldLoad;
  final String? errorMessage;
  final bool simulateConnectionLost;

  bool _isConnectionLost = false;

  FakeBoardNotifier({
    this.initialData,
    this.shouldLoad = false,
    this.errorMessage,
    this.simulateConnectionLost = false,
  }) {
    _isConnectionLost = simulateConnectionLost;
  }

  @override
  bool get isConnectionLost => _isConnectionLost;

  @override
  Future<BoardData> build(String instanceId) async {
    if (shouldLoad) {
      final completer = Completer<BoardData>();
      return completer.future;
    }
    if (errorMessage != null) {
      throw Exception(errorMessage);
    }
    return initialData ?? const BoardData(success: true, columns: BoardColumns());
  }

  @override
  Future<void> refresh() async {}

  @override
  Future<void> retry() async {
    _isConnectionLost = false;
  }
}

/// Feature: spec/features/work-unit-detail-view.feature
///
/// Shared test fixtures for Work Unit Detail-related tests.
/// Provides reusable WorkUnitDetail, UserStory, Rule, Example, and Question objects
/// for various detail view scenarios.
library;

import 'dart:async';

import 'package:fspec_mobile/features/work_unit/data/models/work_unit_detail.dart';
import 'package:fspec_mobile/features/work_unit/data/providers/work_unit_providers.dart';
import 'package:fspec_mobile/features/board/data/models/board_data.dart';
import 'package:fspec_mobile/features/connection/domain/models/connection.dart';

import 'connection_fixtures.dart';

/// Standard test fixtures for Work Unit Detail scenarios
class WorkUnitDetailFixtures {
  /// Connection that is online and ready for detail fetch
  /// Delegates to shared ConnectionFixtures.connectedInstance
  static Connection connectedInstance({
    String name = 'MacBook Pro - fspec-mobile',
    String projectName = 'fspec-mobile',
    String channelId = 'channel-detail',
  }) {
    return ConnectionFixtures.connectedInstance(
      name: name,
      projectName: projectName,
      channelId: channelId,
    );
  }

  /// Full work unit detail with all Example Mapping data
  /// Used for: Happy path scenario - complete detail display
  static WorkUnitDetail fullWorkUnitDetail({
    String id = 'AUTH-001',
    String title = 'Implement Biometric Login',
    WorkUnitType type = WorkUnitType.story,
    String status = 'specifying',
    int estimate = 5,
  }) {
    return WorkUnitDetail(
      id: id,
      title: title,
      type: type,
      status: status,
      estimate: estimate,
      userStory: const UserStory(
        role: 'mobile user',
        action: 'log in using FaceID',
        benefit: 'I can access my account quickly without typing a password',
      ),
      rules: const [
        Rule(
          index: 0,
          text: 'Must fallback to PIN or Password if FaceID biometrics fail or are cancelled by user.',
        ),
        Rule(
          index: 1,
          text: 'Biometrics only enabled after initial successful password login on the device.',
        ),
      ],
      examples: const [
        Example(
          index: 0,
          text: 'User enables FaceID in settings, next app launch prompts for FaceID immediately.',
          type: 'HAPPY PATH',
        ),
        Example(
          index: 1,
          text: 'User changes system face data -> App detects change and forces password login once.',
          type: 'EDGE CASE',
        ),
      ],
      questions: const [
        Question(
          index: 0,
          text: 'What is the max retry count before we force PIN entry? Is it system default or custom?',
          mentions: ['@security-team'],
        ),
      ],
      architectureNotes: const [
        'Uses LocalAuthentication framework for biometric APIs',
        'Stores biometric enrollment state in secure enclave',
      ],
    );
  }

  /// Work unit without a user story
  /// Used for: Empty user story section test
  static WorkUnitDetail workUnitWithoutUserStory({
    String id = 'TASK-001',
    String title = 'Setup CI Pipeline',
    WorkUnitType type = WorkUnitType.task,
    String status = 'backlog',
  }) {
    return WorkUnitDetail(
      id: id,
      title: title,
      type: type,
      status: status,
      userStory: null,
      rules: const [],
      examples: const [],
      questions: const [],
      architectureNotes: const [],
    );
  }

  /// Work unit with zero rules
  /// Used for: Empty rules section test
  static WorkUnitDetail workUnitWithZeroRules({
    String id = 'NEW-001',
    String title = 'New Feature',
    WorkUnitType type = WorkUnitType.story,
    String status = 'specifying',
  }) {
    return WorkUnitDetail(
      id: id,
      title: title,
      type: type,
      status: status,
      userStory: const UserStory(
        role: 'user',
        action: 'do something',
        benefit: 'get value',
      ),
      rules: const [],
      examples: const [
        Example(index: 0, text: 'Example 1', type: 'HAPPY PATH'),
      ],
      questions: const [],
      architectureNotes: const [],
    );
  }

  /// Work unit with @mention in question
  /// Used for: @mention highlighting test
  static WorkUnitDetail workUnitWithMention({
    String id = 'AUTH-001',
    String title = 'Auth Feature',
  }) {
    return WorkUnitDetail(
      id: id,
      title: title,
      type: WorkUnitType.story,
      status: 'specifying',
      userStory: null,
      rules: const [],
      examples: const [],
      questions: const [
        Question(
          index: 0,
          text: 'Need clarification on security requirements @security-team',
          mentions: ['@security-team'],
        ),
      ],
      architectureNotes: const [],
    );
  }

  /// Bug work unit
  /// Used for: Bug type badge display test
  static WorkUnitDetail bugWorkUnit({
    String id = 'BUG-001',
    String title = 'Fix Login Crash',
    String status = 'implementing',
  }) {
    return WorkUnitDetail(
      id: id,
      title: title,
      type: WorkUnitType.bug,
      status: status,
      estimate: 3,
      userStory: null,
      rules: const [],
      examples: const [],
      questions: const [],
      architectureNotes: const [],
    );
  }

  /// Work unit without estimate
  /// Used for: No estimate badge test
  static WorkUnitDetail workUnitWithoutEstimate({
    String id = 'DRAFT-001',
    String title = 'Draft Feature',
    WorkUnitType type = WorkUnitType.story,
    String status = 'backlog',
  }) {
    return WorkUnitDetail(
      id: id,
      title: title,
      type: type,
      status: status,
      estimate: null,
      userStory: null,
      rules: const [],
      examples: const [],
      questions: const [],
      architectureNotes: const [],
    );
  }

  /// Work unit detail JSON response as Map (simulates relay response)
  static Map<String, dynamic> detailJsonResponse() {
    return {
      'id': 'AUTH-001',
      'title': 'Implement Biometric Login',
      'type': 'story',
      'status': 'specifying',
      'estimate': 5,
      'userStory': {
        'role': 'mobile user',
        'action': 'log in using FaceID',
        'benefit': 'I can access my account quickly without typing a password',
      },
      'rules': [
        {
          'index': 0,
          'text': 'Must fallback to PIN or Password if FaceID biometrics fail.',
          'deleted': false,
        },
        {
          'index': 1,
          'text': 'Biometrics only enabled after initial successful password login.',
          'deleted': false,
        },
      ],
      'examples': [
        {
          'index': 0,
          'text': 'User enables FaceID in settings.',
          'type': 'HAPPY PATH',
          'deleted': false,
        },
        {
          'index': 1,
          'text': 'User changes system face data.',
          'type': 'EDGE CASE',
          'deleted': false,
        },
      ],
      'questions': [
        {
          'index': 0,
          'text': 'What is the max retry count? @security-team',
          'answer': null,
          'deleted': false,
        },
      ],
      'architectureNotes': [
        'Uses LocalAuthentication framework',
      ],
    };
  }
}

/// Fake WorkUnitDetailNotifier for testing
///
/// Allows control over loading/error/data states without actual
/// WebSocket communication. Use to simulate various detail states.
class FakeWorkUnitDetailNotifier extends WorkUnitDetailNotifier {
  final WorkUnitDetail? initialData;
  final bool shouldLoad;
  final String? errorMessage;
  final bool simulateConnectionLost;

  bool _isConnectionLost = false;

  FakeWorkUnitDetailNotifier({
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
  Future<WorkUnitDetail> build(String instanceId, String workUnitId) async {
    if (shouldLoad) {
      final completer = Completer<WorkUnitDetail>();
      return completer.future;
    }
    if (errorMessage != null) {
      throw Exception(errorMessage);
    }
    return initialData ?? WorkUnitDetailFixtures.fullWorkUnitDetail();
  }

  @override
  Future<void> refresh() async {}

  @override
  Future<void> retry() async {
    _isConnectionLost = false;
  }
}

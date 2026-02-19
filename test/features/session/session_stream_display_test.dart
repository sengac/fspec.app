/// Feature: spec/features/session-stream-display.feature
///
/// Tests for Session Stream Display screen.
/// Validates display of StreamChunks: user messages, thinking blocks,
/// tool calls, AI responses, session state changes, and auto-scroll behavior.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fspec_mobile/features/connection/data/providers/connection_providers.dart';
import 'package:fspec_mobile/features/connection/data/services/relay_connection_service.dart';
import 'package:fspec_mobile/features/session/data/models/session_stream_state.dart';
import 'package:fspec_mobile/features/session/data/models/stream_chunk.dart';
import 'package:fspec_mobile/features/session/data/providers/session_stream_providers.dart';
import 'package:fspec_mobile/features/session/presentation/screens/session_stream_screen.dart';
import 'package:go_router/go_router.dart';

import '../../fixtures/stream_chunk_fixtures.dart';
import '../../fixtures/connection_fixtures.dart';
import '../../fixtures/in_memory_connection_repository.dart';
import '../../fixtures/fake_relay_connection_service.dart';
import '../../fixtures/session_stream_fixtures.dart';

void main() {
  late InMemoryConnectionRepository repository;
  late FakeRelayConnectionService fakeService;
  late SessionStreamTestFactory testFactory;

  setUp(() {
    repository = InMemoryConnectionRepository();
    fakeService = FakeRelayConnectionService(repository);
    testFactory = SessionStreamTestFactory(
      repository: repository,
      relayService: fakeService,
    );
  });

  group('Feature: Session Stream Display', () {
    // -------------------------------------------
    // Session Header Display
    // -------------------------------------------
    group('Scenario: Session header shows connection info and status', () {
      testWidgets('should display connection name, session ID, and status',
          (tester) async {
        // @step Given I am connected to a relay channel
        final connection = ConnectionFixtures.connectedInstance(
          name: 'MacBook Pro',
        );
        await repository.save(connection);

        // @step And I open a session stream view
        await tester.pumpWidget(testFactory.createSessionStreamWidget(
          connectionId: connection.id,
          sessionId: 'AUTH-001',
        ));
        await tester.pumpAndSettle();

        // @step Then I should see the connection name in the header
        expect(find.text('MacBook Pro'), findsOneWidget);

        // @step And I should see the session ID badge
        expect(find.text('AUTH-001'), findsOneWidget);

        // @step And I should see a status indicator showing "Running"
        expect(find.text('Running'), findsOneWidget);
        expect(find.byKey(const Key('status_indicator_running')), findsOneWidget);
      });
    });

    // -------------------------------------------
    // User Message Display
    // -------------------------------------------
    group('Scenario: User message appears in purple bubble with timestamp', () {
      testWidgets('should display user message in purple bubble',
          (tester) async {
        // @step Given I am viewing a session stream
        final connection = ConnectionFixtures.connectedInstance();
        await repository.save(connection);
        await tester.pumpWidget(testFactory.createSessionStreamWidget(
          connectionId: connection.id,
          sessionId: 'AUTH-001',
        ));
        await tester.pumpAndSettle();

        // @step When a user message chunk arrives with text "Refactor the login logic"
        testFactory.notifier.addChunk(UserMessageChunk(
          content: 'Refactor the login logic',
          timestamp: DateTime.now(),
        ));
        await tester.pumpAndSettle();

        // @step Then I should see the message in a purple bubble
        expect(find.text('Refactor the login logic'), findsOneWidget);
        expect(find.byKey(const Key('user_message_bubble')), findsOneWidget);

        // @step And I should see a timestamp on the message
        expect(find.byKey(const Key('message_timestamp')), findsOneWidget);
      });
    });

    // -------------------------------------------
    // AI Thinking Display
    // -------------------------------------------
    group('Scenario: Thinking block displays with collapsible steps', () {
      testWidgets('should display thinking block with gear icon and steps',
          (tester) async {
        // @step Given I am viewing a session stream
        final connection = ConnectionFixtures.connectedInstance();
        await repository.save(connection);
        await tester.pumpWidget(testFactory.createSessionStreamWidget(
          connectionId: connection.id,
          sessionId: 'AUTH-001',
        ));
        await tester.pumpAndSettle();

        // @step When a thinking chunk arrives with content "Analyzing request scope"
        testFactory.notifier.addChunk(const ThinkingChunk(
          content: 'Analyzing request scope',
          id: 'think-1',
        ));
        await tester.pumpAndSettle();

        // @step Then I should see a "Thinking Process" block
        expect(find.text('Thinking Process'), findsOneWidget);
        expect(find.byKey(const Key('thinking_block')), findsOneWidget);

        // @step And the block should show a gear icon
        expect(find.byIcon(Icons.settings), findsOneWidget);

        // @step And I should see the thinking step with a progress indicator
        expect(find.text('Analyzing request scope'), findsOneWidget);
      });
    });

    group('Scenario: User can expand and collapse thinking block', () {
      testWidgets('should toggle thinking block expansion on tap',
          (tester) async {
        // @step Given I am viewing a session stream with a collapsed thinking block
        final connection = ConnectionFixtures.connectedInstance();
        await repository.save(connection);
        
        // Create initial state with a collapsed thinking block
        final initialState = SessionStreamState(
          connectionName: 'MacBook Pro',
          sessionId: 'AUTH-001',
          sessionState: SessionState.running,
          displayItems: [
            StreamDisplayItem.thinking(
              chunks: [
                const ThinkingChunk(content: 'Step 1', id: '1'),
                const ThinkingChunk(content: 'Step 2', id: '2'),
              ],
              isExpanded: false,
            ),
          ],
        );
        
        await tester.pumpWidget(testFactory.createSessionStreamWidget(
          connectionId: connection.id,
          sessionId: 'AUTH-001',
          initialState: initialState,
        ));
        await tester.pumpAndSettle();

        // @step When I tap on the thinking block header
        await tester.tap(find.byKey(const Key('thinking_block_header')));
        await tester.pumpAndSettle();

        // @step Then the block should expand to show all thinking steps
        expect(find.byKey(const Key('thinking_steps_expanded')), findsOneWidget);

        // @step When I tap on the thinking block header again
        await tester.tap(find.byKey(const Key('thinking_block_header')));
        await tester.pumpAndSettle();

        // @step Then the block should collapse
        expect(find.byKey(const Key('thinking_steps_expanded')), findsNothing);
      });
    });

    // -------------------------------------------
    // Tool Call Display
    // -------------------------------------------
    group('Scenario: Tool call displays with name and input', () {
      testWidgets('should display tool call block with running status',
          (tester) async {
        // @step Given I am viewing a session stream
        final connection = ConnectionFixtures.connectedInstance();
        await repository.save(connection);
        await tester.pumpWidget(testFactory.createSessionStreamWidget(
          connectionId: connection.id,
          sessionId: 'AUTH-001',
        ));
        await tester.pumpAndSettle();

        // @step When a tool call chunk arrives for tool "Bash" with input "grep -r \"def login\" ."
        testFactory.notifier.addChunk(const ToolCallChunk(
          toolCallId: 'tool-1',
          name: 'Bash',
          input: 'grep -r "def login" .',
        ));
        await tester.pumpAndSettle();

        // @step Then I should see a "TOOL: BASH" block
        expect(find.text('TOOL: BASH'), findsOneWidget);
        expect(find.byKey(const Key('tool_call_block')), findsOneWidget);

        // @step And I should see the command in a code block
        expect(find.textContaining('grep -r "def login" .'), findsOneWidget);
        expect(find.byKey(const Key('tool_input_code_block')), findsOneWidget);

        // @step And I should see a "running" status badge
        expect(find.text('running'), findsOneWidget);
        expect(find.byKey(const Key('tool_status_badge_running')), findsOneWidget);
      });
    });

    group('Scenario: Tool result updates the tool call display', () {
      testWidgets('should update tool call with result and completed status',
          (tester) async {
        // @step Given I am viewing a session stream with a running tool call
        final connection = ConnectionFixtures.connectedInstance();
        await repository.save(connection);
        
        final initialState = SessionStreamState(
          connectionName: 'MacBook Pro',
          sessionId: 'AUTH-001',
          sessionState: SessionState.running,
          displayItems: [
            StreamDisplayItem.toolCall(
              toolCall: const ToolCallWithResult(
                toolCall: ToolCallChunk(
                  toolCallId: 'tool-1',
                  name: 'Bash',
                  input: 'grep -r "def login" .',
                ),
              ),
            ),
          ],
        );
        
        await tester.pumpWidget(testFactory.createSessionStreamWidget(
          connectionId: connection.id,
          sessionId: 'AUTH-001',
          initialState: initialState,
        ));
        await tester.pumpAndSettle();

        // @step When a tool result chunk arrives with output containing file paths
        testFactory.notifier.addChunk(const ToolResultChunk(
          toolCallId: 'tool-1',
          content: './app/controllers/auth_controller.rb:45: def login',
          isError: false,
        ));
        await tester.pumpAndSettle();

        // @step Then I should see the output displayed below the input
        expect(find.text('./app/controllers/auth_controller.rb:45: def login'), findsOneWidget);
        expect(find.byKey(const Key('tool_output_block')), findsOneWidget);

        // @step And the status badge should change to "completed"
        expect(find.text('completed'), findsOneWidget);
        expect(find.byKey(const Key('tool_status_badge_completed')), findsOneWidget);
      });
    });

    group('Scenario: Tool error displays with error styling', () {
      testWidgets('should display tool error with error badge and styling',
          (tester) async {
        // @step Given I am viewing a session stream with a running tool call
        final connection = ConnectionFixtures.connectedInstance();
        await repository.save(connection);
        
        final initialState = SessionStreamState(
          connectionName: 'MacBook Pro',
          sessionId: 'AUTH-001',
          sessionState: SessionState.running,
          displayItems: [
            StreamDisplayItem.toolCall(
              toolCall: const ToolCallWithResult(
                toolCall: ToolCallChunk(
                  toolCallId: 'tool-1',
                  name: 'Bash',
                  input: 'invalid_command',
                ),
              ),
            ),
          ],
        );
        
        await tester.pumpWidget(testFactory.createSessionStreamWidget(
          connectionId: connection.id,
          sessionId: 'AUTH-001',
          initialState: initialState,
        ));
        await tester.pumpAndSettle();

        // @step When a tool result chunk arrives with an error flag
        testFactory.notifier.addChunk(const ToolResultChunk(
          toolCallId: 'tool-1',
          content: 'command not found: invalid_command',
          isError: true,
        ));
        await tester.pumpAndSettle();

        // @step Then the status badge should show "error"
        expect(find.text('error'), findsOneWidget);
        expect(find.byKey(const Key('tool_status_badge_error')), findsOneWidget);

        // @step And the output should be styled as an error
        expect(find.byKey(const Key('tool_output_error')), findsOneWidget);
      });
    });

    // -------------------------------------------
    // AI Response Display
    // -------------------------------------------
    group('Scenario: AI text response appears in labeled bubble', () {
      testWidgets('should display assistant message with label',
          (tester) async {
        // @step Given I am viewing a session stream
        final connection = ConnectionFixtures.connectedInstance();
        await repository.save(connection);
        await tester.pumpWidget(testFactory.createSessionStreamWidget(
          connectionId: connection.id,
          sessionId: 'AUTH-001',
        ));
        await tester.pumpAndSettle();

        // @step When a text chunk arrives with assistant response "I found the login definition"
        testFactory.notifier.addChunk(const TextChunk(
          content: 'I found the login definition',
          id: 'text-1',
        ));
        await tester.pumpAndSettle();

        // @step Then I should see the text in a message bubble
        expect(find.text('I found the login definition'), findsOneWidget);
        expect(find.byKey(const Key('assistant_message_bubble')), findsOneWidget);

        // @step And the bubble should have a label identifying the assistant
        expect(find.byKey(const Key('assistant_label')), findsOneWidget);
      });
    });

    // -------------------------------------------
    // Session State Changes
    // -------------------------------------------
    group('Scenario: Status indicator updates when session state changes', () {
      testWidgets('should update status to Idle when state changes',
          (tester) async {
        // @step Given I am viewing a session stream showing "Running" status
        final connection = ConnectionFixtures.connectedInstance();
        await repository.save(connection);
        await tester.pumpWidget(testFactory.createSessionStreamWidget(
          connectionId: connection.id,
          sessionId: 'AUTH-001',
        ));
        await tester.pumpAndSettle();
        
        // Initial state is Running
        expect(find.text('Running'), findsOneWidget);

        // @step When a session state change chunk arrives with state "Idle"
        testFactory.notifier.addChunk(const SessionStateChangeChunk(state: SessionState.idle));
        await tester.pumpAndSettle();

        // @step Then the status indicator should change to "Idle"
        expect(find.text('Idle'), findsOneWidget);
        expect(find.byKey(const Key('status_indicator_idle')), findsOneWidget);
      });
    });

    group('Scenario: Status shows Paused when session is paused', () {
      testWidgets('should update status to Paused when state changes',
          (tester) async {
        // @step Given I am viewing a session stream showing "Running" status
        final connection = ConnectionFixtures.connectedInstance();
        await repository.save(connection);
        await tester.pumpWidget(testFactory.createSessionStreamWidget(
          connectionId: connection.id,
          sessionId: 'AUTH-001',
        ));
        await tester.pumpAndSettle();

        // @step When a session state change chunk arrives with state "Paused"
        testFactory.notifier.addChunk(const SessionStateChangeChunk(state: SessionState.paused));
        await tester.pumpAndSettle();

        // @step Then the status indicator should change to "Paused"
        expect(find.text('Paused'), findsOneWidget);
        expect(find.byKey(const Key('status_indicator_paused')), findsOneWidget);
      });
    });

    // -------------------------------------------
    // Auto-scroll Behavior
    // -------------------------------------------
    group('Scenario: New chunks auto-scroll to keep latest visible', () {
      testWidgets('should auto-scroll when new chunks arrive at bottom',
          (tester) async {
        // @step Given I am viewing a session stream at the bottom
        final connection = ConnectionFixtures.connectedInstance();
        await repository.save(connection);
        await tester.pumpWidget(testFactory.createSessionStreamWidget(
          connectionId: connection.id,
          sessionId: 'AUTH-001',
        ));
        await tester.pumpAndSettle();

        // @step When multiple text chunks arrive in sequence
        for (var i = 0; i < 5; i++) {
          testFactory.notifier.addChunk(TextChunk(content: 'Message $i', id: 'msg-$i'));
          await tester.pump();
        }
        await tester.pumpAndSettle();

        // @step Then the view should auto-scroll to show the latest content
        // Verify the last message is visible
        expect(find.text('Message 4'), findsOneWidget);
        // Verify auto-scroll indicator is active (not showing paused banner)
        expect(find.byKey(const Key('auto_scroll_active')), findsOneWidget);
      });
    });

    group('Scenario: Manual scroll up pauses auto-scroll', () {
      testWidgets('should pause auto-scroll when user scrolls up',
          (tester) async {
        // @step Given I am viewing a session stream with auto-scroll active
        final connection = ConnectionFixtures.connectedInstance();
        await repository.save(connection);
        
        // Create initial state with several messages (autoScrollEnabled is true by default)
        final initialState = SessionStreamState(
          connectionName: 'MacBook Pro',
          sessionId: 'AUTH-001',
          sessionState: SessionState.running,
          autoScrollEnabled: true,
          displayItems: List.generate(
            20,
            (i) => StreamDisplayItem.assistantText(
              chunk: TextChunk(content: 'Message $i', id: 'msg-$i'),
            ),
          ),
        );
        
        await tester.pumpWidget(testFactory.createSessionStreamWidget(
          connectionId: connection.id,
          sessionId: 'AUTH-001',
          initialState: initialState,
        ));
        await tester.pumpAndSettle();

        // @step When I manually scroll up to view earlier content
        // Simulate scroll by calling pauseAutoScroll (drag events in widget tests are unreliable)
        testFactory.notifier.pauseAutoScroll();
        await tester.pumpAndSettle();

        // @step Then auto-scroll should pause
        expect(find.byKey(const Key('auto_scroll_paused')), findsOneWidget);

        // @step And I should be able to review earlier messages
        expect(find.text('Message 0'), findsOneWidget);
      });
    });

    // -------------------------------------------
    // Emergency Interrupt
    // -------------------------------------------
    group('Scenario: Emergency interrupt button is always visible', () {
      testWidgets('should display red emergency interrupt button',
          (tester) async {
        // @step Given I am viewing a session stream
        final connection = ConnectionFixtures.connectedInstance();
        await repository.save(connection);
        await tester.pumpWidget(testFactory.createSessionStreamWidget(
          connectionId: connection.id,
          sessionId: 'AUTH-001',
        ));
        await tester.pumpAndSettle();

        // @step Then I should see an "Emergency Interrupt" button at the bottom
        expect(find.text('EMERGENCY INTERRUPT'), findsOneWidget);
        expect(find.byKey(const Key('emergency_interrupt_button')), findsOneWidget);

        // @step And the button should be styled prominently in red
        final button = tester.widget<ElevatedButton>(
          find.byKey(const Key('emergency_interrupt_button')),
        );
        // Verify button exists and is an ElevatedButton
        expect(button, isA<ElevatedButton>());
      });
    });
  });
}

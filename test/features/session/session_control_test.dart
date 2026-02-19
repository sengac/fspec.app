/// Feature: spec/features/session-control.feature
///
/// Tests for Session Control feature.
/// Validates interrupt button, clear session via header menu,
/// confirmation dialog, and graceful handling of disconnected state.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fspec_mobile/core/websocket/websocket_message.dart';

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

  group('Feature: Session Control', () {
    // ===========================================
    // INTERRUPT SCENARIOS
    // ===========================================

    group('Scenario: User sends interrupt command via emergency button', () {
      testWidgets('should send interrupt message when emergency button tapped',
          (tester) async {
        // @step Given I am viewing an active session stream
        final connection = ConnectionFixtures.connectedInstance();
        await repository.save(connection);
        final fakeManager = fakeService.ensureFakeManager(connection.id);

        await tester.pumpWidget(testFactory.createSessionStreamWidget(
          connectionId: connection.id,
          sessionId: 'AUTH-001',
        ));
        await tester.pumpAndSettle();

        // @step And the session is running
        expect(find.byKey(const Key('session_stream_screen')), findsOneWidget);

        // @step When I tap the emergency interrupt button
        await tester.tap(find.byKey(const Key('emergency_interrupt_button')));
        await tester.pumpAndSettle();

        // @step Then a session_control message with action "interrupt" should be sent
        expect(fakeManager.sentMessages.length, 1);
        expect(
          fakeManager.sentMessages.first.type,
          MessageType.sessionControl,
        );
        expect(
          fakeManager.sentMessages.first.data['action'],
          'interrupt',
        );

        // @step And the message should include the current session_id
        expect(fakeManager.sentMessages.first.sessionId, 'AUTH-001');
      });
    });

    // ===========================================
    // CLEAR SESSION SCENARIOS
    // ===========================================

    group('Scenario: User clears session via header menu', () {
      testWidgets('should send clear message after confirmation',
          (tester) async {
        // @step Given I am viewing an active session stream
        final connection = ConnectionFixtures.connectedInstance();
        await repository.save(connection);
        final fakeManager = fakeService.ensureFakeManager(connection.id);

        await tester.pumpWidget(testFactory.createSessionStreamWidget(
          connectionId: connection.id,
          sessionId: 'AUTH-001',
        ));
        await tester.pumpAndSettle();

        // @step When I tap the overflow menu in the header
        await tester.tap(find.byKey(const Key('header_overflow_menu')));
        await tester.pumpAndSettle();

        // @step And I tap "Clear Session"
        await tester.tap(find.text('Clear Session'));
        await tester.pumpAndSettle();

        // @step Then a confirmation dialog should appear
        expect(find.byKey(const Key('clear_session_dialog')), findsOneWidget);
        expect(find.text('Clear Session?'), findsOneWidget);

        // @step When I confirm the clear action
        await tester.tap(find.byKey(const Key('confirm_clear_button')));
        await tester.pumpAndSettle();

        // @step Then a session_control message with action "clear" should be sent
        expect(fakeManager.sentMessages.length, 1);
        expect(
          fakeManager.sentMessages.first.type,
          MessageType.sessionControl,
        );
        expect(
          fakeManager.sentMessages.first.data['action'],
          'clear',
        );

        // @step And the message should include the current session_id
        expect(fakeManager.sentMessages.first.sessionId, 'AUTH-001');
      });
    });

    group('Scenario: User cancels clear session confirmation', () {
      testWidgets('should not send message when cancel tapped', (tester) async {
        // @step Given I am viewing an active session stream
        final connection = ConnectionFixtures.connectedInstance();
        await repository.save(connection);
        final fakeManager = fakeService.ensureFakeManager(connection.id);

        await tester.pumpWidget(testFactory.createSessionStreamWidget(
          connectionId: connection.id,
          sessionId: 'AUTH-001',
        ));
        await tester.pumpAndSettle();

        // @step When I tap the overflow menu in the header
        await tester.tap(find.byKey(const Key('header_overflow_menu')));
        await tester.pumpAndSettle();

        // @step And I tap "Clear Session"
        await tester.tap(find.text('Clear Session'));
        await tester.pumpAndSettle();

        // @step Then a confirmation dialog should appear
        expect(find.byKey(const Key('clear_session_dialog')), findsOneWidget);

        // @step When I cancel the clear action
        await tester.tap(find.byKey(const Key('cancel_clear_button')));
        await tester.pumpAndSettle();

        // @step Then no session_control message should be sent
        expect(fakeManager.sentMessages, isEmpty);
      });
    });

    // ===========================================
    // OFFLINE HANDLING
    // ===========================================

    group('Scenario: User taps interrupt while disconnected', () {
      testWidgets('should handle disconnect gracefully', (tester) async {
        // @step Given I am viewing a session stream
        final connection = ConnectionFixtures.connectedInstance();
        await repository.save(connection);
        final fakeManager = fakeService.ensureFakeManager(connection.id);

        await tester.pumpWidget(testFactory.createSessionStreamWidget(
          connectionId: connection.id,
          sessionId: 'AUTH-001',
        ));
        await tester.pumpAndSettle();

        // @step And the WebSocket connection is disconnected
        fakeManager.simulateDisconnect();
        await tester.pumpAndSettle();

        // @step When I tap the emergency interrupt button
        await tester.tap(find.byKey(const Key('emergency_interrupt_button')));
        await tester.pumpAndSettle();

        // @step Then the interrupt should fail gracefully
        // @step And no crash should occur
        // If we reach here without exception, the test passes
        expect(fakeManager.sentMessages, isEmpty);
      });
    });

    // ===========================================
    // UI DISPLAY
    // ===========================================

    group('Scenario: Emergency interrupt button is prominently displayed', () {
      testWidgets('should display red interrupt button above input bar',
          (tester) async {
        // @step Given I am viewing an active session stream
        final connection = ConnectionFixtures.connectedInstance();
        await repository.save(connection);
        fakeService.ensureFakeManager(connection.id);

        await tester.pumpWidget(testFactory.createSessionStreamWidget(
          connectionId: connection.id,
          sessionId: 'AUTH-001',
        ));
        await tester.pumpAndSettle();

        // @step Then I should see the emergency interrupt button in red
        final emergencyButtonFinder = find.byKey(const Key('emergency_interrupt_button'));
        expect(emergencyButtonFinder, findsOneWidget);
        
        // The key is directly on the ElevatedButton.icon widget
        final button = tester.widget<ElevatedButton>(emergencyButtonFinder);
        // Check that the button has a red background
        final backgroundColor = button.style?.backgroundColor?.resolve({});
        expect(backgroundColor, equals(Colors.red[700]));

        // @step And the button should be positioned above the input bar
        final inputBarFinder = find.byKey(const Key('input_bar'));
        expect(inputBarFinder, findsOneWidget);

        final interruptBox = tester.getRect(emergencyButtonFinder);
        final inputBox = tester.getRect(inputBarFinder);

        // Interrupt button should be above (smaller Y = higher on screen)
        expect(interruptBox.bottom, lessThanOrEqualTo(inputBox.top + 10));

        // @step And the button should span the full width of the screen
        // Button is in a Container with width: double.infinity and padding
        // We check it's reasonably wide (most of screen width minus padding)
        final screenWidth = tester.view.physicalSize.width /
            tester.view.devicePixelRatio;
        expect(interruptBox.width, greaterThan(screenWidth * 0.7));
      });
    });
  });
}

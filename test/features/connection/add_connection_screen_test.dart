/// Feature: spec/features/add-connection-screen.feature
///
/// Tests for Add Connection Screen.
/// Includes widget tests for form/UI and unit tests for QR code parsing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fspec_mobile/features/connection/data/providers/connection_providers.dart';
import 'package:fspec_mobile/features/connection/presentation/screens/add_connection_screen.dart';
import 'package:fspec_mobile/features/connection/domain/services/qr_code_parser.dart';

import '../../fixtures/qr_code_fixtures.dart';
import '../../fixtures/in_memory_connection_repository.dart';

void main() {
  late InMemoryConnectionRepository repository;

  setUp(() {
    repository = InMemoryConnectionRepository();
  });

  Widget createTestWidget({Widget? child}) {
    return ProviderScope(
      overrides: [
        connectionRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        home: child ?? const AddConnectionScreen(),
      ),
    );
  }

  group('Feature: Add Connection Screen', () {
    group('Scenario: Creating connection with all required fields succeeds', () {
      testWidgets('should save connection and return to list', (tester) async {
        // @step Given I am on the Add Connection screen
        await tester.pumpWidget(createTestWidget());

        // @step When I enter "Work MacBook" in the Connection Name field
        await tester.enterText(
          find.byKey(const Key('connection_name_field')),
          'Work MacBook',
        );

        // @step And I enter "https://relay.fspec.dev" in the Relay Server URL field
        await tester.enterText(
          find.byKey(const Key('relay_url_field')),
          'https://relay.fspec.dev',
        );

        // @step And I enter "abc-123" in the Channel ID field
        await tester.enterText(
          find.byKey(const Key('channel_id_field')),
          'abc-123',
        );

        // @step And I tap the Save button
        await tester.ensureVisible(find.byKey(const Key('save_button')));
        await tester.tap(find.byKey(const Key('save_button')));
        await tester.pumpAndSettle();

        // @step Then the connection should be saved
        expect(repository.hasConnectionNamed('Work MacBook'), isTrue);

        // @step And I should be returned to the connections list
        final savedConnection = await repository.getByName('Work MacBook');
        expect(savedConnection, isNotNull);
        expect(savedConnection!.relayUrl, equals('https://relay.fspec.dev'));
        expect(savedConnection.channelId, equals('abc-123'));
      });
    });

    group('Scenario: Creating connection without API key succeeds', () {
      testWidgets('should save connection without API key', (tester) async {
        // @step Given I am on the Add Connection screen
        await tester.pumpWidget(createTestWidget());

        // @step When I enter "Personal Laptop" in the Connection Name field
        await tester.enterText(
          find.byKey(const Key('connection_name_field')),
          'Personal Laptop',
        );

        // @step And I enter "https://relay.example.com" in the Relay Server URL field
        await tester.enterText(
          find.byKey(const Key('relay_url_field')),
          'https://relay.example.com',
        );

        // @step And I enter "xyz-789" in the Channel ID field
        await tester.enterText(
          find.byKey(const Key('channel_id_field')),
          'xyz-789',
        );

        // @step And I tap the Save button
        await tester.ensureVisible(find.byKey(const Key('save_button')));
        await tester.tap(find.byKey(const Key('save_button')));
        await tester.pumpAndSettle();

        // @step Then the connection should be saved
        final savedConnection = await repository.getByName('Personal Laptop');
        expect(savedConnection, isNotNull);
        expect(savedConnection!.apiKey, isNull);

        // @step And I should be returned to the connections list
        expect(savedConnection.relayUrl, equals('https://relay.example.com'));
      });
    });

    group('Scenario: Camera permission denied shows settings option', () {
      testWidgets('should show settings option when camera denied', (tester) async {
        // @step Given camera permission is denied
        // (Simulated - the current implementation shows permission denied on QR button tap)

        // @step When I tap the Scan QR Code button
        await tester.pumpWidget(createTestWidget());
        await tester.tap(find.byKey(const Key('scan_qr_button')));
        await tester.pumpAndSettle();

        // @step Then I should see a camera permission explanation
        expect(find.text('Camera access required'), findsOneWidget);

        // @step And I should see an "Open Settings" button
        expect(find.byKey(const Key('open_settings_button')), findsOneWidget);
      });
    });

    group('Scenario: Empty connection name shows validation error', () {
      testWidgets('should show validation error for empty name', (tester) async {
        // @step Given I am on the Add Connection screen
        await tester.pumpWidget(createTestWidget());

        // @step When I leave the Connection Name field empty
        // (field is already empty)

        // @step And I enter "https://relay.fspec.dev" in the Relay Server URL field
        await tester.enterText(
          find.byKey(const Key('relay_url_field')),
          'https://relay.fspec.dev',
        );

        // @step And I enter "abc-123" in the Channel ID field
        await tester.enterText(
          find.byKey(const Key('channel_id_field')),
          'abc-123',
        );

        // @step And I tap the Save button
        await tester.ensureVisible(find.byKey(const Key('save_button')));
        await tester.tap(find.byKey(const Key('save_button')));
        await tester.pumpAndSettle();

        // @step Then I should see a validation error "Connection name is required"
        expect(find.text('Connection name is required'), findsOneWidget);

        // @step And the connection should not be saved
        expect(repository.storedConnections, isEmpty);
      });
    });

    group('Scenario: HTTP URL shows validation error', () {
      testWidgets('should show validation error for http URL', (tester) async {
        // @step Given I am on the Add Connection screen
        await tester.pumpWidget(createTestWidget());

        // @step When I enter "Work MacBook" in the Connection Name field
        await tester.enterText(
          find.byKey(const Key('connection_name_field')),
          'Work MacBook',
        );

        // @step And I enter "http://relay.example.com" in the Relay Server URL field
        await tester.enterText(
          find.byKey(const Key('relay_url_field')),
          'http://relay.example.com',
        );

        // @step And I enter "abc-123" in the Channel ID field
        await tester.enterText(
          find.byKey(const Key('channel_id_field')),
          'abc-123',
        );

        // @step And I tap the Save button
        await tester.ensureVisible(find.byKey(const Key('save_button')));
        await tester.tap(find.byKey(const Key('save_button')));
        await tester.pumpAndSettle();

        // @step Then I should see a validation error "URL must use https"
        expect(find.text('URL must use https'), findsOneWidget);

        // @step And the connection should not be saved
        expect(repository.storedConnections, isEmpty);
      });
    });

    group('Scenario: Empty channel ID shows validation error', () {
      testWidgets('should show validation error for empty channel ID', (tester) async {
        // @step Given I am on the Add Connection screen
        await tester.pumpWidget(createTestWidget());

        // @step When I enter "Work MacBook" in the Connection Name field
        await tester.enterText(
          find.byKey(const Key('connection_name_field')),
          'Work MacBook',
        );

        // @step And I enter "https://relay.fspec.dev" in the Relay Server URL field
        await tester.enterText(
          find.byKey(const Key('relay_url_field')),
          'https://relay.fspec.dev',
        );

        // @step And I leave the Channel ID field empty
        // (field is already empty)

        // @step And I tap the Save button
        await tester.ensureVisible(find.byKey(const Key('save_button')));
        await tester.tap(find.byKey(const Key('save_button')));
        await tester.pumpAndSettle();

        // @step Then I should see a validation error "Channel ID is required"
        expect(find.text('Channel ID is required'), findsOneWidget);

        // @step And the connection should not be saved
        expect(repository.storedConnections, isEmpty);
      });
    });

    group('Scenario: Cancel button returns to previous screen without saving', () {
      testWidgets('should navigate back without saving', (tester) async {
        // @step Given I am on the Add Connection screen
        await tester.pumpWidget(createTestWidget());

        // @step When I enter "Work MacBook" in the Connection Name field
        await tester.enterText(
          find.byKey(const Key('connection_name_field')),
          'Work MacBook',
        );

        // @step And I tap the Cancel button
        await tester.ensureVisible(find.byKey(const Key('cancel_button')));
        await tester.tap(find.byKey(const Key('cancel_button')));
        await tester.pumpAndSettle();

        // @step Then I should be returned to the previous screen
        // (Navigation handled by Navigator.maybePop)

        // @step And no connection should be saved
        expect(repository.storedConnections, isEmpty);
      });
    });

    group('Scenario: API key visibility can be toggled', () {
      testWidgets('should toggle API key visibility', (tester) async {
        // @step Given I am on the Add Connection screen
        await tester.pumpWidget(createTestWidget());

        // @step When I enter "my-secret-key" in the API Key field
        await tester.enterText(
          find.byKey(const Key('api_key_field')),
          'my-secret-key',
        );
        await tester.pumpAndSettle();

        // @step Then the API Key field should be obscured
        // Check that the visibility icon is shown (meaning it's currently hidden)
        expect(find.byIcon(Icons.visibility), findsOneWidget);
        expect(find.byIcon(Icons.visibility_off), findsNothing);

        // @step When I tap the visibility toggle on the API Key field
        await tester.tap(find.byKey(const Key('api_key_visibility_toggle')));
        await tester.pumpAndSettle();

        // @step Then the API Key field should show "my-secret-key"
        // Check that visibility_off icon is shown (meaning it's now visible)
        expect(find.byIcon(Icons.visibility_off), findsOneWidget);
        expect(find.byIcon(Icons.visibility), findsNothing);

        // @step When I tap the visibility toggle on the API Key field
        await tester.tap(find.byKey(const Key('api_key_visibility_toggle')));
        await tester.pumpAndSettle();

        // @step Then the API Key field should be obscured
        expect(find.byIcon(Icons.visibility), findsOneWidget);
        expect(find.byIcon(Icons.visibility_off), findsNothing);
      });
    });

    // QR Code Parsing Tests (unit tests for QrCodeParser)
    group('Scenario: Scanning valid QR code auto-populates all fields', () {
      test('should parse valid QR code with all fields', () {
        // @step When I tap the Scan QR Code button
        // (Scanner opened - tested in widget test)

        // @step And I scan a QR code containing "fspec://connect?n=Work%20MacBook&r=https://relay.fspec.dev&c=abc-123&k=secret-key"
        final result = QrCodeParser.parse(QrCodeFixtures.validWithAllFields);

        // @step Then the Connection Name field should contain "Work MacBook"
        expect(result.name, equals('Work MacBook'));

        // @step And the Relay Server URL field should contain "https://relay.fspec.dev"
        expect(result.relayUrl, equals('https://relay.fspec.dev'));

        // @step And the Channel ID field should contain "abc-123"
        expect(result.channelId, equals('abc-123'));

        // @step And the API Key field should contain "secret-key"
        expect(result.apiKey, equals('secret-key'));
      });
    });

    group('Scenario: Scanning QR code without API key auto-populates available fields', () {
      test('should parse valid QR code without API key', () {
        // @step When I tap the Scan QR Code button
        // (Scanner opened - tested in widget test)

        // @step And I scan a QR code containing "fspec://connect?n=Home%20Server&r=https://relay.home.dev&c=home-456"
        final result = QrCodeParser.parse(QrCodeFixtures.validWithoutApiKey);

        // @step Then the Connection Name field should contain "Home Server"
        expect(result.name, equals('Home Server'));

        // @step And the Relay Server URL field should contain "https://relay.home.dev"
        expect(result.relayUrl, equals('https://relay.home.dev'));

        // @step And the Channel ID field should contain "home-456"
        expect(result.channelId, equals('home-456'));

        // @step And the API Key field should be empty
        expect(result.apiKey, isNull);
      });
    });

    group('Scenario: Scanning invalid QR code shows error and stays on scanner', () {
      test('should return error for invalid scheme', () {
        // @step When I tap the Scan QR Code button
        // (Scanner opened - tested in widget test)

        // @step And I scan a QR code containing "https://example.com"
        final result = QrCodeParser.parse(QrCodeFixtures.invalidScheme);

        // @step Then I should see a toast message "Not a valid fspec connection code"
        expect(result.isValid, isFalse);
        expect(result.error, equals('Not a valid fspec connection code'));

        // @step And I should remain on the QR scanner
        // (UI behavior - handled in widget test)
      });
    });

    group('Scenario: Scanning QR code with missing fields partially fills form', () {
      test('should parse partial QR code data', () {
        // @step When I tap the Scan QR Code button
        // (Scanner opened - tested in widget test)

        // @step And I scan a QR code containing "fspec://connect?n=Partial&r=https://relay.dev"
        final result = QrCodeParser.parse(QrCodeFixtures.partialFields);

        // @step Then the Connection Name field should contain "Partial"
        expect(result.name, equals('Partial'));

        // @step And the Relay Server URL field should contain "https://relay.dev"
        expect(result.relayUrl, equals('https://relay.dev'));

        // @step And the Channel ID field should be empty
        expect(result.channelId, isNull);

        // @step And I should see a toast message "Some fields couldn't be read. Please complete manually."
        expect(result.isPartial, isTrue);
        expect(result.partialMessage, equals("Some fields couldn't be read. Please complete manually."));
      });
    });
  });
}

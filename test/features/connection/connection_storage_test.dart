/// Feature: spec/features/connection-storage.feature
///
/// This test file validates the acceptance criteria defined in the feature file.
/// Tests the Connection data model and local storage persistence using Hive.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:fspec_mobile/features/connection/domain/models/connection.dart';
import 'package:fspec_mobile/features/connection/data/repositories/connection_repository.dart';

import '../../fixtures/connection_fixtures.dart';

void main() {
  late ConnectionRepository repository;
  late Directory tempDir;

  setUpAll(() async {
    // Initialize Hive with a temporary directory for tests
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    // Clean up temp directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    repository = ConnectionRepository();
    await repository.clear(); // Start fresh for each test
  });

  tearDown(() async {
    await repository.clear();
  });

  group('Feature: Connection Data Model and Local Storage', () {
    group('Scenario: Creating a connection with all required fields succeeds', () {
      test('should create and save a connection successfully', () async {
        // @step Given I have no saved connections
        final initialConnections = await repository.getAll();
        expect(initialConnections, isEmpty);

        // @step When I create a connection with:
        // | name       | Work MacBook              |
        // | relayUrl   | https://relay.fspec.dev   |
        // | channelId  | abc-123                   |
        final connection = ConnectionFixtures.validConnection();
        final result = await repository.save(connection);

        // @step Then the connection should be saved successfully
        expect(result.isRight(), isTrue);

        // @step And the connection should have a unique UUID
        final saved = result.getOrElse((_) => throw Exception('Failed'));
        expect(saved.id, isNotEmpty);
        expect(saved.id.length, equals(36)); // UUID format

        // @step And the connection status should be "disconnected"
        expect(saved.status, equals(ConnectionStatus.disconnected));
      });
    });

    group('Scenario: Creating a connection without API key succeeds', () {
      test('should create connection with null API key', () async {
        // @step Given I have no saved connections
        final initialConnections = await repository.getAll();
        expect(initialConnections, isEmpty);

        // @step When I create a connection with:
        // | name       | Home Server               |
        // | relayUrl   | https://relay.fspec.dev   |
        // | channelId  | xyz-789                   |
        // | apiKey     |                           |
        final connection = ConnectionFixtures.connectionWithoutApiKey();
        final result = await repository.save(connection);

        // @step Then the connection should be saved successfully
        expect(result.isRight(), isTrue);
        final saved = result.getOrElse((_) => throw Exception('Failed'));
        expect(saved.apiKey, isNull);
      });
    });

    group('Scenario: Creating a connection with empty name fails', () {
      test('should fail validation with empty name', () async {
        // @step Given I have no saved connections
        final initialConnections = await repository.getAll();
        expect(initialConnections, isEmpty);

        // @step When I create a connection with:
        // | name       |                           |
        // | relayUrl   | https://relay.fspec.dev   |
        // | channelId  | abc-123                   |
        final connection = ConnectionFixtures.connectionWithEmptyName();
        final result = await repository.save(connection);

        // @step Then the connection should fail with validation error "Name is required"
        expect(result.isLeft(), isTrue);
        result.fold(
          (error) => expect(error.message, contains('Name is required')),
          (_) => fail('Should have failed'),
        );
      });
    });

    group('Scenario: Creating a connection with http URL fails', () {
      test('should fail validation with http URL', () async {
        // @step Given I have no saved connections
        final initialConnections = await repository.getAll();
        expect(initialConnections, isEmpty);

        // @step When I create a connection with:
        // | name       | Insecure Server           |
        // | relayUrl   | http://relay.fspec.dev    |
        // | channelId  | abc-123                   |
        final connection = ConnectionFixtures.connectionWithHttpUrl();
        final result = await repository.save(connection);

        // @step Then the connection should fail with validation error "URL must use HTTPS"
        expect(result.isLeft(), isTrue);
        result.fold(
          (error) => expect(error.message, contains('URL must use HTTPS')),
          (_) => fail('Should have failed'),
        );
      });
    });

    group('Scenario: Saved connections persist after app restart', () {
      test('should load connections from storage', () async {
        // @step Given I have a saved connection named "Work MacBook"
        final connection = ConnectionFixtures.validConnection();
        await repository.save(connection);

        // @step When the app restarts
        // Simulate restart by creating new repository instance
        final newRepository = ConnectionRepository();

        // @step And I list all connections
        final connections = await newRepository.getAll();

        // @step Then I should see a connection named "Work MacBook"
        expect(connections.any((c) => c.name == 'Work MacBook'), isTrue);
      });
    });

    group('Scenario: Updating a connection name persists the change', () {
      test('should persist name update', () async {
        // @step Given I have a saved connection named "Old Name"
        final connection = ConnectionFixtures.validConnection(name: 'Old Name');
        final saveResult = await repository.save(connection);
        final saved = saveResult.getOrElse((_) => throw Exception('Failed'));

        // @step When I update the connection name to "New Name"
        final updated = saved.copyWith(name: 'New Name');
        await repository.save(updated);

        // @step And the app restarts
        final newRepository = ConnectionRepository();

        // @step And I list all connections
        final connections = await newRepository.getAll();

        // @step Then I should see a connection named "New Name"
        expect(connections.any((c) => c.name == 'New Name'), isTrue);

        // @step And I should not see a connection named "Old Name"
        expect(connections.any((c) => c.name == 'Old Name'), isFalse);
      });
    });

    group('Scenario: Deleting a connection removes it permanently', () {
      test('should remove deleted connection from storage', () async {
        // @step Given I have a saved connection named "To Delete"
        final connection = ConnectionFixtures.validConnection(name: 'To Delete');
        final saveResult = await repository.save(connection);
        final saved = saveResult.getOrElse((_) => throw Exception('Failed'));

        // @step When I delete the connection named "To Delete"
        await repository.delete(saved.id);

        // @step And the app restarts
        final newRepository = ConnectionRepository();

        // @step And I list all connections
        final connections = await newRepository.getAll();

        // @step Then I should not see a connection named "To Delete"
        expect(connections.any((c) => c.name == 'To Delete'), isFalse);
      });
    });

    group('Scenario: Listing connections returns them in creation order', () {
      test('should return connections in creation order', () async {
        // @step Given I have no saved connections
        await repository.clear();

        // @step When I create a connection named "First"
        await repository.save(ConnectionFixtures.namedConnection('First'));

        // Small delay to ensure different timestamps
        await Future.delayed(const Duration(milliseconds: 10));

        // @step And I create a connection named "Second"
        await repository.save(ConnectionFixtures.namedConnection('Second'));

        await Future.delayed(const Duration(milliseconds: 10));

        // @step And I create a connection named "Third"
        await repository.save(ConnectionFixtures.namedConnection('Third'));

        // @step And I list all connections
        final connections = await repository.getAll();

        // @step Then the connections should be in order:
        // | name   |
        // | First  |
        // | Second |
        // | Third  |
        expect(connections.length, equals(3));
        expect(connections[0].name, equals('First'));
        expect(connections[1].name, equals('Second'));
        expect(connections[2].name, equals('Third'));
      });
    });
  });
}

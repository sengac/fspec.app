/// Feature: spec/features/connection-storage.feature
///
/// Shared test fixtures for Connection-related tests.
/// Provides reusable Connection objects matching the Gherkin scenarios.
library;

import 'package:fspec_mobile/features/connection/domain/models/connection.dart';

/// Standard test fixtures for Connection scenarios
class ConnectionFixtures {
  /// Valid connection with all required fields
  /// Used for: "Creating a connection with all required fields succeeds"
  static Connection validConnection({
    String name = 'Work MacBook',
    String relayUrl = 'https://relay.fspec.dev',
    String channelId = 'abc-123',
    String? apiKey,
  }) {
    return Connection(
      name: name,
      relayUrl: relayUrl,
      channelId: channelId,
      apiKey: apiKey,
    );
  }

  /// Connection with no API key (API key is optional)
  /// Used for: "Creating a connection without API key succeeds"
  static Connection connectionWithoutApiKey({
    String name = 'Home Server',
    String channelId = 'xyz-789',
  }) {
    return Connection(
      name: name,
      relayUrl: 'https://relay.fspec.dev',
      channelId: channelId,
      apiKey: null,
    );
  }

  /// Invalid connection with empty name
  /// Used for: "Creating a connection with empty name fails"
  static Connection connectionWithEmptyName() {
    return const Connection(
      name: '',
      relayUrl: 'https://relay.fspec.dev',
      channelId: 'abc-123',
    );
  }

  /// Invalid connection with http URL (must be https)
  /// Used for: "Creating a connection with http URL fails"
  static Connection connectionWithHttpUrl() {
    return const Connection(
      name: 'Insecure Server',
      relayUrl: 'http://relay.fspec.dev',
      channelId: 'abc-123',
    );
  }

  /// Create a named connection for ordering tests
  /// Used for: "Listing connections returns them in creation order"
  static Connection namedConnection(String name, {String? channelId}) {
    return Connection(
      name: name,
      relayUrl: 'https://relay.fspec.dev',
      channelId: channelId ?? 'ch-${name.toLowerCase()}',
    );
  }
}

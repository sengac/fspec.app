/// Feature: spec/features/instance-dashboard.feature
///
/// Shared test fixtures for Dashboard-related tests.
/// Provides reusable Connection objects with various status and activity states.
library;

import 'package:fspec_mobile/features/connection/domain/models/connection.dart';

/// Standard test fixtures for Dashboard scenarios
class DashboardFixtures {
  /// Online connection with project name
  /// Used for: Status indicator tests, project name display
  static Connection onlineConnection({
    String name = 'MacBook Pro',
    String projectName = 'fspec-core',
    String channelId = 'channel-1',
  }) {
    return Connection.create(
      name: name,
      relayUrl: 'https://relay.fspec.dev',
      channelId: channelId,
    ).copyWith(
      status: ConnectionStatus.connected,
      lastKnownProjectName: projectName,
    );
  }

  /// Offline (disconnected) connection
  /// Used for: Offline status indicator tests
  static Connection offlineConnection({
    String name = 'Ubuntu Server',
    String projectName = 'api-gateway',
    String channelId = 'channel-2',
  }) {
    return Connection.create(
      name: name,
      relayUrl: 'https://relay.fspec.dev',
      channelId: channelId,
    ).copyWith(
      status: ConnectionStatus.disconnected,
      lastKnownProjectName: projectName,
    );
  }

  /// Syncing (connecting) connection
  /// Used for: SYNCING status indicator tests
  static Connection syncingConnection({
    String name = 'Staging Server',
    String projectName = 'staging-app',
    String channelId = 'channel-3',
  }) {
    return Connection.create(
      name: name,
      relayUrl: 'https://relay.fspec.dev',
      channelId: channelId,
    ).copyWith(
      status: ConnectionStatus.connecting,
      lastKnownProjectName: projectName,
    );
  }

  /// Error state connection
  /// Used for: Error indicator and retry button tests
  static Connection errorConnection({
    String name = 'Build Server',
    String errorContent = 'Build failed at step 4: dependency conflict...',
    String channelId = 'channel-4',
  }) {
    return Connection.create(
      name: name,
      relayUrl: 'https://relay.fspec.dev',
      channelId: channelId,
    ).copyWith(
      status: ConnectionStatus.error,
      lastActivityType: ActivityType.error,
      lastActivityContent: errorContent,
      lastActivityAt: DateTime.now(),
    );
  }

  /// Connection with AI output activity
  /// Used for: AI output preview display tests
  static Connection connectionWithAiOutput({
    String name = 'MacBook Pro',
    String content = 'Optimized 3 functions in core module. Reduced latency by 12%...',
  }) {
    return Connection.create(
      name: name,
      relayUrl: 'https://relay.fspec.dev',
      channelId: 'channel-ai',
    ).copyWith(
      status: ConnectionStatus.connected,
      lastActivityType: ActivityType.aiOutput,
      lastActivityContent: content,
      lastActivityAt: DateTime.now(),
    );
  }

  /// Connection with status message activity
  /// Used for: Status message preview display tests
  static Connection connectionWithStatusMessage({
    String name = 'CI Server',
    String content = 'Pipeline completed successfully',
  }) {
    return Connection.create(
      name: name,
      relayUrl: 'https://relay.fspec.dev',
      channelId: 'channel-status',
    ).copyWith(
      status: ConnectionStatus.connected,
      lastActivityType: ActivityType.status,
      lastActivityContent: content,
      lastActivityAt: DateTime.now(),
    );
  }

  /// Connection with recent activity for relative time display
  /// Used for: "just now", "Xm ago" time display tests
  static Connection connectionWithRecentActivity({
    String name = 'Recent Server',
    Duration ago = Duration.zero,
  }) {
    return Connection.create(
      name: name,
      relayUrl: 'https://relay.fspec.dev',
      channelId: 'channel-recent',
    ).copyWith(
      status: ConnectionStatus.connected,
      lastActivityType: ActivityType.status,
      lastActivityContent: 'Recent activity',
      lastActivityAt: DateTime.now().subtract(ago),
    );
  }

  /// Standard 3-connection setup for multi-card tests
  /// Returns: [Online MacBook, Offline Ubuntu, Online VM]
  static List<Connection> multipleConnections() {
    return [
      onlineConnection(
        name: 'MacBook Pro',
        projectName: 'fspec-core',
        channelId: 'channel-1',
      ),
      offlineConnection(
        name: 'Ubuntu Server',
        projectName: 'api-gateway',
        channelId: 'channel-2',
      ),
      onlineConnection(
        name: 'Development VM',
        projectName: 'mobile-ui',
        channelId: 'channel-3',
      ),
    ];
  }
}

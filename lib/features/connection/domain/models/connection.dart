import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'connection.freezed.dart';
part 'connection.g.dart';

/// Connection status enumeration
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// Activity type for last activity preview on dashboard
enum ActivityType {
  aiOutput,
  error,
  status,
}

/// Connection model representing a relay server connection
///
/// Stores all necessary information to connect to an fspec instance
/// through a relay server.
@freezed
abstract class Connection with _$Connection {
  const Connection._();

  const factory Connection({
    /// Unique identifier for this connection (UUID)
    @Default('') String id,

    /// Display name for this connection
    required String name,

    /// Relay server URL (must use HTTPS)
    required String relayUrl,

    /// Channel ID for connecting to the relay
    required String channelId,

    /// Optional API key for authentication
    String? apiKey,

    /// Current connection status
    @Default(ConnectionStatus.disconnected) ConnectionStatus status,

    /// Timestamp when the connection was created
    DateTime? createdAt,

    /// Whether to auto-connect on app launch
    @Default(false) bool autoConnect,

    /// Cached project name from fspec instance (received via WebSocket)
    String? lastKnownProjectName,

    /// Type of the last activity (aiOutput, error, status)
    ActivityType? lastActivityType,

    /// Truncated preview content of the last activity
    String? lastActivityContent,

    /// Timestamp of the last activity for relative display
    DateTime? lastActivityAt,
  }) = _Connection;

  /// Create a new connection with auto-generated ID and timestamp
  factory Connection.create({
    required String name,
    required String relayUrl,
    required String channelId,
    String? apiKey,
  }) {
    return Connection(
      id: const Uuid().v4(),
      name: name,
      relayUrl: relayUrl,
      channelId: channelId,
      apiKey: apiKey,
      status: ConnectionStatus.disconnected,
      createdAt: DateTime.now(),
    );
  }

  factory Connection.fromJson(Map<String, dynamic> json) =>
      _$ConnectionFromJson(json);

  /// Validate the connection data
  /// Returns null if valid, or an error message if invalid
  String? validate() {
    if (name.trim().isEmpty) {
      return 'Name is required';
    }

    if (relayUrl.trim().isEmpty) {
      return 'Relay URL is required';
    }

    final lowerUrl = relayUrl.toLowerCase();
    // Allow http:// for localhost development
    final isLocalhost = lowerUrl.startsWith('http://localhost') ||
        lowerUrl.startsWith('http://127.0.0.1');
    if (!isLocalhost && !lowerUrl.startsWith('https://')) {
      return 'URL must use HTTPS';
    }

    if (channelId.trim().isEmpty) {
      return 'Channel ID is required';
    }

    return null;
  }

  /// Check if this connection is valid
  bool get isValid => validate() == null;
}

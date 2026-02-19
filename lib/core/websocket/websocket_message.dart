/// WebSocket message types and serialization
///
/// Extracted from websocket_manager.dart for separation of concerns.
/// Contains message type enum and message wrapper class.
library;

/// WebSocket message types matching fspec protocol
enum MessageType {
  // Outbound: mobile → relay → fspec
  input,
  sessionControl,
  command,
  auth, // Authentication handshake

  // Inbound: fspec → relay → mobile
  chunk,
  commandResponse,
  connected,
  authSuccess, // Authentication succeeded
  authError, // Authentication failed

  // System
  error,
  ping,
  pong,
}

/// WebSocket message wrapper
class WebSocketMessage {
  final MessageType type;
  final Map<String, dynamic> data;
  final String? requestId;
  final String? sessionId;
  final String? instanceId;

  const WebSocketMessage({
    required this.type,
    required this.data,
    this.requestId,
    this.sessionId,
    this.instanceId,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'data': data,
        if (requestId != null) 'request_id': requestId,
        if (sessionId != null) 'session_id': sessionId,
        if (instanceId != null) 'instance_id': instanceId,
      };

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final Map<String, dynamic> data = rawData != null
        ? Map<String, dynamic>.from(rawData as Map)
        : {};
    
    return WebSocketMessage(
      type: MessageType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => MessageType.error,
      ),
      data: data,
      requestId: json['request_id'] as String?,
      sessionId: json['session_id'] as String?,
      instanceId: json['instance_id'] as String?,
    );
  }

  /// Create an auth message for handshake
  factory WebSocketMessage.auth({
    required String channelId,
    String? apiKey,
  }) {
    return WebSocketMessage(
      type: MessageType.auth,
      data: {
        'channel_id': channelId,
        if (apiKey != null) 'api_key': apiKey,
      },
    );
  }

  /// Create a ping message for heartbeat
  factory WebSocketMessage.ping() {
    return WebSocketMessage(
      type: MessageType.ping,
      data: {'timestamp': DateTime.now().millisecondsSinceEpoch},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WebSocketMessage &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          requestId == other.requestId;

  @override
  int get hashCode => Object.hash(type, requestId);

  @override
  String toString() => 'WebSocketMessage($type, data: $data)';
}

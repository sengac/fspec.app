/// WebSocket state management types
///
/// Extracted from websocket_manager.dart for separation of concerns.
/// Contains connection state enum and authentication result types.
library;

/// WebSocket connection state
enum WebSocketState {
  disconnected,
  connecting,
  authenticating, // WebSocket connected, waiting for auth response
  connected,
  reconnecting,
  error,
}

/// Authentication error codes from relay
enum AuthErrorCode {
  invalidChannel,
  invalidApiKey,
  rateLimited,
  unknown,
}

/// Authentication result
class AuthResult {
  final bool success;
  final AuthErrorCode? errorCode;
  final String? errorMessage;
  final List<Map<String, dynamic>>? instances;

  const AuthResult.success({this.instances})
      : success = true,
        errorCode = null,
        errorMessage = null;

  const AuthResult.failure({
    required this.errorCode,
    this.errorMessage,
  })  : success = false,
        instances = null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthResult &&
          runtimeType == other.runtimeType &&
          success == other.success &&
          errorCode == other.errorCode &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(success, errorCode, errorMessage);

  @override
  String toString() => success
      ? 'AuthResult.success(instances: ${instances?.length ?? 0})'
      : 'AuthResult.failure($errorCode: $errorMessage)';
}

/// Feature: spec/features/websocket-relay-connection.feature
///
/// Shared test fixtures for WebSocket connection tests.
/// Provides reusable Connection objects for auth scenarios and fake WebSocket behavior.
library;

import 'dart:async';
import 'dart:convert';

import 'package:fspec_mobile/features/connection/domain/models/connection.dart';
import 'package:fspec_mobile/core/websocket/websocket_message.dart';
import 'package:fspec_mobile/core/websocket/websocket_state.dart';

/// Test fixtures for WebSocket relay connection scenarios
class WebSocketFixtures {
  /// Connection with valid credentials for successful auth
  /// Used for: "Successful connection to relay server"
  static Connection validAuthConnection({
    String name = 'Test Connection',
    String channelId = 'valid-channel-123',
    String apiKey = 'valid-api-key',
  }) {
    return Connection.create(
      name: name,
      relayUrl: 'https://relay.fspec.dev',
      channelId: channelId,
      apiKey: apiKey,
    );
  }

  /// Connection with invalid API key
  /// Used for: "Connection fails with invalid API key"
  static Connection invalidApiKeyConnection({
    String name = 'Invalid API Key Connection',
    String channelId = 'valid-channel-123',
  }) {
    return Connection.create(
      name: name,
      relayUrl: 'https://relay.fspec.dev',
      channelId: channelId,
      apiKey: 'invalid-api-key',
    );
  }

  /// Connection with invalid channel ID
  /// Used for: "Connection fails with invalid channel ID"
  static Connection invalidChannelConnection({
    String name = 'Invalid Channel Connection',
    String apiKey = 'valid-api-key',
  }) {
    return Connection.create(
      name: name,
      relayUrl: 'https://relay.fspec.dev',
      channelId: 'nonexistent-channel',
      apiKey: apiKey,
    );
  }

  /// Connection marked for auto-connect
  /// Used for: "Auto-connect on app launch"
  static Connection autoConnectConnection({
    String name = 'Auto Connect Connection',
  }) {
    return Connection.create(
      name: name,
      relayUrl: 'https://relay.fspec.dev',
      channelId: 'auto-channel',
      apiKey: 'auto-api-key',
    ).copyWith(autoConnect: true);
  }

  /// Create an auth_success message from relay
  static Map<String, dynamic> authSuccessMessage({
    List<Map<String, dynamic>>? instances,
  }) {
    return {
      'type': 'authSuccess',
      'data': {
        'instances': instances ??
            [
              {
                'instance_id': 'inst-1',
                'project_name': 'fspec-core',
                'online': true,
              }
            ],
      },
    };
  }

  /// Create an auth_error message from relay
  static Map<String, dynamic> authErrorMessage({
    required String code,
    String? message,
  }) {
    return {
      'type': 'authError',
      'data': {
        'code': code,
        'message': message ?? 'Authentication failed',
      },
    };
  }

  /// Create a pong message from relay
  static Map<String, dynamic> pongMessage() {
    return {
      'type': 'pong',
      'data': {'timestamp': DateTime.now().millisecondsSinceEpoch},
    };
  }
}

/// Fake WebSocket channel for testing without network
///
/// Simulates WebSocket behavior for testing auth handshake,
/// reconnection, and message handling.
class FakeWebSocketSink {
  final List<String> sentMessages = [];
  final void Function(String)? onMessage;

  FakeWebSocketSink({this.onMessage});

  void add(dynamic data) {
    final message = data as String;
    sentMessages.add(message);
    onMessage?.call(message);
  }

  Future<void> close() async {
    // No-op for tests
  }

  /// Get the last sent message as parsed JSON
  Map<String, dynamic>? get lastSentJson {
    if (sentMessages.isEmpty) return null;
    return jsonDecode(sentMessages.last) as Map<String, dynamic>;
  }

  /// Check if an auth message was sent with expected credentials
  bool hasAuthMessage({required String channelId, String? apiKey}) {
    for (final msg in sentMessages) {
      final json = jsonDecode(msg) as Map<String, dynamic>;
      if (json['type'] == 'auth') {
        final data = json['data'] as Map<String, dynamic>;
        if (data['channel_id'] == channelId) {
          if (apiKey == null || data['api_key'] == apiKey) {
            return true;
          }
        }
      }
    }
    return false;
  }
}

/// Fake WebSocket channel that simulates relay behavior
class FakeWebSocketChannel {
  final _streamController = StreamController<dynamic>.broadcast();
  final FakeWebSocketSink sink;
  final Completer<void> _readyCompleter = Completer<void>();
  bool _shouldFailConnect = false;
  String? _authResponse;

  FakeWebSocketChannel({
    bool autoReady = true,
    bool shouldFailConnect = false,
    String? authResponse,
  })  : sink = FakeWebSocketSink(),
        _shouldFailConnect = shouldFailConnect,
        _authResponse = authResponse {
    if (autoReady && !shouldFailConnect) {
      _readyCompleter.complete();
    }
  }

  Stream<dynamic> get stream => _streamController.stream;

  Future<void> get ready {
    if (_shouldFailConnect) {
      return Future.error(Exception('Connection failed'));
    }
    return _readyCompleter.future;
  }

  /// Simulate receiving a message from the relay
  void receiveMessage(Map<String, dynamic> message) {
    _streamController.add(jsonEncode(message));
  }

  /// Simulate auth success response
  void respondWithAuthSuccess({List<Map<String, dynamic>>? instances}) {
    receiveMessage(WebSocketFixtures.authSuccessMessage(instances: instances));
  }

  /// Simulate auth error response
  void respondWithAuthError({required String code, String? message}) {
    receiveMessage(WebSocketFixtures.authErrorMessage(code: code, message: message));
  }

  /// Simulate connection close
  void close() {
    _streamController.close();
  }

  /// Simulate connection error
  void simulateError(Object error) {
    _streamController.addError(error);
  }

  void dispose() {
    _streamController.close();
  }
}

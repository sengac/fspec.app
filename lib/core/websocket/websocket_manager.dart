import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';

import 'websocket_state.dart';
import 'websocket_message.dart';
import 'reconnect_strategy.dart';

export 'websocket_state.dart';
export 'websocket_message.dart';
export 'reconnect_strategy.dart';

part 'websocket_manager.g.dart';

/// WebSocket connection manager
///
/// Manages WebSocket lifecycle, authentication handshake, reconnection
/// with exponential backoff, and ping/pong heartbeat.
class WebSocketManager {
  final Logger _logger = Logger();
  final String url;
  final ReconnectStrategy _reconnectStrategy = ReconnectStrategy();

  WebSocketChannel? _channel;
  WebSocketState _state = WebSocketState.disconnected;
  Timer? _pingTimer;
  bool _authFailed = false;
  Completer<AuthResult>? _authCompleter;

  final _stateController = StreamController<WebSocketState>.broadcast();
  final _messageController = StreamController<WebSocketMessage>.broadcast();
  final _authResultController = StreamController<AuthResult>.broadcast();

  WebSocketManager({required this.url});

  /// Current connection state
  WebSocketState get state => _state;

  /// Stream of connection state changes
  Stream<WebSocketState> get stateStream => _stateController.stream;

  /// Stream of incoming messages
  Stream<WebSocketMessage> get messageStream => _messageController.stream;

  /// Stream of auth results
  Stream<AuthResult> get authResultStream => _authResultController.stream;

  /// Connect to the WebSocket server
  Future<void> connect() async {
    if (_state == WebSocketState.connecting ||
        _state == WebSocketState.authenticating ||
        _state == WebSocketState.connected) {
      return;
    }

    _updateState(WebSocketState.connecting);
    _authFailed = false;
    
    _logger.i('Connecting to WebSocket: $url');

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      await _channel!.ready;
      _reconnectStrategy.reset();

      _channel!.stream.listen(_onMessage, onError: _onError, onDone: _onDone);
      _updateState(WebSocketState.authenticating);
    } catch (e) {
      _logger.e('WebSocket connection failed', error: e);
      _updateState(WebSocketState.error);
      _scheduleReconnect();
    }
  }

  /// Connect and authenticate with the relay server
  Future<AuthResult> connectAndAuthenticate({
    required String channelId,
    String? apiKey,
  }) async {
    _authCompleter = Completer<AuthResult>();
    await connect();

    if (_state != WebSocketState.authenticating) {
      return const AuthResult.failure(
        errorCode: AuthErrorCode.unknown,
        errorMessage: 'Failed to connect to server',
      );
    }

    sendAuth(channelId: channelId, apiKey: apiKey);

    try {
      return await _authCompleter!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => const AuthResult.failure(
          errorCode: AuthErrorCode.unknown,
          errorMessage: 'Authentication timed out',
        ),
      );
    } catch (e) {
      return AuthResult.failure(
        errorCode: AuthErrorCode.unknown,
        errorMessage: e.toString(),
      );
    }
  }

  /// Send authentication message to relay
  void sendAuth({required String channelId, String? apiKey}) {
    if (_channel == null) {
      _logger.w('Cannot send auth: not connected');
      return;
    }
    final message = WebSocketMessage.auth(channelId: channelId, apiKey: apiKey);
    _channel?.sink.add(jsonEncode(message.toJson()));
  }

  /// Disconnect from the WebSocket server
  void disconnect() {
    _pingTimer?.cancel();
    _reconnectStrategy.cancel();
    _channel?.sink.close();
    _channel = null;
    _updateState(WebSocketState.disconnected);
  }

  /// Send a message
  void send(WebSocketMessage message) {
    if (_state != WebSocketState.connected) {
      _logger.w('Cannot send message: not connected');
      return;
    }
    _channel?.sink.add(jsonEncode(message.toJson()));
  }

  /// Send an fspec command
  void sendCommand({
    required String instanceId,
    required String command,
    Map<String, dynamic> args = const {},
    required String requestId,
  }) {
    send(WebSocketMessage(
      type: MessageType.command,
      instanceId: instanceId,
      requestId: requestId,
      data: {'command': command, 'args': args},
    ));
  }

  /// Send input to a session
  void sendInput({
    required String sessionId,
    required String message,
    List<Map<String, dynamic>>? images,
  }) {
    send(WebSocketMessage(
      type: MessageType.input,
      sessionId: sessionId,
      data: {'message': message, if (images != null) 'images': images},
    ));
  }

  /// Send session control command (interrupt, clear)
  void sendSessionControl({required String sessionId, required String action}) {
    send(WebSocketMessage(
      type: MessageType.sessionControl,
      sessionId: sessionId,
      data: {'action': action},
    ));
  }

  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final message = WebSocketMessage.fromJson(json);

      if (message.type == MessageType.authSuccess) {
        _handleAuthSuccess(message);
        return;
      }
      if (message.type == MessageType.authError) {
        _handleAuthError(message);
        return;
      }
      if (message.type == MessageType.pong) return;

      _messageController.add(message);
    } catch (e) {
      _logger.e('Failed to parse message', error: e);
    }
  }

  void _handleAuthSuccess(WebSocketMessage message) {
    _logger.i('Authentication successful');
    _updateState(WebSocketState.connected);
    _startPingTimer();

    final instances = message.data['instances'] as List<dynamic>?;
    final result = AuthResult.success(
      instances: instances?.cast<Map<String, dynamic>>(),
    );

    _authResultController.add(result);
    _authCompleter?.complete(result);
    _authCompleter = null;
  }

  void _handleAuthError(WebSocketMessage message) {
    final code = message.data['code'] as String?;
    final errorMessage = message.data['message'] as String?;
    _logger.e('Authentication failed: $code - $errorMessage');
    _authFailed = true;
    _updateState(WebSocketState.error);

    final errorCode = switch (code) {
      'INVALID_CHANNEL' => AuthErrorCode.invalidChannel,
      'INVALID_API_KEY' => AuthErrorCode.invalidApiKey,
      'RATE_LIMITED' => AuthErrorCode.rateLimited,
      _ => AuthErrorCode.unknown,
    };
    final result = AuthResult.failure(errorCode: errorCode, errorMessage: errorMessage);
    _authResultController.add(result);
    _authCompleter?.complete(result);
    _authCompleter = null;
    _channel?.sink.close();
    _channel = null;
  }

  void _onError(Object error) {
    _logger.e('WebSocket error', error: error);
    _updateState(WebSocketState.error);
    _scheduleReconnect();
  }

  void _onDone() {
    _logger.i('WebSocket connection closed');
    _pingTimer?.cancel();

    if (_state == WebSocketState.authenticating && _authCompleter != null) {
      _authCompleter?.complete(const AuthResult.failure(
        errorCode: AuthErrorCode.unknown,
        errorMessage: 'Connection closed during authentication',
      ));
      _authCompleter = null;
    }

    if (_state != WebSocketState.disconnected) {
      _updateState(WebSocketState.disconnected);
      _scheduleReconnect();
    }
  }

  void _updateState(WebSocketState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  void _scheduleReconnect() {
    if (_authFailed) {
      _logger.w('Not reconnecting: authentication failed');
      return;
    }

    if (_reconnectStrategy.exhausted) {
      _logger.w('Max reconnect attempts reached');
      _updateState(WebSocketState.error);
      return;
    }

    _updateState(WebSocketState.reconnecting);
    _logger.i('Scheduling reconnect (attempt ${_reconnectStrategy.attempts + 1})');
    _reconnectStrategy.schedule(connect);
  }

  void _startPingTimer() {
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_state == WebSocketState.connected) {
        send(WebSocketMessage.ping());
      }
    });
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _reconnectStrategy.dispose();
    _stateController.close();
    _messageController.close();
    _authResultController.close();
  }
}

/// Provider for WebSocket manager
@riverpod
WebSocketManager webSocketManager(Ref ref, String url) {
  final manager = WebSocketManager(url: url);
  ref.onDispose(() => manager.dispose());
  return manager;
}

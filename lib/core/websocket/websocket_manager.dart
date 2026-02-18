import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';

import '../../constants/app_constants.dart';

part 'websocket_manager.g.dart';

/// WebSocket connection state
enum WebSocketState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// WebSocket message types matching fspec protocol
enum MessageType {
  // Outbound: mobile → relay → fspec
  input,
  sessionControl,
  command,

  // Inbound: fspec → relay → mobile
  chunk,
  commandResponse,
  connected,

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

  WebSocketMessage({
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
    return WebSocketMessage(
      type: MessageType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => MessageType.error,
      ),
      data: json['data'] as Map<String, dynamic>? ?? {},
      requestId: json['request_id'] as String?,
      sessionId: json['session_id'] as String?,
      instanceId: json['instance_id'] as String?,
    );
  }
}

/// WebSocket connection manager
class WebSocketManager {
  final Logger _logger = Logger();
  final String url;

  WebSocketChannel? _channel;
  WebSocketState _state = WebSocketState.disconnected;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  final _stateController = StreamController<WebSocketState>.broadcast();
  final _messageController = StreamController<WebSocketMessage>.broadcast();

  WebSocketManager({required this.url});

  /// Current connection state
  WebSocketState get state => _state;

  /// Stream of connection state changes
  Stream<WebSocketState> get stateStream => _stateController.stream;

  /// Stream of incoming messages
  Stream<WebSocketMessage> get messageStream => _messageController.stream;

  /// Connect to the WebSocket server
  Future<void> connect() async {
    if (_state == WebSocketState.connecting ||
        _state == WebSocketState.connected) {
      return;
    }

    _updateState(WebSocketState.connecting);

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));

      await _channel!.ready;

      _updateState(WebSocketState.connected);
      _reconnectAttempts = 0;
      _startPingTimer();

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
    } catch (e) {
      _logger.e('WebSocket connection failed', error: e);
      _updateState(WebSocketState.error);
      _scheduleReconnect();
    }
  }

  /// Disconnect from the WebSocket server
  void disconnect() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
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
      data: {
        'command': command,
        'args': args,
      },
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
      data: {
        'message': message,
        'images': ?images,
      },
    ));
  }

  /// Send session control command (interrupt, clear)
  void sendSessionControl({
    required String sessionId,
    required String action,
  }) {
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

      if (message.type == MessageType.pong) {
        return; // Handled internally
      }

      _messageController.add(message);
    } catch (e) {
      _logger.e('Failed to parse message', error: e);
    }
  }

  void _onError(Object error) {
    _logger.e('WebSocket error', error: error);
    _updateState(WebSocketState.error);
    _scheduleReconnect();
  }

  void _onDone() {
    _logger.i('WebSocket connection closed');
    _pingTimer?.cancel();
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
    if (_reconnectAttempts >= AppConstants.maxReconnectAttempts) {
      _logger.w('Max reconnect attempts reached');
      return;
    }

    _updateState(WebSocketState.reconnecting);
    _reconnectAttempts++;

    final delay = Duration(
      milliseconds: (AppConstants.initialReconnectDelay.inMilliseconds *
              (1 << (_reconnectAttempts - 1)))
          .clamp(
        AppConstants.initialReconnectDelay.inMilliseconds,
        AppConstants.maxReconnectDelay.inMilliseconds,
      ),
    );

    _logger.i('Scheduling reconnect in ${delay.inSeconds}s '
        '(attempt $_reconnectAttempts)');

    _reconnectTimer = Timer(delay, connect);
  }

  void _startPingTimer() {
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_state == WebSocketState.connected) {
        send(WebSocketMessage(
          type: MessageType.ping,
          data: {'timestamp': DateTime.now().millisecondsSinceEpoch},
        ));
      }
    });
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _stateController.close();
    _messageController.close();
  }
}

/// Provider for WebSocket manager
@riverpod
WebSocketManager webSocketManager(Ref ref, String url) {
  final manager = WebSocketManager(url: url);
  ref.onDispose(() => manager.dispose());
  return manager;
}

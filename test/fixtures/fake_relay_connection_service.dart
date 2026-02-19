import 'dart:async';

import 'package:fspec_mobile/core/websocket/websocket_manager.dart';
import 'package:fspec_mobile/core/websocket/websocket_message.dart';
import 'package:fspec_mobile/features/connection/domain/repositories/connection_repository_interface.dart';
import 'package:fspec_mobile/features/connection/data/services/relay_connection_service.dart';
import 'package:fspec_mobile/features/connection/domain/models/connection.dart';

/// Fake WebSocketManager that captures sent messages
class FakeWebSocketManager extends WebSocketManager {
  final List<WebSocketMessage> sentMessages = [];
  bool _isConnected = true;
  
  FakeWebSocketManager() : super(url: 'ws://localhost:8080');
  
  @override
  WebSocketState get state => _isConnected ? WebSocketState.connected : WebSocketState.disconnected;
  
  /// Simulate a disconnect for testing
  void simulateDisconnect() {
    _isConnected = false;
  }
  
  /// Simulate a reconnect for testing
  void simulateReconnect() {
    _isConnected = true;
  }
  
  @override
  void send(WebSocketMessage message) {
    if (_isConnected) {
      sentMessages.add(message);
    }
  }
  
  @override
  void sendInput({
    required String sessionId,
    required String message,
    List<Map<String, dynamic>>? images,
  }) {
    if (!_isConnected) return;
    sentMessages.add(WebSocketMessage(
      type: MessageType.input,
      sessionId: sessionId,
      data: {'message': message, if (images != null) 'images': images},
    ));
  }
  
  @override
  void sendSessionControl({required String sessionId, required String action}) {
    if (!_isConnected) return;
    sentMessages.add(WebSocketMessage(
      type: MessageType.sessionControl,
      sessionId: sessionId,
      data: {'action': action},
    ));
  }
  
  void clearMessages() {
    sentMessages.clear();
  }
}

/// Fake RelayConnectionService that extends the real one for testing
/// 
/// Overrides connection methods to do nothing, allowing tests to run 
/// without actual WebSocket connections.
class FakeRelayConnectionService extends RelayConnectionService {
  final Map<String, FakeWebSocketManager> _fakeManagers = {};
  
  FakeRelayConnectionService(IConnectionRepository repository) : super(repository);

  @override
  Future<AuthResult> connect(Connection connection) async {
    // Create a fake manager for this connection
    _fakeManagers[connection.id] = FakeWebSocketManager();
    return const AuthResult.success();
  }

  @override
  Future<void> disconnect(String connectionId) async {
    _fakeManagers.remove(connectionId);
  }

  @override
  Future<void> autoConnectAll() async {
    // Do nothing in tests - don't auto-connect
  }
  
  @override
  WebSocketManager? getManager(String connectionId) {
    // Return the fake manager if exists, otherwise create one
    _fakeManagers[connectionId] ??= FakeWebSocketManager();
    return _fakeManagers[connectionId];
  }
  
  /// Get the fake manager for testing assertions
  FakeWebSocketManager? getFakeManager(String connectionId) {
    return _fakeManagers[connectionId];
  }
  
  /// Ensure a fake manager exists for a connection
  FakeWebSocketManager ensureFakeManager(String connectionId) {
    _fakeManagers[connectionId] ??= FakeWebSocketManager();
    return _fakeManagers[connectionId]!;
  }
}

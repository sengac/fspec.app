import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/websocket/websocket_manager.dart';
import '../../../dashboard/data/providers/dashboard_providers.dart';
import '../../domain/models/connection.dart';
import '../../domain/repositories/connection_repository_interface.dart';
import '../providers/connection_providers.dart';

part 'relay_connection_service.g.dart';

/// Service for managing relay connections
///
/// Wraps WebSocketManager and manages Connection model state via Riverpod.
/// Handles:
/// - Connection lifecycle (connect, disconnect, reconnect)
/// - Authentication handshake
/// - Status updates to Connection model
/// - Auto-connect on app launch
class RelayConnectionService {
  final IConnectionRepository _repository;
  final void Function()? _onConnectionChanged;
  final Map<String, WebSocketManager> _managers = {};
  final Map<String, StreamSubscription> _stateSubscriptions = {};

  RelayConnectionService(this._repository, [this._onConnectionChanged]);

  /// Connect to a relay server for the given connection
  Future<AuthResult> connect(Connection connection) async {
    if (connection.id.isEmpty) {
      return const AuthResult.failure(
        errorCode: AuthErrorCode.unknown,
        errorMessage: 'Invalid connection: missing ID',
      );
    }

    // Create WebSocket URL from relay URL
    final wsUrl = _buildWebSocketUrl(connection.relayUrl);
    print('🔌 Connecting to WebSocket URL: $wsUrl (from relay URL: ${connection.relayUrl})');
    
    // Get or create manager for this connection
    var manager = _managers[connection.id];
    if (manager == null) {
      manager = WebSocketManager(url: wsUrl);
      _managers[connection.id] = manager;
      
      // Subscribe to state changes
      _stateSubscriptions[connection.id] = manager.stateStream.listen(
        (state) => _onStateChanged(connection.id, state),
      );
    }

    // Update status to connecting
    await _updateConnectionStatus(connection.id, ConnectionStatus.connecting);

    // Connect and authenticate
    final result = await manager.connectAndAuthenticate(
      channelId: connection.channelId,
      apiKey: connection.apiKey,
    );

    // Update status based on result
    if (result.success) {
      await _updateConnectionStatus(connection.id, ConnectionStatus.connected);
      // Mark as auto-connect for future launches
      await _setAutoConnect(connection.id, true);
    } else {
      await _updateConnectionStatus(connection.id, ConnectionStatus.error);
    }

    return result;
  }

  /// Disconnect from a relay server
  Future<void> disconnect(String connectionId) async {
    final manager = _managers[connectionId];
    if (manager != null) {
      manager.disconnect();
      await _updateConnectionStatus(connectionId, ConnectionStatus.disconnected);
      // Clear auto-connect when manually disconnecting
      await _setAutoConnect(connectionId, false);
    }
  }

  /// Get the WebSocket manager for a connection (for sending messages)
  WebSocketManager? getManager(String connectionId) => _managers[connectionId];

  /// Get connection state
  WebSocketState? getState(String connectionId) => _managers[connectionId]?.state;

  /// Auto-connect to all connections marked for auto-connect
  Future<void> autoConnectAll() async {
    final connections = await _repository.getAll();
    final autoConnectConnections = connections.where((c) => c.autoConnect);
    
    for (final connection in autoConnectConnections) {
      // Don't await - connect in parallel
      connect(connection);
    }
  }

  void _onStateChanged(String connectionId, WebSocketState state) {
    final status = switch (state) {
      WebSocketState.disconnected => ConnectionStatus.disconnected,
      WebSocketState.connecting => ConnectionStatus.connecting,
      WebSocketState.authenticating => ConnectionStatus.connecting,
      WebSocketState.connected => ConnectionStatus.connected,
      WebSocketState.reconnecting => ConnectionStatus.connecting,
      WebSocketState.error => ConnectionStatus.error,
    };
    _updateConnectionStatus(connectionId, status);
  }

  Future<void> _updateConnectionStatus(String connectionId, ConnectionStatus status) async {
    print('📊 Updating connection $connectionId to status: $status');
    final connection = await _repository.getById(connectionId);
    if (connection != null) {
      await _repository.save(connection.copyWith(status: status));
      print('📊 Saved to repository, calling onConnectionChanged');
      _onConnectionChanged?.call();
      print('📊 onConnectionChanged called');
    } else {
      print('📊 Connection not found in repository!');
    }
  }

  Future<void> _setAutoConnect(String connectionId, bool autoConnect) async {
    final connection = await _repository.getById(connectionId);
    if (connection != null) {
      await _repository.save(connection.copyWith(autoConnect: autoConnect));
    }
  }

  String _buildWebSocketUrl(String relayUrl) {
    // Convert HTTPS URL to WSS URL
    var wsUrl = relayUrl;
    if (wsUrl.startsWith('https://')) {
      wsUrl = 'wss://${wsUrl.substring(8)}';
    } else if (wsUrl.startsWith('http://')) {
      wsUrl = 'ws://${wsUrl.substring(7)}';
    }
    
    // Append WebSocket path if not already present
    if (!wsUrl.contains('/v1/ws')) {
      wsUrl = wsUrl.endsWith('/') ? '${wsUrl}v1/ws' : '$wsUrl/v1/ws';
    }
    
    return wsUrl;
  }

  /// Dispose all managers and subscriptions
  void dispose() {
    for (final subscription in _stateSubscriptions.values) {
      subscription.cancel();
    }
    _stateSubscriptions.clear();
    
    for (final manager in _managers.values) {
      manager.dispose();
    }
    _managers.clear();
  }
}

/// Provider for RelayConnectionService
@Riverpod(keepAlive: true)
RelayConnectionService relayConnectionService(Ref ref) {
  final repository = ref.watch(connectionRepositoryProvider);
  
  // Create a callback that invalidates the connections provider when status changes
  void onConnectionChanged() {
    // Invalidate the dashboard connections provider to refresh UI
    ref.invalidate(connectionsProvider);
  }
  
  final service = RelayConnectionService(repository, onConnectionChanged);
  ref.onDispose(() => service.dispose());
  return service;
}

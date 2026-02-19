/// Feature: spec/features/kanban-board-view.feature
///
/// Providers for the Kanban board feature.
/// Manages board state and relay communication.
library;

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/websocket/websocket_manager.dart';
import '../../../connection/data/services/relay_connection_service.dart';
import '../models/board_data.dart';

part 'board_providers.g.dart';

/// Provider for board data, parameterized by instance ID
@riverpod
class BoardNotifier extends _$BoardNotifier {
  bool _isConnectionLost = false;
  StreamSubscription<WebSocketMessage>? _messageSubscription;
  StreamSubscription<WebSocketState>? _stateSubscription;
  Completer<BoardData>? _boardCompleter;

  @override
  Future<BoardData> build(String instanceId) async {
    // Clean up subscriptions when provider is disposed
    ref.onDispose(() {
      _messageSubscription?.cancel();
      _stateSubscription?.cancel();
    });

    // Get the relay service and manager
    final relayService = ref.watch(relayConnectionServiceProvider);
    final manager = relayService.getManager(instanceId);

    if (manager == null) {
      throw Exception('No connection found for instance $instanceId');
    }

    // Subscribe to connection state changes
    _stateSubscription = manager.stateStream.listen((state) {
      if (state == WebSocketState.disconnected ||
          state == WebSocketState.error) {
        _isConnectionLost = true;
        // Keep the current data but mark as disconnected
        ref.notifyListeners();
      } else if (state == WebSocketState.connected) {
        _isConnectionLost = false;
        ref.notifyListeners();
      }
    });

    // Fetch the board data
    return _fetchBoardData(manager, instanceId);
  }

  /// Whether the connection to the relay has been lost
  bool get isConnectionLost => _isConnectionLost;

  /// Fetch board data from the relay
  Future<BoardData> _fetchBoardData(
    WebSocketManager manager,
    String instanceId,
  ) async {
    _boardCompleter = Completer<BoardData>();

    // Subscribe to messages to receive the board response
    _messageSubscription?.cancel();
    _messageSubscription = manager.messageStream.listen((message) {
      if (message.type == MessageType.commandResponse &&
          message.data['command'] == 'board') {
        try {
          final boardData = BoardData.fromJson(message.data['result'] as Map<String, dynamic>);
          _boardCompleter?.complete(boardData);
          _boardCompleter = null;
        } catch (e) {
          _boardCompleter?.completeError(e);
          _boardCompleter = null;
        }
      }
    });

    // Send the board command
    final requestId = const Uuid().v4();
    manager.sendCommand(
      instanceId: instanceId,
      command: 'board',
      requestId: requestId,
    );

    // Wait for the response with timeout
    try {
      return await _boardCompleter!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Board request timed out');
        },
      );
    } catch (e) {
      _boardCompleter = null;
      rethrow;
    }
  }

  /// Refresh the board data
  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  /// Retry connection after connection loss
  Future<void> retry() async {
    _isConnectionLost = false;
    ref.invalidateSelf();
  }
}

/// Feature: spec/features/work-unit-detail-view.feature
///
/// Providers for the Work Unit Detail feature.
/// Manages work unit detail state and relay communication.
library;

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/websocket/websocket_manager.dart';
import '../../../connection/data/services/relay_connection_service.dart';
import '../models/work_unit_detail.dart';

part 'work_unit_providers.g.dart';

/// Provider for work unit detail data, parameterized by instance ID and work unit ID
@riverpod
class WorkUnitDetailNotifier extends _$WorkUnitDetailNotifier {
  bool _isConnectionLost = false;
  StreamSubscription<WebSocketMessage>? _messageSubscription;
  StreamSubscription<WebSocketState>? _stateSubscription;
  Completer<WorkUnitDetail>? _detailCompleter;

  @override
  Future<WorkUnitDetail> build(String instanceId, String workUnitId) async {
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
        ref.notifyListeners();
      } else if (state == WebSocketState.connected) {
        _isConnectionLost = false;
        ref.notifyListeners();
      }
    });

    // Fetch the work unit detail data
    return _fetchWorkUnitDetail(manager, instanceId, workUnitId);
  }

  /// Whether the connection to the relay has been lost
  bool get isConnectionLost => _isConnectionLost;

  /// Fetch work unit detail data from the relay
  Future<WorkUnitDetail> _fetchWorkUnitDetail(
    WebSocketManager manager,
    String instanceId,
    String workUnitId,
  ) async {
    _detailCompleter = Completer<WorkUnitDetail>();

    // Subscribe to messages to receive the detail response
    _messageSubscription?.cancel();
    _messageSubscription = manager.messageStream.listen((message) {
      if (message.type == MessageType.commandResponse &&
          message.data['command'] == 'show-work-unit') {
        try {
          final detailData = WorkUnitDetail.fromJson(
            message.data['result'] as Map<String, dynamic>,
          );
          _detailCompleter?.complete(detailData);
          _detailCompleter = null;
        } catch (e) {
          _detailCompleter?.completeError(e);
          _detailCompleter = null;
        }
      }
    });

    // Send the show-work-unit command
    final requestId = const Uuid().v4();
    manager.sendCommand(
      instanceId: instanceId,
      command: 'show-work-unit',
      args: {'_': [workUnitId]},
      requestId: requestId,
    );

    // Wait for the response with timeout
    try {
      return await _detailCompleter!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Work unit detail request timed out');
        },
      );
    } catch (e) {
      _detailCompleter = null;
      rethrow;
    }
  }

  /// Refresh the work unit detail data
  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  /// Retry connection after connection loss
  Future<void> retry() async {
    _isConnectionLost = false;
    ref.invalidateSelf();
  }
}

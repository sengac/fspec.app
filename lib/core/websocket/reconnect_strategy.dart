/// Exponential backoff reconnection strategy
///
/// Extracted from websocket_manager.dart for separation of concerns.
/// Handles reconnection timing and attempt counting.
library;

import 'dart:async';

import '../../constants/app_constants.dart';

/// Callback for reconnection attempt
typedef ReconnectCallback = Future<void> Function();

/// Manages exponential backoff reconnection
///
/// Calculates delays using exponential backoff: 1s, 2s, 4s, 8s, 16s, 30s (max)
/// Stops after max attempts (10 by default)
class ReconnectStrategy {
  int _attempts = 0;
  Timer? _timer;
  bool _cancelled = false;

  /// Current number of reconnection attempts
  int get attempts => _attempts;

  /// Whether max attempts have been reached
  bool get exhausted => _attempts >= AppConstants.maxReconnectAttempts;

  /// Calculate delay for next reconnection attempt
  Duration get nextDelay {
    if (_attempts == 0) {
      return AppConstants.initialReconnectDelay;
    }

    final delayMs = (AppConstants.initialReconnectDelay.inMilliseconds *
            (1 << (_attempts)))
        .clamp(
      AppConstants.initialReconnectDelay.inMilliseconds,
      AppConstants.maxReconnectDelay.inMilliseconds,
    );

    return Duration(milliseconds: delayMs);
  }

  /// Schedule a reconnection attempt
  ///
  /// Returns false if max attempts reached, true if scheduled
  bool schedule(ReconnectCallback onReconnect) {
    if (exhausted || _cancelled) {
      return false;
    }

    _attempts++;
    final delay = nextDelay;

    _timer = Timer(delay, () async {
      if (!_cancelled) {
        await onReconnect();
      }
    });

    return true;
  }

  /// Reset the reconnection counter (call after successful connection)
  void reset() {
    _attempts = 0;
    _cancelled = false;
  }

  /// Cancel any pending reconnection
  void cancel() {
    _cancelled = true;
    _timer?.cancel();
    _timer = null;
  }

  /// Dispose resources
  void dispose() {
    cancel();
  }
}

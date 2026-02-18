/// API and WebSocket endpoints
class ApiEndpoints {
  ApiEndpoints._();

  /// Base URL for the relay server
  /// Configure this in environment or settings
  static const String relayBaseUrl = 'wss://relay.fspec.dev';

  /// API version
  static const String apiVersion = 'v1';

  /// WebSocket connection endpoint
  static String get wsEndpoint => '$relayBaseUrl/$apiVersion/ws';
}

/// App-wide constants
class AppConstants {
  AppConstants._();

  /// App name
  static const String appName = 'fspec Mobile';

  /// App version
  static const String appVersion = '1.0.0';

  /// Message buffer size limit (1GB like fspec)
  static const int messageBufferLimit = 1024 * 1024 * 1024;

  /// Reconnection settings
  static const int maxReconnectAttempts = 10;
  static const Duration initialReconnectDelay = Duration(seconds: 1);
  static const Duration maxReconnectDelay = Duration(seconds: 30);

  /// UI constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const Duration animationDuration = Duration(milliseconds: 200);
}

/// Storage keys for Hive
class StorageKeys {
  StorageKeys._();

  static const String authToken = 'auth_token';
  static const String instances = 'instances';
  static const String settings = 'settings';
  static const String cachedBoardState = 'cached_board_state';
}

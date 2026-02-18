import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_error.freezed.dart';

/// Base error class for the application
@freezed
sealed class AppError with _$AppError {
  const AppError._();

  const factory AppError.network({
    required String message,
    int? statusCode,
    Object? originalError,
  }) = NetworkError;

  const factory AppError.websocket({
    required String message,
    Object? originalError,
  }) = WebSocketError;

  const factory AppError.authentication({
    required String message,
  }) = AuthenticationError;

  const factory AppError.validation({
    required String message,
    Map<String, String>? fieldErrors,
  }) = ValidationError;

  const factory AppError.cache({
    required String message,
  }) = CacheError;

  const factory AppError.unknown({
    required String message,
    Object? originalError,
  }) = UnknownError;

  /// Get a user-friendly error message
  String get userMessage => switch (this) {
        NetworkError(:final message) => 'Network error: $message',
        WebSocketError(:final message) => 'Connection error: $message',
        AuthenticationError(:final message) => 'Authentication failed: $message',
        ValidationError(:final message) => message,
        CacheError(:final message) => 'Storage error: $message',
        UnknownError(:final message) => 'An unexpected error occurred: $message',
      };

  /// Check if error is recoverable
  bool get isRecoverable => switch (this) {
        NetworkError(:final statusCode) =>
            statusCode == null || (statusCode >= 500 && statusCode < 600),
        WebSocketError() => true,
        AuthenticationError() => false,
        ValidationError() => true,
        CacheError() => true,
        UnknownError() => false,
      };
}

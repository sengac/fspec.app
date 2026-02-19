/// StreamChunk data models for session stream display.
///
/// Represents the different types of chunks received from fspec via WebSocket.
/// Each chunk type corresponds to a specific UI widget in the stream view.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'stream_chunk.freezed.dart';
part 'stream_chunk.g.dart';

/// Stream chunk types matching fspec protocol
enum StreamChunkType {
  text,
  thinking,
  toolCall,
  toolResult,
  toolProgress,
  sessionStateChange,
  userMessage,
  done,
  error,
}

/// Session state enum
enum SessionState {
  idle,
  running,
  paused,
}

/// Tool call status
enum ToolCallStatus {
  running,
  completed,
  error,
}

/// Base stream chunk class using Freezed union types
@freezed
sealed class StreamChunk with _$StreamChunk {
  const StreamChunk._();

  /// Text response from AI assistant
  const factory StreamChunk.text({
    required String content,
    @Default('') String id,
  }) = TextChunk;

  /// Thinking/reasoning content from AI
  const factory StreamChunk.thinking({
    required String content,
    @Default('') String id,
  }) = ThinkingChunk;

  /// Tool call invocation
  const factory StreamChunk.toolCall({
    required String toolCallId,
    required String name,
    required String input,
    @Default(ToolCallStatus.running) ToolCallStatus status,
  }) = ToolCallChunk;

  /// Tool execution result
  const factory StreamChunk.toolResult({
    required String toolCallId,
    required String content,
    @Default(false) bool isError,
  }) = ToolResultChunk;

  /// Streaming tool progress (e.g., bash output)
  const factory StreamChunk.toolProgress({
    required String content,
  }) = ToolProgressChunk;

  /// Session state change notification
  const factory StreamChunk.sessionStateChange({
    required SessionState state,
  }) = SessionStateChangeChunk;

  /// User message (displayed differently from AI messages)
  const factory StreamChunk.userMessage({
    required String content,
    required DateTime timestamp,
  }) = UserMessageChunk;

  /// Stream completed
  const factory StreamChunk.done() = DoneChunk;

  /// Error occurred
  const factory StreamChunk.error({
    required String message,
  }) = ErrorChunk;

  /// Parse a stream chunk from WebSocket message data
  factory StreamChunk.fromMessageData(Map<String, dynamic> data) {
    final chunkType = data['chunkType'] as String?;

    return switch (chunkType) {
      'text' => StreamChunk.text(
          content: data['content'] as String? ?? '',
          id: data['id'] as String? ?? '',
        ),
      'thinking' => StreamChunk.thinking(
          content: data['content'] as String? ?? '',
          id: data['id'] as String? ?? '',
        ),
      'toolCall' => StreamChunk.toolCall(
          toolCallId: data['id'] as String? ?? '',
          name: data['name'] as String? ?? '',
          input: data['input'] as String? ?? '',
        ),
      'toolResult' => StreamChunk.toolResult(
          toolCallId: data['toolCallId'] as String? ?? '',
          content: data['content'] as String? ?? '',
          isError: data['isError'] as bool? ?? false,
        ),
      'toolProgress' => StreamChunk.toolProgress(
          content: data['content'] as String? ?? '',
        ),
      'sessionStateChange' => StreamChunk.sessionStateChange(
          state: _parseSessionState(data['state'] as String?),
        ),
      'userMessage' => StreamChunk.userMessage(
          content: data['content'] as String? ?? '',
          timestamp: data['timestamp'] != null
              ? DateTime.parse(data['timestamp'] as String)
              : DateTime.now(),
        ),
      'done' => const StreamChunk.done(),
      'error' => StreamChunk.error(
          message: data['message'] as String? ?? 'Unknown error',
        ),
      _ => StreamChunk.error(message: 'Unknown chunk type: $chunkType'),
    };
  }

  factory StreamChunk.fromJson(Map<String, dynamic> json) =>
      _$StreamChunkFromJson(json);
}

SessionState _parseSessionState(String? state) {
  return switch (state?.toLowerCase()) {
    'running' => SessionState.running,
    'paused' => SessionState.paused,
    'idle' => SessionState.idle,
    _ => SessionState.idle,
  };
}

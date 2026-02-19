/// Session stream state model.
///
/// Holds the current state of a session stream including all chunks,
/// session state, and UI state like auto-scroll.
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'stream_chunk.dart';

part 'session_stream_state.freezed.dart';

/// Represents a tool call with its result
@freezed
abstract class ToolCallWithResult with _$ToolCallWithResult {
  const factory ToolCallWithResult({
    required ToolCallChunk toolCall,
    ToolResultChunk? result,
    @Default([]) List<String> progressOutput,
  }) = _ToolCallWithResult;

  const ToolCallWithResult._();

  /// Get the effective status considering the result
  ToolCallStatus get effectiveStatus {
    if (result == null) return toolCall.status;
    return result!.isError ? ToolCallStatus.error : ToolCallStatus.completed;
  }
}

/// Display item for the stream list - unified type for rendering
@freezed
sealed class StreamDisplayItem with _$StreamDisplayItem {
  const factory StreamDisplayItem.userMessage({
    required UserMessageChunk chunk,
  }) = UserMessageDisplayItem;

  const factory StreamDisplayItem.assistantText({
    required TextChunk chunk,
  }) = AssistantTextDisplayItem;

  const factory StreamDisplayItem.thinking({
    required List<ThinkingChunk> chunks,
    @Default(false) bool isExpanded,
  }) = ThinkingDisplayItem;

  const factory StreamDisplayItem.toolCall({
    required ToolCallWithResult toolCall,
  }) = ToolCallDisplayItem;

  const factory StreamDisplayItem.error({
    required ErrorChunk chunk,
  }) = ErrorDisplayItem;
}

/// Session stream state
@freezed
abstract class SessionStreamState with _$SessionStreamState {
  const factory SessionStreamState({
    /// Current session state (Running, Idle, Paused)
    @Default(SessionState.idle) SessionState sessionState,

    /// List of display items in order
    @Default([]) List<StreamDisplayItem> displayItems,

    /// Whether auto-scroll is enabled
    @Default(true) bool autoScrollEnabled,

    /// Connection name for header display
    @Default('') String connectionName,

    /// Session ID for header display
    @Default('') String sessionId,

    /// Whether the stream is loading
    @Default(false) bool isLoading,

    /// Error message if any
    String? errorMessage,
  }) = _SessionStreamState;

  const SessionStreamState._();

  /// Check if session is currently running
  bool get isRunning => sessionState == SessionState.running;
}

/// Session stream providers for Riverpod state management.
///
/// Provides reactive access to session stream data, subscribing to
/// WebSocketManager.messageStream and filtering for chunk messages.
library;

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/websocket/websocket_manager.dart';
import '../../../../core/websocket/websocket_message.dart';
import '../../../connection/data/providers/connection_providers.dart';
import '../../../connection/data/services/relay_connection_service.dart';
import '../models/stream_chunk.dart';
import '../models/session_stream_state.dart';

part 'session_stream_providers.g.dart';

/// Provider for session stream state
@riverpod
class SessionStream extends _$SessionStream {
  StreamSubscription<WebSocketMessage>? _subscription;
  List<ThinkingChunk> _pendingThinkingChunks = [];
  final Map<String, ToolCallWithResult> _toolCalls = {};

  @override
  SessionStreamState build(String connectionId, String sessionId) {
    // Get the WebSocket manager for this connection
    final service = ref.watch(relayConnectionServiceProvider);
    final manager = service.getManager(connectionId);

    if (manager != null) {
      _subscribeToMessages(manager, sessionId);
    }

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return SessionStreamState(
      connectionName: '', // Will be updated by screen
      sessionId: sessionId,
      sessionState: SessionState.running,
    );
  }

  /// Update connection name (called by screen when connection is loaded)
  void setConnectionName(String name) {
    state = state.copyWith(connectionName: name);
  }

  void _subscribeToMessages(WebSocketManager manager, String sessionId) {
    _subscription = manager.messageStream.listen((message) {
      // Only process chunk messages for this session
      if (message.type == MessageType.chunk &&
          message.sessionId == sessionId) {
        _processChunk(message.data);
      }
    });
  }

  void _processChunk(Map<String, dynamic> data) {
    final chunk = StreamChunk.fromMessageData(data);

    chunk.when(
      text: (content, id) => _addTextChunk(TextChunk(content: content, id: id)),
      thinking: (content, id) =>
          _addThinkingChunk(ThinkingChunk(content: content, id: id)),
      toolCall: (toolCallId, name, input, status) =>
          _addToolCall(ToolCallChunk(
        toolCallId: toolCallId,
        name: name,
        input: input,
        status: status,
      )),
      toolResult: (toolCallId, content, isError) =>
          _addToolResult(ToolResultChunk(
        toolCallId: toolCallId,
        content: content,
        isError: isError,
      )),
      toolProgress: (content) => _addToolProgress(content),
      sessionStateChange: (sessionState) =>
          _updateSessionState(sessionState),
      userMessage: (content, timestamp) =>
          _addUserMessage(UserMessageChunk(
        content: content,
        timestamp: timestamp,
      )),
      done: () => _handleDone(),
      error: (message) => _addError(ErrorChunk(message: message)),
    );
  }

  void _addTextChunk(TextChunk chunk) {
    // Flush any pending thinking chunks first
    _flushThinkingChunks();

    state = state.copyWith(
      displayItems: [
        ...state.displayItems,
        StreamDisplayItem.assistantText(chunk: chunk),
      ],
    );
  }

  void _addThinkingChunk(ThinkingChunk chunk) {
    _pendingThinkingChunks.add(chunk);

    // Update or create the thinking display item
    final items = [...state.displayItems];
    final lastIndex = items.length - 1;

    if (lastIndex >= 0 && items[lastIndex] is ThinkingDisplayItem) {
      // Update existing thinking block
      final existing = items[lastIndex] as ThinkingDisplayItem;
      items[lastIndex] = StreamDisplayItem.thinking(
        chunks: [...existing.chunks, chunk],
        isExpanded: existing.isExpanded,
      );
    } else {
      // Create new thinking block
      items.add(StreamDisplayItem.thinking(chunks: [chunk]));
    }

    state = state.copyWith(displayItems: items);
  }

  void _flushThinkingChunks() {
    _pendingThinkingChunks = [];
  }

  void _addToolCall(ToolCallChunk chunk) {
    _flushThinkingChunks();

    final toolCallWithResult = ToolCallWithResult(toolCall: chunk);
    _toolCalls[chunk.toolCallId] = toolCallWithResult;

    state = state.copyWith(
      displayItems: [
        ...state.displayItems,
        StreamDisplayItem.toolCall(toolCall: toolCallWithResult),
      ],
    );
  }

  void _addToolResult(ToolResultChunk result) {
    final existing = _toolCalls[result.toolCallId];
    if (existing == null) return;

    final updated = ToolCallWithResult(
      toolCall: existing.toolCall,
      result: result,
      progressOutput: existing.progressOutput,
    );
    _toolCalls[result.toolCallId] = updated;

    // Update the display item
    final items = state.displayItems.map((item) {
      if (item is ToolCallDisplayItem &&
          item.toolCall.toolCall.toolCallId == result.toolCallId) {
        return StreamDisplayItem.toolCall(toolCall: updated);
      }
      return item;
    }).toList();

    state = state.copyWith(displayItems: items);
  }

  void _addToolProgress(String content) {
    // Find the most recent tool call and add progress
    if (_toolCalls.isEmpty) return;

    final lastToolCallId = _toolCalls.keys.last;
    final existing = _toolCalls[lastToolCallId]!;

    final updated = ToolCallWithResult(
      toolCall: existing.toolCall,
      result: existing.result,
      progressOutput: [...existing.progressOutput, content],
    );
    _toolCalls[lastToolCallId] = updated;

    // Update the display item
    final items = state.displayItems.map((item) {
      if (item is ToolCallDisplayItem &&
          item.toolCall.toolCall.toolCallId == lastToolCallId) {
        return StreamDisplayItem.toolCall(toolCall: updated);
      }
      return item;
    }).toList();

    state = state.copyWith(displayItems: items);
  }

  void _updateSessionState(SessionState sessionState) {
    state = state.copyWith(sessionState: sessionState);
  }

  void _addUserMessage(UserMessageChunk chunk) {
    state = state.copyWith(
      displayItems: [
        ...state.displayItems,
        StreamDisplayItem.userMessage(chunk: chunk),
      ],
    );
  }

  void _handleDone() {
    _flushThinkingChunks();
    state = state.copyWith(sessionState: SessionState.idle);
  }

  void _addError(ErrorChunk chunk) {
    state = state.copyWith(
      displayItems: [
        ...state.displayItems,
        StreamDisplayItem.error(chunk: chunk),
      ],
    );
  }

  /// Toggle expansion state of a thinking block
  void toggleThinkingBlock(int index) {
    final items = [...state.displayItems];
    final item = items[index];

    if (item is ThinkingDisplayItem) {
      items[index] = StreamDisplayItem.thinking(
        chunks: item.chunks,
        isExpanded: !item.isExpanded,
      );
      state = state.copyWith(displayItems: items);
    }
  }

  /// Enable or disable auto-scroll
  void setAutoScroll(bool enabled) {
    state = state.copyWith(autoScrollEnabled: enabled);
  }

  /// Pause auto-scroll (when user manually scrolls)
  void pauseAutoScroll() {
    state = state.copyWith(autoScrollEnabled: false);
  }

  /// Resume auto-scroll (when user scrolls to bottom)
  void resumeAutoScroll() {
    state = state.copyWith(autoScrollEnabled: true);
  }
}

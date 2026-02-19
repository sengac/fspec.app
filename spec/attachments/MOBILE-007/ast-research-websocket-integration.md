# AST Research: WebSocket Integration for Session Stream Display

## Research Summary

Manual codebase analysis performed (Dart not supported by ast-grep tool).

## Key Integration Points

### 1. WebSocketManager (lib/core/websocket/websocket_manager.dart)

**Location**: `lib/core/websocket/websocket_manager.dart:22`

**Relevant Streams**:
- `messageStream` (line 46): `Stream<WebSocketMessage>` - broadcasts all incoming messages
- `stateStream` (line 43): `Stream<WebSocketState>` - connection state changes
- `authResultStream` (line 49): `Stream<AuthResult>` - authentication results

**Key Methods**:
- `sendInput()` - Send user input to session
- `sendSessionControl()` - Send interrupt/clear commands

### 2. WebSocketMessage (lib/core/websocket/websocket_message.dart)

**MessageType enum includes**:
- `chunk` - Incoming stream chunks from fspec (MessageType.chunk)
- `input` - Outbound user input
- `sessionControl` - Session control commands

**Message Structure**:
```dart
class WebSocketMessage {
  final MessageType type;
  final Map<String, dynamic> data;
  final String? sessionId;
  final String? instanceId;
}
```

### 3. RelayConnectionService (lib/features/connection/data/services/relay_connection_service.dart)

**Location**: `lib/features/connection/data/services/relay_connection_service.dart:20`

**Key Method**:
- `getManager(connectionId)` - Returns `WebSocketManager?` for a connection

## StreamChunk Types (from architecture notes)

The `chunk` message `data` field contains:
- `chunkType`: text | thinking | toolCall | toolResult | toolProgress | sessionStateChange | done | error
- Type-specific fields vary by chunk type

### Chunk Type Details

| Type | Data Fields |
|------|-------------|
| text | content |
| thinking | content |
| toolCall | id, name, input |
| toolResult | toolCallId, content, isError |
| toolProgress | content (streaming bash output) |
| sessionStateChange | state (Idle, Running, Paused) |
| done | (empty) |
| error | message |

## Recommended Implementation Approach

1. **Create StreamChunk Model Hierarchy**:
   - Base `StreamChunk` class with `fromJson` factory
   - Subclasses for each chunk type: `TextChunk`, `ThinkingChunk`, `ToolCallChunk`, etc.

2. **Create Session Stream Provider**:
   - Uses Riverpod `StreamProvider` 
   - Subscribes to `WebSocketManager.messageStream`
   - Filters for `MessageType.chunk`
   - Parses into typed `StreamChunk` models
   - Maintains list of chunks in state

3. **Widget Hierarchy**:
   - `SessionStreamScreen` - Main screen with header, list, input area
   - `StreamChunkWidget` - Factory widget that returns appropriate chunk widget
   - `UserMessageBubble` - Purple bubble for user messages
   - `ThinkingBlock` - Collapsible thinking block with ExpansionTile
   - `ToolCallCard` - Tool call with status badge and code blocks
   - `AssistantMessageBubble` - AI response bubble

4. **Auto-scroll Logic**:
   - `ScrollController` attached to ListView
   - `isAtBottom` flag to track position
   - Auto-scroll when at bottom and new chunk arrives
   - Pause auto-scroll on manual scroll up

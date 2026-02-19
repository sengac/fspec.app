# AST Research: Input Injection (MOBILE-008)

## Research Summary

Manual code analysis performed (Dart not supported by AST tool).

## Key Findings

### 1. WebSocketManager - sendInput Method (EXISTING)

**File:** `lib/core/websocket/websocket_manager.dart`
**Lines:** 153-163

```dart
/// Send input to a session
void sendInput({
  required String sessionId,
  required String message,
  List<Map<String, dynamic>>? images,
}) {
  send(WebSocketMessage(
    type: MessageType.input,
    sessionId: sessionId,
    data: {'message': message, if (images != null) 'images': images},
  ));
}
```

**Integration Point:** This method is ready to use. Input bar widget needs to call this via RelayConnectionService.

### 2. SessionStreamScreen - Current Structure

**File:** `lib/features/session/presentation/screens/session_stream_screen.dart`

Current body structure (lines 123-166):
```dart
body: Column(
  children: [
    // Auto-scroll indicator
    if (!state.autoScrollEnabled) Container(...),
    
    // Stream list
    Expanded(
      child: ListView.builder(...),
    ),
    
    // Emergency interrupt button
    EmergencyInterruptButton(...),
  ],
),
```

**Integration Point:** Input bar should be added BEFORE EmergencyInterruptButton in the Column children.

### 3. RelayConnectionService - Access Pattern

**File:** `lib/features/connection/data/services/relay_connection_service.dart`
**Lines:** 84

```dart
/// Get the WebSocket manager for a connection (for sending messages)
WebSocketManager? getManager(String connectionId) => _managers[connectionId];
```

**Integration Point:** Already used in SessionStreamScreen for interrupt. Same pattern for sendInput.

### 4. MessageType.input (EXISTING)

**File:** `lib/core/websocket/websocket_message.dart`
**Lines:** 8-10

```dart
enum MessageType {
  // Outbound: mobile → relay → fspec
  input,
  ...
}
```

**Status:** Already defined, ready to use.

### 5. UserMessageBubble (EXISTING)

**File:** `lib/features/session/presentation/widgets/user_message_bubble.dart`

**Status:** Already renders user messages in the stream. Input will appear automatically when relay echoes back.

## Widgets To Create

1. **InputBarWidget** - Main input bar with:
   - TextField for message input
   - Send button (IconButton)
   - Camera icon (IconButton)
   - Image preview row (when images attached)

2. **ImagePreviewThumbnail** - For attached image previews:
   - Thumbnail image
   - X button to remove

## Dependencies Needed

- `image_picker: ^1.0.0` - For camera/gallery access

## Integration Checklist

- [ ] Create InputBarWidget
- [ ] Create ImagePreviewThumbnail
- [ ] Add InputBarWidget to SessionStreamScreen Column
- [ ] Wire up send button to WebSocketManager.sendInput()
- [ ] Wire up camera icon to image_picker
- [ ] Handle keyboard insets (resizeToAvoidBottomInset)

# AST Research: Session Control

## Research Query
Analyzed session control patterns in the codebase for MOBILE-009.

## Findings

### 1. WebSocketManager.sendSessionControl() - Already Exists
**Location:** `lib/core/websocket/websocket_manager.dart:166-172`

```dart
/// Send session control command (interrupt, clear)
void sendSessionControl({required String sessionId, required String action}) {
  send(WebSocketMessage(
    type: MessageType.sessionControl,
    sessionId: sessionId,
    data: {'action': action},
  ));
}
```

**Status:** ✅ Ready to use - supports both 'interrupt' and 'clear' actions.

### 2. MessageType.sessionControl - Already Defined
**Location:** `lib/core/websocket/websocket_message.dart:11`

```dart
enum MessageType {
  // Outbound: mobile → relay → fspec
  input,
  sessionControl,  // <-- This is what we need
  command,
  auth,
  // ...
}
```

**Status:** ✅ Already defined in protocol.

### 3. EmergencyInterruptButton - Already Implemented
**Location:** `lib/features/session/presentation/widgets/emergency_interrupt_button.dart`

```dart
class EmergencyInterruptButton extends StatelessWidget {
  final VoidCallback? onPressed;
  // Red button with pan_tool icon and "EMERGENCY INTERRUPT" text
}
```

**Status:** ✅ Widget exists, already wired to `_handleInterrupt()` in SessionStreamScreen.

### 4. SessionStreamScreen._handleInterrupt() - Already Wired
**Location:** `lib/features/session/presentation/screens/session_stream_screen.dart:88-95`

```dart
void _handleInterrupt() {
  final service = ref.read(relayConnectionServiceProvider);
  final manager = service.getManager(widget.connectionId);
  manager?.sendSessionControl(
    sessionId: widget.sessionId,
    action: 'interrupt',
  );
}
```

**Status:** ✅ Interrupt is fully implemented.

### 5. SessionHeader - Needs Overflow Menu
**Location:** `lib/features/session/presentation/widgets/session_header.dart`

Current implementation has no overflow menu. Need to add:
- PopupMenuButton with three-dot icon
- "Clear Session" menu item
- Callback to parent for handling clear action

**Status:** ⚠️ Needs modification for clear functionality.

## Implementation Plan

1. **Interrupt functionality:** Already complete, just needs test coverage.

2. **Clear functionality:**
   - Add `onClearSession` callback to `SessionHeader`
   - Add `PopupMenuButton` with "Clear Session" option
   - Add confirmation dialog in `SessionStreamScreen`
   - Wire to `sendSessionControl(action: 'clear')`

3. **Tests needed:**
   - Test interrupt button sends correct message
   - Test clear via menu sends correct message
   - Test confirmation dialog appears and works
   - Test cancel confirmation doesn't send message

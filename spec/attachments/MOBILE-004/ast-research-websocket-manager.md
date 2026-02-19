# AST Research: WebSocket Manager Analysis

## Research Purpose
Analyze existing WebSocket infrastructure to understand what needs to be enhanced for MOBILE-004 (WebSocket Relay Connection).

## Existing Code Structure

### File: `lib/core/websocket/websocket_manager.dart`

#### WebSocketState Enum (line 13)
```dart
enum WebSocketState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}
```
✅ Already supports all states needed for connection lifecycle.

#### MessageType Enum (line 22)
```dart
enum MessageType {
  // Outbound: mobile → relay → fspec
  input,
  sessionControl,
  command,

  // Inbound: fspec → relay → mobile
  chunk,
  commandResponse,
  connected,

  // System
  error,
  ping,
  pong,
}
```
❌ **MISSING**: `auth`, `auth_success`, `auth_error` message types for authentication handshake.

#### WebSocketMessage Class (line 40)
- Has `type`, `data`, `requestId`, `sessionId`, `instanceId` fields
- Has `toJson()` and `fromJson()` methods
✅ Can be used as-is for auth messages.

#### WebSocketManager Class (line 78)
- `connect()` - establishes WebSocket connection
- `disconnect()` - closes connection
- `send()` - sends WebSocketMessage
- `_scheduleReconnect()` - exponential backoff (1s initial, 30s max, 10 attempts)
- `_startPingTimer()` - 30s ping interval

❌ **MISSING**: 
1. Auth handshake after connect (send `auth` message, wait for response)
2. Handling `auth_error` to prevent reconnect attempts
3. Integration with Connection model status

## Required Changes

### 1. Add Auth Message Types
```dart
enum MessageType {
  // ... existing types
  auth,         // ADD: mobile → relay
  authSuccess,  // ADD: relay → mobile
  authError,    // ADD: relay → mobile
}
```

### 2. Add Auth Handshake to WebSocketManager
- After `_channel.ready`, send `auth` message with `channel_id` and `api_key`
- Wait for `auth_success` or `auth_error` before setting state to `connected`
- On `auth_error`, set state to `error` and DO NOT reconnect

### 3. Create RelayConnectionService
New service that:
- Wraps WebSocketManager
- Takes Connection model as input
- Updates Connection.status based on WebSocketState
- Persists connection state via ConnectionRepository

## Integration Points

1. **InstanceCard** - needs connect/disconnect tap handler
2. **DashboardScreen** - needs to auto-connect on launch
3. **ConnectionRepository** - needs to track `wasConnected` flag for auto-connect

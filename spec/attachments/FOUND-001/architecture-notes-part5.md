# fspec Mobile Architecture Notes - Part 5: Implementation Considerations

## System Components

### 1. Relay Server (New Component)

**Responsibilities:**
- Accept WebSocket connections from mobile apps and fspec instances
- Authenticate connections
- Route messages between mobile ↔ fspec
- Buffer messages for disconnected recipients
- Track connection state

**Potential Tech Stack:**
- Rust (consistency with fspec codebase)
- Or TypeScript/Node.js (faster iteration, team familiarity)
- WebSocket library: `tokio-tungstenite` (Rust) or `ws` (Node.js)
- Deployment: Cloud Run, Fly.io, or dedicated server

### 2. fspec Bridge Enhancement

**Current state:**
- fspec already has Bridge tool for WebSocket connections
- Already buffers messages when endpoint disconnects
- Already handles `input` and `control` inbound messages

**Needed changes:**
- Handle new `command` message type
- Return `command_response` for fspec commands
- Instance identification (currently session-scoped)

### 3. Mobile App (Flutter)

**Architecture:**
- WebSocket connection management
- State management (Riverpod, Bloc, or Provider)
- Offline capability (cache last known state)
- Push notifications (when backgrounded)

**Key Screens:**
- Instance list/dashboard
- Board view (Kanban)
- Work unit detail
- Session stream view
- Input composer

## Data Flow Examples

### Querying Board (No Session)

```
Mobile                    Relay                     fspec
   |                        |                         |
   |--command(board)------->|                         |
   |                        |--command(board)-------->|
   |                        |                         |
   |                        |<--command_response------|
   |<--command_response-----|                         |
```

### Watching AI Stream

```
Mobile                    Relay                     fspec
   |                        |                         |
   |--subscribe(session)--->|                         |
   |                        |                         |--[AI running]
   |                        |<--chunk(text)-----------|
   |<--chunk(text)----------|                         |
   |                        |<--chunk(toolCall)-------|
   |<--chunk(toolCall)------|                         |
   |                        |<--chunk(done)-----------|
   |<--chunk(done)----------|                         |
```

### Sending Input While Away, Buffered

```
Mobile                    Relay                     fspec
   |                        |                         |
   |--input("fix bug")----->|                         |
   |                        |--[fspec offline]        |
   |                        |--buffer(input)          |
   |                        |                         |
   |<--ack(buffered)--------|                         |
   |                        |                         |
   |                        |        [fspec reconnects]
   |                        |--input("fix bug")------>|
   |                        |<--chunk(text)-----------|
   |<--chunk(text)----------|                         |
```

## Open Questions

1. **Instance Registration** - How does fspec instance register with relay?
   - Manual config with API key?
   - QR code pairing from mobile app?
   - Web dashboard for instance management?

2. **Message Ordering** - How to handle out-of-order delivery?
   - Sequence numbers?
   - Timestamps?
   - Causal ordering?

3. **Buffer Limits** - What limits for relay-side buffering?
   - Size limit per instance?
   - TTL for buffered messages?
   - Priority for different message types?

4. **Security** - How to secure the relay?
   - TLS for transport
   - JWT for authentication
   - Rate limiting
   - Instance ownership verification

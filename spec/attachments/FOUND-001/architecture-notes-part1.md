# fspec Mobile Architecture Notes - Part 1: Bridge System Research

## Existing Bridge System Analysis

Research conducted on the fspec bridge system in `~/projects/fspec/bridge` and `~/projects/fspec/codelet/tools/src/bridge*.rs`.

### Current Architecture

**fspec (codelet) is the WebSocket CLIENT** - it connects TO bridge endpoints using the Bridge tool.

**Bridge endpoints (like Telegram) are WebSocket SERVERS** - they receive connections from fspec.

### Connection Flow

```
fspec instance ----[connects to]----> Bridge Endpoint (e.g., Telegram)
    (client)                              (server)
```

### Current Message Types (Same WebSocket, Different `type` Fields)

**Outbound: fspec → Bridge Endpoint**

| Type | Purpose |
|------|---------|
| `connected` | Handshake with `session_id` after WebSocket connects |
| `chunk` | StreamChunk data (see StreamChunk types below) |

**Inbound: Bridge Endpoint → fspec**

| Type | Purpose |
|------|---------|
| `input` | User text + optional images → injected as AI prompt |
| `control` | Session actions: `interrupt`, `clear` |

### StreamChunk Types (from `codelet/napi/src/types.rs`)

The `chunk` message wraps these StreamChunk variants:
- `text` - Text content from assistant
- `thinking` - Reasoning/thinking content
- `toolCall` - Tool invocation (id, name, input)
- `toolResult` - Tool execution result (toolCallId, content, isError)
- `toolProgress` - Streaming bash output
- `sessionStateChange` - Internal state updates (Idle, Running, Paused, etc.)
- `userNotification` - User-facing messages with severity
- `tokenUpdate` - Token usage tracking
- `contextFillUpdate` - Context window fill percentage
- `done` - Stream completed
- `error` - Error occurred
- `fspecCommandRequest` - When AI invokes Fspec tool
- `fspecCommandResult` - Result of Fspec tool invocation
- `workUnitsUpdate` - Work units file changed

### Telegram Bridge Specifics

Located in `bridge/telegram-endpoint.ts`:
- Runs as standalone WebSocket server
- Single session at a time (rejects additional connections)
- Chat ID learned from first Telegram message or env var
- Buffers messages for Telegram API rate limiting (800ms idle flush, 3500 char limit)
- Whitelist support for authorized users

### Key Insight: Buffering Location

**Current fspec-side buffering** (in `bridge.rs`):
- fspec buffers outbound messages when WebSocket to endpoint drops
- 1GB buffer limit before connection is dropped
- Automatic reconnection with exponential backoff

**Telegram endpoint has NO reconnection buffering** - it's relatively "dumb":
- Batches messages for Telegram API rate limits
- But doesn't buffer when mobile client disconnects

This is the gap for mobile: need server-side buffering at the relay.

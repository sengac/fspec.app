# fspec Mobile Architecture Notes - Part 3: Message Protocol Design

## Why Not Extend Existing `control` Channel?

The current `control` channel supports `interrupt` and `clear`. We considered extending it for fspec commands but rejected this because:

**Current `control` channel characteristics:**
- Session-scoped (needs an active session)
- Fire-and-forget (no response expected)
- Lifecycle operations only

**fspec commands characteristics:**
- Instance-scoped (work without any session)
- Request/response pattern (need to correlate response to request)
- Query/mutation operations

These are fundamentally different concerns. Lumping them together would:
- Violate Single Responsibility Principle
- Create awkward protocol where some "control" messages need responses, some don't
- Create confusion about which messages need a session and which don't

## Clean Message Protocol Design

Distinct message types by scope and pattern:

| Type | Scope | Pattern | Direction | Purpose |
|------|-------|---------|-----------|---------|
| `input` | session | fire-and-forget | mobile→fspec | Inject AI prompt (text + optional images) |
| `session_control` | session | fire-and-forget | mobile→fspec | interrupt, clear |
| `command` | instance | request/response | mobile→fspec | fspec commands (board, show-work-unit, etc.) |
| `command_response` | instance | response | fspec→mobile | fspec command results |
| `chunk` | session | stream | fspec→mobile | StreamChunk output from AI |

### Message Format Examples

**input (session-scoped, fire-and-forget)**
```json
{
  "type": "input",
  "session_id": "uuid",
  "message": "build the login feature",
  "images": [{"data": "base64...", "media_type": "image/jpeg"}]
}
```

**session_control (session-scoped, fire-and-forget)**
```json
{
  "type": "session_control",
  "session_id": "uuid",
  "action": "interrupt"
}
```
Actions: `interrupt`, `clear`

**command (instance-scoped, request/response)**
```json
{
  "type": "command",
  "request_id": "uuid",
  "instance_id": "uuid",
  "command": "board",
  "args": {}
}
```

**command_response (instance-scoped, response)**
```json
{
  "type": "command_response",
  "request_id": "uuid",
  "success": true,
  "data": { ... },
  "error": null
}
```

**chunk (session-scoped, stream)**
```json
{
  "type": "chunk",
  "session_id": "uuid",
  "data": {
    "type": "text",
    "text": "I'll help you build that..."
  }
}
```

## Protocol Benefits

1. **Self-documenting** - message type tells you scope and pattern
2. **SRP compliant** - each message type has one job
3. **Extensible** - can add new command types without affecting other message types
4. **Type-safe** - easy to generate TypeScript/Dart types from this schema

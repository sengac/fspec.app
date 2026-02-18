# fspec Mobile Architecture Notes - Part 4: fspec Command Capabilities

## Available via `command` Message Type

The mobile app can execute any fspec command against the instance, not just view streams.

### Project Queries (Always Available)

**Board & Work Units:**
- `board` - Get Kanban board state
- `list-work-units` - List work units with filters
- `show-work-unit` - Get work unit details
- `query-work-units` - Query with complex filters

**Features & Specifications:**
- `list-features` - List feature files
- `show-feature` - Get feature file content
- `get-scenarios` - Get scenarios by tag
- `show-coverage` - Get coverage status

**Foundation & Architecture:**
- `show-foundation` - Get project foundation
- `show-foundation-event-storm` - Get domain model
- `list-epics` - List epics

### Work Unit Management (Mutating)

**Status Updates:**
- `update-work-unit-status` - Move work units through workflow

**Example Mapping (Discovery):**
- `add-rule`, `remove-rule` - Manage business rules
- `add-example`, `remove-example` - Manage examples
- `add-question`, `answer-question` - Manage questions

**Prioritization:**
- `prioritize-work-unit` - Reorder backlog

### Session-Dependent Commands

These only make sense when a session is active:
- Session metrics and token usage
- Active session list

## Mobile App Use Cases

### On-the-Go Planning (No Session Needed)
1. Review board state
2. Check work unit details
3. Reprioritize backlog
4. Review feature specifications
5. Add questions/notes to work units for later

### Monitoring Active Work (Session Streaming)
1. Watch AI output in real-time
2. Send quick inputs/clarifications
3. Interrupt if something goes wrong
4. Clear and restart if needed

### Multi-Instance Dashboard
1. See status of multiple projects at once
2. Quick-switch between instances
3. Get notified when attention needed

## Command Response Patterns

**Synchronous commands** (most queries):
- Mobile sends `command`
- Relay forwards to fspec instance
- fspec executes, returns result
- Relay forwards `command_response` to mobile

**Potential future: Subscription commands**:
- Subscribe to work unit changes
- Subscribe to board updates
- Would require additional message types

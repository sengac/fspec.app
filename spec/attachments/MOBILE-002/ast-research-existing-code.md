# AST Research: MOBILE-002 Add Connection Screen

## Feature Dependency Analysis

### MOBILE-001 → MOBILE-002 Dependency Chain

```
┌─────────────────────────────────────────────────────────────────┐
│ MOBILE-001: Connection Data Model and Local Storage (DONE)      │
│ Feature: connection-storage.feature                             │
│ Coverage: 100% (8/8 scenarios)                                  │
├─────────────────────────────────────────────────────────────────┤
│ Implementation Files:                                           │
│   • lib/features/connection/domain/models/connection.dart       │
│   • lib/features/connection/data/repositories/                  │
│     connection_repository.dart                                  │
│                                                                 │
│ Test Files:                                                     │
│   • test/features/connection/connection_storage_test.dart       │
│                                                                 │
│ Exposed Capabilities:                                           │
│   ✓ Connection.create(name, relayUrl, channelId, apiKey?)      │
│   ✓ Connection.validate() → String? (error message or null)    │
│   ✓ ConnectionRepository.save(connection) → Either<Error, Conn>│
│   ✓ ConnectionRepository.getAll() → List<Connection>           │
│   ✓ ConnectionRepository.delete(id) → Either<Error, void>      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ DEPENDS ON
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ MOBILE-002: Add Connection Screen (SPECIFYING)                  │
│ Feature: add-connection-screen.feature                          │
│ Coverage: 0% (12 scenarios, not yet tested)                     │
├─────────────────────────────────────────────────────────────────┤
│ REUSES from MOBILE-001:                                         │
│   • Connection model (domain/models/connection.dart)            │
│   • Connection.validate() for form validation                   │
│   • ConnectionRepository.save() to persist new connections      │
│                                                                 │
│ NEW Implementation Required:                                    │
│   • lib/features/connection/presentation/screens/               │
│     add_connection_screen.dart                                  │
│   • lib/features/connection/domain/services/                    │
│     qr_code_parser.dart                                         │
│   • Route registration in lib/router/app_router.dart            │
│                                                                 │
│ NEW Test Files Required:                                        │
│   • test/features/connection/add_connection_screen_test.dart    │
│   • test/features/connection/qr_code_parser_test.dart           │
└─────────────────────────────────────────────────────────────────┘
```

## Scenario-to-Implementation Mapping (MOBILE-001)

From `connection-storage.feature.coverage`:

| Scenario | Test Lines | Implementation |
|----------|------------|----------------|
| Creating connection with all required fields | 41-66 | connection.dart (full) |
| Creating connection without API key | 69-94 | connection.dart (full) |
| Creating connection with empty name fails | 97-122 | connection.dart:66-85 (validate) |
| Creating connection with http URL fails | 125-150 | connection.dart:66-85 (validate) |
| Saved connections persist | 153-167 | connection_repository.dart (full) |
| Updating connection name | 170-196 | connection_repository.dart (full) |
| Deleting connection | 199-221 | connection_repository.dart (full) |
| Listing in creation order | 224-262 | connection_repository.dart:61-82 (getAll) |

## Integration Points for MOBILE-002

### 1. Form Validation (REUSE existing)

The `Connection.validate()` method already implements:
```dart
// From connection.dart lines 69-87
String? validate() {
  if (name.trim().isEmpty) return 'Name is required';
  if (relayUrl.trim().isEmpty) return 'Relay URL is required';
  if (!relayUrl.toLowerCase().startsWith('https://')) return 'URL must use HTTPS';
  if (channelId.trim().isEmpty) return 'Channel ID is required';
  return null;
}
```

**MOBILE-002 Action**: Use this in TextFormField validators to show inline errors.

### 2. Save Flow (REUSE existing)

```dart
// From connection_repository.dart lines 42-68
Future<Either<AppError, Connection>> save(Connection connection)
```

**MOBILE-002 Action**: Call `repository.save(Connection.create(...))` on form submit.

### 3. Navigation Integration (NEW)

Current routes in `app_router.dart`:
- `/` → DashboardScreen
- `/connection` → ConnectionScreen (old, WebSocket-based)

**MOBILE-002 Action**: Add `/add-connection` route pointing to new AddConnectionScreen.

### 4. QR Code Parser (NEW)

URL scheme: `fspec://connect?n=Name&r=RelayURL&c=ChannelID&k=APIKey`

**MOBILE-002 Action**: Create `QrCodeParser` service that:
1. Validates scheme is `fspec://connect`
2. Extracts and URL-decodes parameters
3. Returns partial Connection data (even if incomplete)

## Validation Error Message Alignment

MOBILE-001 uses these error messages (from coverage):
- `"Name is required"`
- `"URL must use HTTPS"`

MOBILE-002 scenarios specify:
- `"Connection name is required"`
- `"URL must use https"`
- `"Channel ID is required"`

**Decision**: Either:
1. Update Connection.validate() messages to match UI copy, OR
2. Map repository errors to user-friendly messages in the UI layer

Recommend option 2 - keep data layer messages technical, map in presentation layer.

## Test Pattern from MOBILE-001

```dart
// @step Given I have no saved connections
final initialConnections = await repository.getAll();
expect(initialConnections, isEmpty);

// @step When I create a connection with...
final connection = ConnectionFixtures.validConnection();
final result = await repository.save(connection);

// @step Then the connection should be saved successfully
expect(result.isRight(), isTrue);
```

**MOBILE-002 Action**: Follow same pattern with `@step` comments for traceability.

## Files to Create

| File | Purpose | Depends On |
|------|---------|------------|
| `add_connection_screen.dart` | UI form + QR scanner | Connection model, Repository, QrCodeParser |
| `qr_code_parser.dart` | Parse fspec:// URLs | None (pure function) |
| `add_connection_screen_test.dart` | Widget tests | Fixtures, mock repository |
| `qr_code_parser_test.dart` | Unit tests | QR fixtures |

## Files to Modify

| File | Change |
|------|--------|
| `app_router.dart` | Add `/add-connection` route |
| `pubspec.yaml` | Add `mobile_scanner`, `permission_handler` |

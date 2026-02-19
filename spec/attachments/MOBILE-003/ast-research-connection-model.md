# AST Research: Connection Model Analysis

## Overview
Manual code analysis for MOBILE-003 (Instance Dashboard) since AST tool doesn't support Dart.

## Current Connection Model

**File:** `lib/features/connection/domain/models/connection.dart`

### Existing Fields
```dart
@freezed
abstract class Connection with _$Connection {
  const factory Connection({
    @Default('') String id,
    required String name,
    required String relayUrl,
    required String channelId,
    String? apiKey,
    @Default(ConnectionStatus.disconnected) ConnectionStatus status,
    DateTime? createdAt,
  }) = _Connection;
}
```

### Existing ConnectionStatus Enum
```dart
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}
```

## Fields to Add for Dashboard

Based on Example Mapping, need to add:

1. **lastKnownProjectName** (`String?`) - Cached project name from fspec instance
2. **lastActivityType** (new enum) - Type of last activity (aiOutput, error, status)
3. **lastActivityContent** (`String?`) - Truncated preview text
4. **lastActivityAt** (`DateTime?`) - Timestamp for relative display

### New ActivityType Enum
```dart
enum ActivityType {
  aiOutput,
  error,
  status,
}
```

## Repository Interface

**File:** `lib/features/connection/domain/repositories/connection_repository_interface.dart`

### Existing Methods
- `save(Connection)` - Save connection
- `getAll()` - Get all connections
- `getById(String)` - Get by ID
- `getByName(String)` - Get by name
- `delete(String)` - Delete connection
- `clear()` - Clear all
- `updateStatus(String, ConnectionStatus)` - Update status

### Methods to Add
- `updateActivity(String id, ActivityType type, String content)` - Update activity preview

## Provider Structure

**File:** `lib/features/connection/data/providers/connection_providers.dart`

Uses `@Riverpod(keepAlive: true)` for singleton repository instance.

### Providers to Add
- `connectionsProvider` - Stream/watch all connections
- `activeConnectionsCountProvider` - Computed count of connected instances

## Status Mapping (from Example Mapping)
| ConnectionStatus | Display Label | Indicator |
|-----------------|---------------|-----------|
| connected | ONLINE | Green |
| disconnected | OFFLINE | Red |
| connecting | SYNCING | Animated |
| error | OFFLINE | Red |

## Impact Analysis
- Connection model changes require regenerating freezed code (`flutter pub run build_runner build`)
- Repository interface changes require updating Hive implementation
- New providers needed for dashboard screen

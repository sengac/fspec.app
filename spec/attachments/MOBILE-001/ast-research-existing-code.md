# AST Research: Existing Code Analysis for MOBILE-001

## Research Objective
Analyze existing Flutter codebase to understand current architecture and integration points for the Connection data model and local storage feature.

## Files Analyzed

### 1. Feature Structure
```
lib/features/connection/
└── presentation/
    └── screens/
        └── connection_screen.dart  # Basic UI only, no data layer
```

**Finding:** The connection feature has presentation layer only. No data layer (models, repositories) exists yet.

### 2. Core Error Handling (`lib/core/error/app_error.dart`)
```dart
@freezed
sealed class AppError with _$AppError {
  const factory AppError.validation({
    required String message,
    Map<String, String>? fieldErrors,
  }) = ValidationError;
  
  const factory AppError.cache({
    required String message,
  }) = CacheError;
}
```

**Finding:** Error types already exist for validation and cache errors. We should use these for Connection validation and Hive storage errors.

### 3. Existing Connection Screen (`lib/features/connection/presentation/screens/connection_screen.dart`)
- Has form fields for URL and token
- Uses basic TextEditingController approach
- Has `// TODO: Implement actual connection logic` placeholder
- Validates URL starts with `wss://` or `ws://`

**Finding:** The existing screen expects WebSocket URLs, but our architecture uses HTTPS relay URLs. We need to update the validation.

### 4. Project Dependencies (`pubspec.yaml`)
```yaml
dependencies:
  freezed_annotation: ^3.0.0
  json_annotation: ^4.9.0
  hive_ce: ^2.11.0
  hive_ce_flutter: ^2.2.0
  uuid: ^4.5.1

dev_dependencies:
  freezed: ^3.0.0
  json_serializable: ^6.9.2
  hive_ce_generator: ^1.8.0
```

**Finding:** All required dependencies for Freezed models and Hive storage are already present.

## Integration Points

### Files to Create
1. `lib/features/connection/domain/models/connection.dart` - Freezed model
2. `lib/features/connection/data/repositories/connection_repository.dart` - Repository
3. `lib/features/connection/data/providers/connection_providers.dart` - Riverpod providers

### Files to Modify
1. `lib/main.dart` - Initialize Hive storage
2. `lib/features/connection/presentation/screens/connection_screen.dart` - Use repository

## Recommendations
1. Follow existing Freezed pattern from `AppError`
2. Use `hive_ce` for encrypted local storage
3. Create Riverpod providers for dependency injection
4. Status enum: `disconnected`, `connecting`, `connected`, `error`

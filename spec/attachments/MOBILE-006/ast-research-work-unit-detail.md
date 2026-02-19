# AST Research: Work Unit Detail View

## Research Date: 2026-02-19
## Work Unit: MOBILE-006

---

## 1. Existing WorkUnit Model Analysis

**File:** `lib/features/board/data/models/board_data.dart`

```dart
@freezed
abstract class WorkUnit with _$WorkUnit {
  const factory WorkUnit({
    required String id,
    required String title,
    required WorkUnitType type,
    int? estimate,
  }) = _WorkUnit;
}
```

**Finding:** Current model is minimal - only supports board card display. Need a detailed model for the detail view.

---

## 2. WebSocket Command Pattern

**File:** `lib/features/board/data/providers/board_providers.dart`

Pattern for fetching data via WebSocket relay:

```dart
// 1. Subscribe to message stream
_messageSubscription = manager.messageStream.listen((message) {
  if (message.type == MessageType.commandResponse &&
      message.data['command'] == 'board') {
    final boardData = BoardData.fromJson(message.data['result']);
    _boardCompleter?.complete(boardData);
  }
});

// 2. Send command with request ID
manager.sendCommand(
  instanceId: instanceId,
  command: 'board',
  requestId: requestId,
);

// 3. Wait for response with timeout
return await _boardCompleter!.future.timeout(Duration(seconds: 10));
```

**Recommendation:** Follow same pattern for `show-work-unit` command.

---

## 3. WebSocket Message Protocol

**File:** `lib/core/websocket/websocket_message.dart`

Message types:
- `command` - Outbound request
- `commandResponse` - Inbound response

Response structure expected:
```json
{
  "type": "commandResponse",
  "data": {
    "command": "show-work-unit",
    "result": { /* work unit detail JSON */ }
  }
}
```

---

## 4. Color Theming Pattern

**File:** `lib/features/board/presentation/widgets/work_unit_card.dart`

Type colors:
```dart
Color get _typeColor {
  switch (workUnit.type) {
    case WorkUnitType.story: return Colors.blue;
    case WorkUnitType.bug: return Colors.orange;
    case WorkUnitType.task: return Colors.green;
  }
}
```

Type icons:
```dart
IconData get _typeIcon {
  switch (workUnit.type) {
    case WorkUnitType.story: return Icons.folder_outlined;
    case WorkUnitType.bug: return Icons.bug_report_outlined;
    case WorkUnitType.task: return Icons.check_box_outlined;
  }
}
```

---

## 5. Expected show-work-unit Response Structure

Based on fspec command output, the detail model should include:

```dart
@freezed
abstract class WorkUnitDetail with _$WorkUnitDetail {
  const factory WorkUnitDetail({
    required String id,
    required String title,
    required WorkUnitType type,
    required String status,
    String? description,
    String? epic,
    int? estimate,
    UserStory? userStory,
    @Default([]) List<Rule> rules,
    @Default([]) List<Example> examples,
    @Default([]) List<Question> questions,
    @Default([]) List<String> architectureNotes,
    @Default([]) List<String> dependsOn,
    @Default([]) List<String> linkedFeatures,
  }) = _WorkUnitDetail;
}

@freezed
abstract class UserStory with _$UserStory {
  const factory UserStory({
    required String role,
    required String action,
    required String benefit,
  }) = _UserStory;
}

@freezed
abstract class Rule with _$Rule {
  const factory Rule({
    required int index,
    required String text,
    @Default(false) bool deleted,
  }) = _Rule;
}

@freezed
abstract class Example with _$Example {
  const factory Example({
    required int index,
    required String text,
    String? type, // "HAPPY PATH", "EDGE CASE", etc.
    @Default(false) bool deleted,
  }) = _Example;
}

@freezed
abstract class Question with _$Question {
  const factory Question({
    required int index,
    required String text,
    String? answer,
    @Default(false) bool deleted,
  }) = _Question;
}
```

---

## 6. Router Configuration

**File:** `lib/router/app_router.dart`

Route already defined:
```dart
static const String workUnit = '/work-unit/:instanceId/:workUnitId';
```

Need to implement screen builder.

---

## 7. Integration Points

1. **Navigation:** From `WorkUnitCard.onTap` → push to `/work-unit/:instanceId/:workUnitId`
2. **Data fetching:** Create `WorkUnitDetailNotifier` similar to `BoardNotifier`
3. **Styling:** Reuse color getters from `WorkUnitCard` or extract to shared utility

---

## 8. Files to Create

| File | Purpose |
|------|---------|
| `lib/features/work_unit/data/models/work_unit_detail.dart` | Detail data model |
| `lib/features/work_unit/data/providers/work_unit_providers.dart` | Data fetching provider |
| `lib/features/work_unit/presentation/screens/work_unit_detail_screen.dart` | Main screen |
| `lib/features/work_unit/presentation/widgets/user_story_card.dart` | User story display |
| `lib/features/work_unit/presentation/widgets/rule_card.dart` | Blue rule card |
| `lib/features/work_unit/presentation/widgets/example_card.dart` | Green example card |
| `lib/features/work_unit/presentation/widgets/question_card.dart` | Red question card |
| `lib/features/work_unit/presentation/widgets/section_header.dart` | Section with count badge |

---

## 9. Test File Structure

```
test/features/work_unit/
├── data/
│   └── models/
│       └── work_unit_detail_test.dart
├── presentation/
│   └── screens/
│       └── work_unit_detail_screen_test.dart
```

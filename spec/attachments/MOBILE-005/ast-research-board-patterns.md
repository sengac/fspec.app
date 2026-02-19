# AST Research: Kanban Board View Patterns

## Work Unit: MOBILE-005

## Research Date: 2026-02-19

## 1. Screen Widget Pattern (from DashboardScreen)

**File:** `lib/features/dashboard/presentation/screens/dashboard_screen.dart`

```dart
class DashboardScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-trigger actions on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(relayConnectionServiceProvider).autoConnectAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(...),
      body: const _DashboardBody(),
      floatingActionButton: FloatingActionButton.extended(...),
    );
  }
}
```

**Pattern:** Use `ConsumerStatefulWidget` when needing `initState` for setup actions.

## 2. Async Data Pattern (from _DashboardBody)

```dart
class _DashboardBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(connectionsProvider);

    return connectionsAsync.when(
      data: (connections) {
        if (connections.isEmpty) {
          return const _EmptyState();
        }
        return CustomScrollView(...);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
```

**Pattern:** Use `.when()` for AsyncValue to handle loading/error/data states.

## 3. Provider Pattern (from dashboard_providers.dart)

**File:** `lib/features/dashboard/data/providers/dashboard_providers.dart`

```dart
@riverpod
Future<List<Connection>> connections(Ref ref) async {
  final repository = ref.watch(connectionRepositoryProvider);
  return repository.getAll();
}

@riverpod
Future<int> activeInstancesCount(Ref ref) async {
  final connectionsList = await ref.watch(connectionsProvider.future);
  return connectionsList
      .where((c) => c.status == ConnectionStatus.connected)
      .length;
}
```

**Pattern:** Use `@riverpod` annotation for code-generated providers.

## 4. WebSocket Manager Pattern

**File:** `lib/core/websocket/websocket_manager.dart`

```dart
/// Send an fspec command
void sendCommand({
  required String instanceId,
  required String command,
  Map<String, dynamic> args = const {},
  required String requestId,
}) {
  send(WebSocketMessage(
    type: MessageType.command,
    instanceId: instanceId,
    requestId: requestId,
    data: {'command': command, 'args': args},
  ));
}

/// Stream of incoming messages
Stream<WebSocketMessage> get messageStream => _messageController.stream;
```

**Usage for Board:**
```dart
// Send board command
manager.sendCommand(
  instanceId: connection.id,
  command: 'board',
  requestId: uuid.v4(),
);

// Listen for response
manager.messageStream.listen((message) {
  if (message.type == MessageType.commandResponse) {
    // Parse board data from message.data
  }
});
```

## 5. RelayConnectionService Pattern

**File:** `lib/features/connection/data/services/relay_connection_service.dart`

```dart
/// Get the WebSocket manager for a connection (for sending messages)
WebSocketManager? getManager(String connectionId) => _managers[connectionId];
```

**Usage:** Get the manager from the service, then use it to send commands.

## 6. Router Pattern

**File:** `lib/router/app_router.dart`

```dart
class RoutePaths {
  static const String board = '/board/:instanceId';
  static const String workUnit = '/work-unit/:instanceId/:workUnitId';
}

GoRoute(
  path: RoutePaths.board,
  name: RouteNames.board,
  builder: (context, state) => BoardScreen(
    instanceId: state.pathParameters['instanceId']!,
  ),
),
```

**Note:** Board route already defined, needs implementation.

## 7. Test Pattern

**File:** `test/features/dashboard/instance_dashboard_test.dart`

```dart
/// Feature: spec/features/instance-dashboard.feature
library;

void main() {
  late InMemoryConnectionRepository repository;
  late FakeRelayConnectionService fakeService;

  setUp(() {
    repository = InMemoryConnectionRepository();
    fakeService = FakeRelayConnectionService(repository);
  });

  Widget createTestWidget({Widget? child, GoRouter? router}) {
    return ProviderScope(
      overrides: [
        connectionRepositoryProvider.overrideWithValue(repository),
        relayConnectionServiceProvider.overrideWithValue(fakeService),
      ],
      child: MaterialApp.router(routerConfig: testRouter),
    );
  }

  group('Feature: Instance Dashboard', () {
    group('Scenario: Dashboard displays multiple connections', () {
      testWidgets('should display connections', (tester) async {
        // @step Given I have the following connections configured:
        for (final connection in DashboardFixtures.multipleConnections()) {
          await repository.save(connection);
        }

        // @step When I open the dashboard
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // @step Then I should see 3 instance cards
        expect(find.byKey(const Key('instance_card')), findsNWidgets(3));
      });
    });
  });
}
```

**Pattern:** 
- Feature header comment
- Group per scenario
- `@step` comments for each Gherkin step
- Fixtures for test data
- Provider overrides for DI

## 8. Fixture Pattern

**File:** `test/fixtures/dashboard_fixtures.dart`

```dart
class DashboardFixtures {
  static Connection onlineConnection({
    String name = 'MacBook Pro',
    String projectName = 'fspec-core',
    String channelId = 'channel-1',
  }) {
    return Connection.create(
      name: name,
      relayUrl: 'https://relay.fspec.dev',
      channelId: channelId,
    ).copyWith(
      status: ConnectionStatus.connected,
      lastKnownProjectName: projectName,
    );
  }
  
  static List<Connection> multipleConnections() { ... }
}
```

## 9. Card Widget Pattern (from InstanceCard)

**File:** `lib/features/dashboard/presentation/widgets/instance_card.dart`

```dart
class InstanceCard extends StatelessWidget {
  final Connection connection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('instance_card'),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(...),
        ),
      ),
    );
  }
}
```

**Pattern:** 
- Use `Key` for test identification
- Wrap with `InkWell` for tap handling
- Pass callbacks via constructor

## 10. Relevant Files for Board Implementation

### New Files to Create:
- `lib/features/board/presentation/screens/board_screen.dart`
- `lib/features/board/presentation/widgets/work_unit_card.dart`
- `lib/features/board/presentation/widgets/board_column.dart`
- `lib/features/board/data/providers/board_providers.dart`
- `lib/features/board/data/models/board_data.dart`
- `test/features/board/kanban_board_test.dart`
- `test/fixtures/board_fixtures.dart`

### Files to Modify:
- `lib/router/app_router.dart` - Uncomment and complete board route

## Summary

The Kanban Board should follow these patterns:
1. `BoardScreen` as `ConsumerStatefulWidget` to trigger board fetch on mount
2. `BoardNotifier` as `@riverpod` AsyncNotifier to manage board state
3. `PageView` for horizontal column swiping
4. `WorkUnitCard` widget with `Key` for testing
5. Use `relayConnectionService.getManager()` to send 'board' command
6. Listen to `messageStream` for response parsing
7. Test with fixtures and provider overrides

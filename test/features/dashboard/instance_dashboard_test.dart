/// Feature: spec/features/instance-dashboard.feature
///
/// Tests for Instance Dashboard screen.
/// Validates connection list display, status indicators, activity previews,
/// and navigation to instance details.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fspec_mobile/features/connection/data/providers/connection_providers.dart';
import 'package:fspec_mobile/features/connection/data/services/relay_connection_service.dart';
import 'package:fspec_mobile/features/connection/domain/models/connection.dart';
import 'package:fspec_mobile/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:go_router/go_router.dart';

import '../../fixtures/dashboard_fixtures.dart';
import '../../fixtures/in_memory_connection_repository.dart';
import '../../fixtures/fake_relay_connection_service.dart';

void main() {
  late InMemoryConnectionRepository repository;
  late FakeRelayConnectionService fakeService;

  setUp(() {
    repository = InMemoryConnectionRepository();
    fakeService = FakeRelayConnectionService(repository);
  });

  Widget createTestWidget({Widget? child, GoRouter? router}) {
    final testRouter = router ??
        GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => child ?? const DashboardScreen(),
            ),
            GoRoute(
              path: '/connection',
              builder: (context, state) =>
                  const Scaffold(body: Text('Add Connection')),
            ),
            GoRoute(
              path: '/instance/:id',
              builder: (context, state) => Scaffold(
                key: const Key('instance_detail_screen'),
                body: Text('Instance Detail: ${state.pathParameters['id']}'),
              ),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) =>
                  const Scaffold(body: Text('Settings')),
            ),
          ],
        );

    return ProviderScope(
      overrides: [
        connectionRepositoryProvider.overrideWithValue(repository),
        relayConnectionServiceProvider.overrideWithValue(fakeService),
      ],
      child: MaterialApp.router(
        routerConfig: testRouter,
      ),
    );
  }

  group('Feature: Instance Dashboard', () {
    group('Scenario: Dashboard displays multiple connections with status indicators', () {
      testWidgets('should display connections with correct status colors', (tester) async {
        // @step Given I have the following connections configured:
        for (final connection in DashboardFixtures.multipleConnections()) {
          await repository.save(connection);
        }

        // @step When I open the dashboard
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // @step Then I should see 3 instance cards
        expect(find.byKey(const Key('instance_card')), findsNWidgets(3));

        // @step And "MacBook Pro" should show "ONLINE" status with a green indicator
        expect(find.text('MacBook Pro'), findsOneWidget);
        expect(find.text('ONLINE'), findsWidgets);

        // @step And "Ubuntu Server" should show "OFFLINE" status with a red indicator
        expect(find.text('Ubuntu Server'), findsOneWidget);
        expect(find.text('OFFLINE'), findsOneWidget);

        // @step And "Development VM" should show "ONLINE" status with a green indicator
        expect(find.text('Development VM'), findsOneWidget);
      });
    });

    group('Scenario: Instance card shows AI output activity preview', () {
      testWidgets('should display AI output preview with Disconnect button', (tester) async {
        // @step Given I have a connection "MacBook Pro" with status "connected"
        // @step And the connection has activity type "aiOutput"
        // @step And the activity content is "Optimized 3 functions in core module. Reduced latency by 12%..."
        await repository.save(DashboardFixtures.connectionWithAiOutput(
          name: 'MacBook Pro',
          content: 'Optimized 3 functions in core module. Reduced latency by 12%...',
        ));

        // @step When I open the dashboard
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // @step Then the "MacBook Pro" card should show "AI OUTPUT SNIPPET" label
        expect(find.text('AI OUTPUT SNIPPET'), findsOneWidget);

        // @step And the card should display the activity preview text
        expect(find.textContaining('Optimized 3 functions'), findsOneWidget);

        // @step And the card should have a "Disconnect" action button (connected state)
        expect(find.text('Disconnect'), findsOneWidget);
      });
    });

    group('Scenario: Instance card shows error activity preview', () {
      testWidgets('should display error preview with Retry Connection button', (tester) async {
        // @step Given I have a connection "Ubuntu Server" with status "error"
        // @step And the connection has activity type "error"
        // @step And the activity content is "Build failed at step 4: dependency conflict..."
        await repository.save(DashboardFixtures.errorConnection(
          name: 'Ubuntu Server',
          errorContent: 'Build failed at step 4: dependency conflict...',
        ));

        // @step When I open the dashboard
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // @step Then the "Ubuntu Server" card should show "CRITICAL FAILURE" label in red
        expect(find.text('CRITICAL FAILURE'), findsOneWidget);

        // @step And the card should display the error preview text
        expect(find.textContaining('Build failed at step 4'), findsOneWidget);

        // @step And the card should have a "Retry Connection" action button (error state)
        expect(find.text('Retry Connection'), findsOneWidget);
      });
    });

    group('Scenario: Empty state when no connections configured', () {
      testWidgets('should show empty state with add connection prompt', (tester) async {
        // @step Given I have no connections configured
        // (repository is empty by default)

        // @step When I open the dashboard
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // @step Then I should see an empty state message
        expect(find.byKey(const Key('empty_state')), findsOneWidget);

        // @step And I should see a prompt to add my first connection
        expect(find.text('No fspec instances connected'), findsOneWidget);
      });
    });

    group('Scenario: Navigate to instance detail on card tap', () {
      testWidgets('should navigate to detail view when card is tapped', (tester) async {
        // @step Given I have a connection "MacBook Pro" with status "connected"
        await repository.save(DashboardFixtures.onlineConnection(name: 'MacBook Pro'));

        // @step When I open the dashboard
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // @step And I tap on the "MacBook Pro" card
        await tester.tap(find.text('MacBook Pro'));
        await tester.pumpAndSettle();

        // @step Then I should navigate to the instance detail view for "MacBook Pro"
        expect(find.byKey(const Key('instance_detail_screen')), findsOneWidget);
      });
    });

    group('Scenario: Dashboard shows active instances summary stat', () {
      testWidgets('should display correct active instances count', (tester) async {
        // @step Given I have the following connections configured:
        for (final connection in DashboardFixtures.multipleConnections()) {
          await repository.save(connection);
        }

        // @step When I open the dashboard
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // @step Then I should see "2" as the active instances count
        expect(find.byKey(const Key('active_instances_stat')), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
      });
    });

    group('Scenario: Instance card shows SYNCING status for connecting connection', () {
      testWidgets('should display SYNCING status with orange indicator', (tester) async {
        // @step Given I have a connection "Staging Server" with status "connecting"
        await repository.save(DashboardFixtures.syncingConnection(name: 'Staging Server'));

        // @step When I open the dashboard
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // @step Then "Staging Server" should show "SYNCING" status with an orange indicator
        expect(find.text('Staging Server'), findsOneWidget);
        expect(find.text('SYNCING'), findsOneWidget);
      });
    });

    group('Scenario: Instance card displays project name', () {
      testWidgets('should display project name on card', (tester) async {
        // @step Given I have a connection "MacBook Pro" with project name "fspec-core"
        await repository.save(DashboardFixtures.onlineConnection(
          name: 'MacBook Pro',
          projectName: 'fspec-core',
        ));

        // @step When I open the dashboard
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // @step Then the "MacBook Pro" card should display "fspec-core" as the project name
        expect(find.text('MacBook Pro'), findsOneWidget);
        expect(find.text('fspec-core'), findsOneWidget);
      });
    });
  });
}

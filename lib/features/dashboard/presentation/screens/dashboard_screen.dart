import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_router.dart';
import '../../../connection/domain/models/connection.dart';
import '../../../connection/data/services/relay_connection_service.dart';
import '../../data/providers/dashboard_providers.dart';
import '../widgets/instance_card.dart';

/// Dashboard screen - shows connected fspec instances
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-connect on app launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(relayConnectionServiceProvider).autoConnectAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('fspec Mobile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => context.push(RoutePaths.settings),
          ),
        ],
      ),
      body: const _DashboardBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.addConnection),
        icon: const Icon(Icons.add),
        label: const Text('Add Connection'),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(connectionsProvider);
    final activeCountAsync = ref.watch(activeInstancesCountProvider);

    return connectionsAsync.when(
      data: (connections) {
        if (connections.isEmpty) {
          return const _EmptyState();
        }

        return CustomScrollView(
          slivers: [
            // Stats header
            SliverToBoxAdapter(
              child: _StatsHeader(
                activeCount: activeCountAsync.value ?? 0,
              ),
            ),

            // Section header
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CONNECTED INSTANCES',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Auto-refreshing',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ),
            ),

            // Instance cards list
            SliverPadding(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final connection = connections[index];
                    return InstanceCard(
                      connection: connection,
                      onTap: () => _navigateToDetail(context, connection),
                      onConnect: () => _connect(context, ref, connection),
                      onDisconnect: () => _disconnect(ref, connection),
                      onMoreOptions: () => _editConnection(context, connection),
                    );
                  },
                  childCount: connections.length,
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, Connection connection) {
    // Navigate to board screen for this connection/instance
    context.push('/board/${connection.id}');
  }

  Future<void> _connect(BuildContext context, WidgetRef ref, Connection connection) async {
    final service = ref.read(relayConnectionServiceProvider);
    final result = await service.connect(connection);
    if (!result.success && context.mounted) {
      _showErrorSnackbar(context, result);
    }
  }

  Future<void> _disconnect(WidgetRef ref, Connection connection) async {
    final service = ref.read(relayConnectionServiceProvider);
    await service.disconnect(connection.id);
  }

  void _editConnection(BuildContext context, Connection connection) {
    context.push('/connection/${connection.id}');
  }

  void _showErrorSnackbar(BuildContext context, dynamic result) {
    final message = switch (result.errorCode) {
      _ when result.errorCode.toString().contains('invalidChannel') => 'Channel not found',
      _ when result.errorCode.toString().contains('invalidApiKey') => 'Authentication failed',
      _ when result.errorCode.toString().contains('rateLimited') => 'Rate limited - try again later',
      _ => result.errorMessage ?? 'Connection failed',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.activeCount});

  final int activeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              key: const Key('active_instances_stat'),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACTIVE INSTANCES',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$activeCount',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('empty_state'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.devices_other,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            'No fspec instances connected',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Connect to a relay server to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => context.push(RoutePaths.addConnection),
            icon: const Icon(Icons.add),
            label: const Text('Add Connection'),
          ),
        ],
      ),
    );
  }
}

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../connection/data/providers/connection_providers.dart';
import '../../../connection/domain/models/connection.dart';

part 'dashboard_providers.g.dart';

/// Provider that watches all connections from the repository
@riverpod
Future<List<Connection>> connections(Ref ref) async {
  final repository = ref.watch(connectionRepositoryProvider);
  return repository.getAll();
}

/// Provider that computes the count of active (connected) instances
@riverpod
Future<int> activeInstancesCount(Ref ref) async {
  final connectionsList = await ref.watch(connectionsProvider.future);
  return connectionsList
      .where((c) => c.status == ConnectionStatus.connected)
      .length;
}

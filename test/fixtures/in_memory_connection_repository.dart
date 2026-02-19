/// In-Memory Connection Repository
///
/// Test implementation of IConnectionRepository that stores connections
/// in memory. Used for testing to avoid Hive initialization complexity
/// and to verify actual behavior rather than mock interactions.
library;

import 'package:fpdart/fpdart.dart';
import 'package:fspec_mobile/core/error/app_error.dart';
import 'package:fspec_mobile/features/connection/domain/models/connection.dart';
import 'package:fspec_mobile/features/connection/domain/repositories/connection_repository_interface.dart';
import 'package:uuid/uuid.dart';

/// In-memory implementation of IConnectionRepository for testing
///
/// Provides a fully functional repository that stores data in memory.
/// This allows tests to verify actual behavior rather than mock interactions.
class InMemoryConnectionRepository implements IConnectionRepository {
  final Map<String, Connection> _connections = {};

  /// Get all stored connections (for test assertions)
  List<Connection> get storedConnections => _connections.values.toList();

  /// Check if a connection exists with the given name
  bool hasConnectionNamed(String name) {
    return _connections.values.any((c) => c.name == name);
  }

  @override
  Future<Either<AppError, Connection>> save(Connection connection) async {
    // Validate the connection
    final validationError = connection.validate();
    if (validationError != null) {
      return Left(AppError.validation(message: validationError));
    }

    // Generate ID if not present
    Connection toSave = connection;
    if (connection.id.isEmpty) {
      toSave = connection.copyWith(
        id: const Uuid().v4(),
        createdAt: connection.createdAt ?? DateTime.now(),
      );
    }

    // Store in memory
    _connections[toSave.id] = toSave;

    return Right(toSave);
  }

  @override
  Future<List<Connection>> getAll() async {
    final connections = _connections.values.toList();

    // Sort by creation date, handling nulls
    connections.sort((a, b) {
      final aTime = a.createdAt ?? DateTime(1970);
      final bTime = b.createdAt ?? DateTime(1970);
      return aTime.compareTo(bTime);
    });

    return connections;
  }

  @override
  Future<Connection?> getById(String id) async {
    return _connections[id];
  }

  @override
  Future<Connection?> getByName(String name) async {
    return _connections.values.where((c) => c.name == name).firstOrNull;
  }

  @override
  Future<Either<AppError, void>> delete(String id) async {
    _connections.remove(id);
    return const Right(null);
  }

  @override
  Future<void> clear() async {
    _connections.clear();
  }

  @override
  Future<Either<AppError, Connection>> updateStatus(
    String id,
    ConnectionStatus status,
  ) async {
    final connection = _connections[id];

    if (connection == null) {
      return Left(AppError.validation(message: 'Connection not found'));
    }

    final updated = connection.copyWith(status: status);
    _connections[id] = updated;

    return Right(updated);
  }

  @override
  Future<Either<AppError, Connection>> updateActivity(
    String id,
    ActivityType type,
    String content,
  ) async {
    final connection = _connections[id];

    if (connection == null) {
      return Left(AppError.validation(message: 'Connection not found'));
    }

    final updated = connection.copyWith(
      lastActivityType: type,
      lastActivityContent: content,
      lastActivityAt: DateTime.now(),
    );
    _connections[id] = updated;

    return Right(updated);
  }

  @override
  Future<Either<AppError, Connection>> updateProjectName(
    String id,
    String projectName,
  ) async {
    final connection = _connections[id];

    if (connection == null) {
      return Left(AppError.validation(message: 'Connection not found'));
    }

    final updated = connection.copyWith(lastKnownProjectName: projectName);
    _connections[id] = updated;

    return Right(updated);
  }
}

/// Connection Repository Interface
///
/// Abstract interface for connection persistence.
/// Allows for multiple implementations (Hive, In-Memory, etc.)
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/app_error.dart';
import '../models/connection.dart';

/// Abstract interface for Connection persistence operations
abstract class IConnectionRepository {
  /// Save a connection to storage
  ///
  /// If the connection has no ID, one will be generated.
  /// Validates the connection before saving.
  Future<Either<AppError, Connection>> save(Connection connection);

  /// Get all saved connections
  ///
  /// Returns connections sorted by creation date (oldest first)
  Future<List<Connection>> getAll();

  /// Get a connection by ID
  Future<Connection?> getById(String id);

  /// Get a connection by name
  Future<Connection?> getByName(String name);

  /// Delete a connection by ID
  Future<Either<AppError, void>> delete(String id);

  /// Clear all connections
  Future<void> clear();

  /// Update connection status
  Future<Either<AppError, Connection>> updateStatus(
    String id,
    ConnectionStatus status,
  );

  /// Update connection activity preview
  Future<Either<AppError, Connection>> updateActivity(
    String id,
    ActivityType type,
    String content,
  );

  /// Update connection's last known project name
  Future<Either<AppError, Connection>> updateProjectName(
    String id,
    String projectName,
  );
}

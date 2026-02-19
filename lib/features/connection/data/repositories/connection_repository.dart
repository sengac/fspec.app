import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/app_error.dart';
import '../../domain/models/connection.dart';
import '../../domain/repositories/connection_repository_interface.dart';

/// Repository for managing Connection persistence
///
/// Uses Hive for local storage with JSON serialization.
/// All operations return Either types for explicit error handling.
class ConnectionRepository implements IConnectionRepository {
  static const String _boxName = 'connections';
  Box<String>? _box;

  /// Get or open the Hive box for connections
  Future<Box<String>> _getBox() async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }

    _box = await Hive.openBox<String>(_boxName);
    return _box!;
  }

  /// Convert Connection to JSON string for storage
  String _toJson(Connection connection) {
    return jsonEncode(connection.toJson());
  }

  /// Convert JSON string from storage to Connection
  Connection _fromJson(String json) {
    return Connection.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  /// Save a connection to storage
  ///
  /// If the connection has no ID, one will be generated.
  /// Validates the connection before saving.
  @override
  Future<Either<AppError, Connection>> save(Connection connection) async {
    try {
      // Validate the connection
      final validationError = connection.validate();
      if (validationError != null) {
        return Left(AppError.validation(message: validationError));
      }

      final box = await _getBox();

      // Generate ID if not present
      Connection toSave = connection;
      if (connection.id.isEmpty) {
        toSave = connection.copyWith(
          id: const Uuid().v4(),
          createdAt: connection.createdAt ?? DateTime.now(),
        );
      }

      // Save to Hive using ID as key
      await box.put(toSave.id, _toJson(toSave));

      return Right(toSave);
    } catch (e) {
      return Left(AppError.cache(message: 'Failed to save connection: $e'));
    }
  }

  /// Get all saved connections
  ///
  /// Returns connections sorted by creation date (oldest first)
  @override
  Future<List<Connection>> getAll() async {
    try {
      final box = await _getBox();
      final connections = box.values.map(_fromJson).toList();

      // Sort by creation date, handling nulls
      connections.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(1970);
        final bTime = b.createdAt ?? DateTime(1970);
        return aTime.compareTo(bTime);
      });

      return connections;
    } catch (e) {
      return [];
    }
  }

  /// Get a connection by ID
  @override
  Future<Connection?> getById(String id) async {
    try {
      final box = await _getBox();
      final json = box.get(id);
      if (json == null) return null;
      return _fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Get a connection by name
  @override
  Future<Connection?> getByName(String name) async {
    try {
      final connections = await getAll();
      return connections.where((c) => c.name == name).firstOrNull;
    } catch (e) {
      return null;
    }
  }

  /// Delete a connection by ID
  @override
  Future<Either<AppError, void>> delete(String id) async {
    try {
      final box = await _getBox();
      await box.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(AppError.cache(message: 'Failed to delete connection: $e'));
    }
  }

  /// Clear all connections
  @override
  Future<void> clear() async {
    try {
      final box = await _getBox();
      await box.clear();
    } catch (e) {
      // Ignore clear errors in tests
    }
  }

  /// Update connection status
  @override
  Future<Either<AppError, Connection>> updateStatus(
    String id,
    ConnectionStatus status,
  ) async {
    try {
      final box = await _getBox();
      final json = box.get(id);

      if (json == null) {
        return Left(AppError.validation(message: 'Connection not found'));
      }

      final connection = _fromJson(json);
      final updated = connection.copyWith(status: status);
      await box.put(id, _toJson(updated));

      return Right(updated);
    } catch (e) {
      return Left(AppError.cache(message: 'Failed to update status: $e'));
    }
  }

  /// Update connection activity preview
  @override
  Future<Either<AppError, Connection>> updateActivity(
    String id,
    ActivityType type,
    String content,
  ) async {
    try {
      final box = await _getBox();
      final json = box.get(id);

      if (json == null) {
        return Left(AppError.validation(message: 'Connection not found'));
      }

      final connection = _fromJson(json);
      final updated = connection.copyWith(
        lastActivityType: type,
        lastActivityContent: content,
        lastActivityAt: DateTime.now(),
      );
      await box.put(id, _toJson(updated));

      return Right(updated);
    } catch (e) {
      return Left(AppError.cache(message: 'Failed to update activity: $e'));
    }
  }

  /// Update connection's last known project name
  @override
  Future<Either<AppError, Connection>> updateProjectName(
    String id,
    String projectName,
  ) async {
    try {
      final box = await _getBox();
      final json = box.get(id);

      if (json == null) {
        return Left(AppError.validation(message: 'Connection not found'));
      }

      final connection = _fromJson(json);
      final updated = connection.copyWith(lastKnownProjectName: projectName);
      await box.put(id, _toJson(updated));

      return Right(updated);
    } catch (e) {
      return Left(AppError.cache(message: 'Failed to update project name: $e'));
    }
  }
}

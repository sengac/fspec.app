import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/repositories/connection_repository_interface.dart';
import '../repositories/connection_repository.dart';

part 'connection_providers.g.dart';

/// Provider for ConnectionRepository
///
/// Provides a singleton instance of ConnectionRepository for managing
/// connection persistence throughout the app.
/// Uses interface type to allow test overrides.
@Riverpod(keepAlive: true)
IConnectionRepository connectionRepository(Ref ref) {
  return ConnectionRepository();
}

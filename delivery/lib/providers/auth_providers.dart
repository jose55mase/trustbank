import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth.dart';
import '../repositories/auth_repository.dart';

/// Provider for the AuthRepository interface.
/// Override this in main.dart with the mock (or real) implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError(
    'authRepositoryProvider must be overridden with a concrete implementation',
  );
});

/// Fetches the current active session (if any).
/// Validates: Requisitos 5.1, 5.2, 5.3
final sesionActivaProvider = FutureProvider<SesionActiva?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.obtenerSesionActiva();
});

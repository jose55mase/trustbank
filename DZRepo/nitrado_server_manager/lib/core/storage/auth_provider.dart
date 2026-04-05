import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_service.dart';
import 'auth_service_impl.dart';

/// Riverpod provider that exposes a singleton [AuthService] instance.
///
/// Override this provider in tests to inject a mock implementation.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthServiceImpl();
});

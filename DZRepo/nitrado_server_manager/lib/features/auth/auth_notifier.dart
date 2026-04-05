import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/auth_provider.dart';
import '../../core/storage/auth_service.dart';

/// Possible authentication states.
enum AuthStatus { unknown, authenticated, unauthenticated }

/// State exposed by [AuthNotifier].
class AuthState {
  final AuthStatus status;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Manages authentication flow: login, auto-restore, and error handling.
///
/// Validates tokens via [AuthService], persists them in secure storage,
/// and exposes [AuthState] so the UI and router can react accordingly.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  /// Attempts to restore a previously saved session.
  ///
  /// Called on app start. If a valid token exists the status becomes
  /// [AuthStatus.authenticated]; otherwise [AuthStatus.unauthenticated].
  Future<void> tryRestoreSession() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final authenticated = await _authService.isAuthenticated();
      state = state.copyWith(
        status:
            authenticated ? AuthStatus.authenticated : AuthStatus.unauthenticated,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      );
    }
  }

  /// Validates [token] and, if valid, saves it and marks the session as
  /// authenticated. On failure an error message is set on the state.
  Future<void> login(String token) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final valid = await _authService.validateToken(token);
      if (!valid) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Token inválido o expirado. Ingresa un token válido.',
        );
        return;
      }
      await _authService.saveToken(token);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al validar el token: $e',
      );
    }
  }

  /// Logs out by deleting the stored token.
  Future<void> logout() async {
    await _authService.deleteToken();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

/// Provider for [AuthNotifier].
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/portfolio_auth_state.dart';

/// Function type that returns the current time. Used for testability.
typedef Clock = DateTime Function();

/// StateNotifier that manages portfolio admin authentication state.
///
/// Handles login/logout, session expiry tracking (60 min inactivity),
/// and failed attempt tracking with lockout logic (5 failures = 15 min lockout).
class PortfolioAuthNotifier extends StateNotifier<PortfolioAuthState> {
  final FirebaseAuth? _auth;
  final Clock _clock;
  DateTime? _lastActivity;

  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  static const Duration sessionTimeout = Duration(minutes: 60);

  PortfolioAuthNotifier(FirebaseAuth auth, {Clock? clock})
      : _auth = auth,
        _clock = clock ?? (() => DateTime.now()),
        super(const PortfolioAuthState());

  /// Mock constructor that doesn't require Firebase.
  PortfolioAuthNotifier.mock({Clock? clock})
      : _auth = null,
        _clock = clock ?? (() => DateTime.now()),
        super(const PortfolioAuthState());

  /// Attempts to log in with the given credentials.
  ///
  /// Returns `true` on success, `false` on failure.
  /// Tracks failed attempts and enforces lockout after [maxFailedAttempts].
  Future<bool> login(String username, String password) async {
    // Check if account is currently locked out
    if (state.isLockedOut) {
      return false;
    }

    try {
      if (_auth != null) {
        await _auth.signInWithEmailAndPassword(
          email: username,
          password: password,
        );
      } else {
        // Mock mode: accept any non-empty credentials
        if (username.isEmpty || password.isEmpty) {
          return _handleFailedAttempt();
        }
      }

      // Successful login: reset failures and mark authenticated
      _lastActivity = _clock();
      state = const PortfolioAuthState(
        isAuthenticated: true,
        failedAttempts: 0,
        lockoutUntil: null,
        redirectAfterLogin: null,
      );
      return true;
    } on FirebaseAuthException {
      return _handleFailedAttempt();
    } catch (_) {
      return _handleFailedAttempt();
    }
  }

  /// Logs out the current user and resets authentication state.
  Future<void> logout() async {
    await _auth?.signOut();
    _lastActivity = null;
    state = const PortfolioAuthState(
      isAuthenticated: false,
      failedAttempts: 0,
    );
  }

  /// Checks if the session has expired due to inactivity.
  ///
  /// Returns `true` if the session is still valid, `false` if expired.
  bool checkSessionValidity() {
    if (!state.isAuthenticated) return false;

    if (_lastActivity == null) return false;

    final now = _clock();
    if (now.difference(_lastActivity!) > sessionTimeout) {
      // Session expired
      state = PortfolioAuthState(
        isAuthenticated: false,
        failedAttempts: 0,
        redirectAfterLogin: state.redirectAfterLogin,
      );
      return false;
    }

    return true;
  }

  /// Records user activity to reset the inactivity timer.
  void recordActivity() {
    if (state.isAuthenticated) {
      _lastActivity = _clock();
    }
  }

  /// Sets the redirect URL to navigate to after successful login.
  void setRedirectAfterLogin(String? path) {
    state = state.copyWith(redirectAfterLogin: path);
  }

  bool _handleFailedAttempt() {
    final newFailedAttempts = state.failedAttempts + 1;

    if (newFailedAttempts >= maxFailedAttempts) {
      // Lock the account
      state = PortfolioAuthState(
        isAuthenticated: false,
        failedAttempts: newFailedAttempts,
        lockoutUntil: _clock().add(lockoutDuration),
        redirectAfterLogin: state.redirectAfterLogin,
      );
    } else {
      state = state.copyWith(failedAttempts: newFailedAttempts);
    }

    return false;
  }
}

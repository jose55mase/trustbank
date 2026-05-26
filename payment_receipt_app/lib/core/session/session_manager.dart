import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

/// Manages session expiration globally.
/// When a 401 response is detected, logs out and redirects to login.
class SessionManager {
  SessionManager._();

  /// Global navigator key used to navigate from anywhere (including services).
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static bool _isHandlingExpiry = false;

  /// Call this when a 401 response is received.
  /// Logs out the user and navigates to the login screen.
  static Future<void> handleSessionExpired() async {
    // Prevent multiple simultaneous redirects
    if (_isHandlingExpiry) return;
    _isHandlingExpiry = true;

    try {
      await AuthService.logout();

      final context = navigatorKey.currentContext;
      if (context != null) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (_) => false);
      }
    } finally {
      // Reset after a short delay to allow navigation to complete
      Future.delayed(const Duration(seconds: 2), () {
        _isHandlingExpiry = false;
      });
    }
  }
}

/// Route path constants for the portfolio module.
class PortfolioRoutes {
  PortfolioRoutes._();

  // ── Public routes ──────────────────────────────────────────
  static const String portfolio = '/portfolio';
  static const String projectDetail = '/portfolio/project/:id';

  // ── Admin routes ───────────────────────────────────────────
  static const String admin = '/portfolio/admin';
  static const String adminLogin = '/portfolio/admin/login';
  static const String adminProjects = '/portfolio/admin/projects';
  static const String adminContent = '/portfolio/admin/content';

  /// All admin paths that require authentication.
  static const List<String> guardedPrefixes = [
    '/portfolio/admin',
  ];

  /// Paths that are explicitly excluded from the auth guard.
  static const List<String> unguardedPaths = [
    adminLogin,
  ];

  /// Returns true if the given [location] requires authentication.
  static bool requiresAuth(String location) {
    // Login route is never guarded
    if (location == adminLogin || location.startsWith('$adminLogin?')) {
      return false;
    }

    // Check if the location starts with any guarded prefix
    return guardedPrefixes.any((prefix) => location.startsWith(prefix));
  }

  /// Builds the login redirect path preserving the original [returnTo] URL.
  static String loginRedirect(String returnTo) {
    return '$adminLogin?returnTo=${Uri.encodeComponent(returnTo)}';
  }
}

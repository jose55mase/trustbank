import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/portfolio_auth_state.dart';
import '../providers/portfolio_auth_notifier.dart';
import '../providers/portfolio_providers.dart';
import '../screens/portfolio_home_screen.dart';
import '../screens/portfolio_login_screen.dart';
import 'portfolio_routes.dart';

export 'portfolio_routes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Placeholder widgets for screens not yet implemented.
// These will be replaced by actual screen implementations in later tasks.
// ─────────────────────────────────────────────────────────────────────────────

/// Placeholder for the public portfolio page.
class PortfolioHomePlaceholder extends StatelessWidget {
  const PortfolioHomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Portfolio Home')),
    );
  }
}

/// Placeholder for the project detail page.
class ProjectDetailPlaceholder extends StatelessWidget {
  final String projectId;

  const ProjectDetailPlaceholder({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Project Detail: $projectId')),
    );
  }
}

/// Placeholder for the admin dashboard page.
class AdminDashboardPlaceholder extends StatelessWidget {
  const AdminDashboardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Admin Dashboard')),
    );
  }
}

/// Placeholder for the admin login page.
class AdminLoginPlaceholder extends StatelessWidget {
  const AdminLoginPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Admin Login')),
    );
  }
}

/// Placeholder for the admin projects management page.
class AdminProjectsPlaceholder extends StatelessWidget {
  const AdminProjectsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Admin Projects')),
    );
  }
}

/// Placeholder for the admin content editing page.
class AdminContentPlaceholder extends StatelessWidget {
  const AdminContentPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Admin Content')),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Portfolio GoRouter configuration
// ─────────────────────────────────────────────────────────────────────────────

/// Returns the list of [GoRoute] definitions for the portfolio module.
///
/// These routes can be added to the main app router or used standalone.
List<RouteBase> portfolioRoutes() {
  return [
    // ── Public routes ──────────────────────────────────────────
    GoRoute(
      path: PortfolioRoutes.portfolio,
      name: 'portfolio',
      builder: (context, state) => const PortfolioHomeScreen(),
    ),
    GoRoute(
      path: PortfolioRoutes.projectDetail,
      name: 'portfolioProjectDetail',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ProjectDetailPlaceholder(projectId: id);
      },
    ),

    // ── Admin routes ───────────────────────────────────────────
    GoRoute(
      path: PortfolioRoutes.adminLogin,
      name: 'portfolioAdminLogin',
      builder: (context, state) => const PortfolioLoginScreen(),
    ),
    GoRoute(
      path: PortfolioRoutes.admin,
      name: 'portfolioAdmin',
      builder: (context, state) => const AdminDashboardPlaceholder(),
    ),
    GoRoute(
      path: PortfolioRoutes.adminProjects,
      name: 'portfolioAdminProjects',
      builder: (context, state) => const AdminProjectsPlaceholder(),
    ),
    GoRoute(
      path: PortfolioRoutes.adminContent,
      name: 'portfolioAdminContent',
      builder: (context, state) => const AdminContentPlaceholder(),
    ),
  ];
}

/// Portfolio auth guard redirect logic.
///
/// Checks if the user is authenticated and if the session is still valid.
/// If not authenticated or session expired, redirects to the login page
/// preserving the original URL as a `returnTo` query parameter.
///
/// Returns `null` if no redirect is needed, or the redirect path otherwise.
///
/// Validates: Requirements 4.3, 4.4
String? portfolioAuthGuard(
  GoRouterState state,
  PortfolioAuthState authState,
  PortfolioAuthNotifier authNotifier,
) {
  final location = state.matchedLocation;
  final fullLocation = state.uri.toString();

  // Only guard routes that require authentication
  if (!PortfolioRoutes.requiresAuth(location)) {
    return null;
  }

  // Check if user is authenticated
  if (!authState.isAuthenticated) {
    return PortfolioRoutes.loginRedirect(fullLocation);
  }

  // Check session validity (60 min inactivity timeout)
  if (!authNotifier.checkSessionValidity()) {
    return PortfolioRoutes.loginRedirect(fullLocation);
  }

  return null; // No redirect needed
}

/// Creates a standalone [GoRouter] for the portfolio module.
///
/// This is useful for testing or running the portfolio as an independent app.
/// For integration with the main delivery app, use [portfolioRoutes] and
/// [portfolioAuthGuard] directly in the main router.
GoRouter createPortfolioRouter(Ref ref) {
  return GoRouter(
    initialLocation: PortfolioRoutes.portfolio,
    routes: portfolioRoutes(),
    redirect: (BuildContext context, GoRouterState state) {
      final container = ProviderScope.containerOf(context);
      final authState = container.read(portfolioAuthProvider);
      final notifier = container.read(portfolioAuthProvider.notifier);

      return portfolioAuthGuard(state, authState, notifier);
    },
  );
}

/// Riverpod provider for the standalone portfolio router.
final portfolioRouterProvider = Provider<GoRouter>((ref) {
  return createPortfolioRouter(ref);
});

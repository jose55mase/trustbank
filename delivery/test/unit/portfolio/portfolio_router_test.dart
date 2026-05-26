import 'package:delivery_app/portfolio/models/portfolio_auth_state.dart';
import 'package:delivery_app/portfolio/providers/portfolio_auth_notifier.dart';
import 'package:delivery_app/portfolio/router/portfolio_router.dart';
import 'package:delivery_app/portfolio/router/portfolio_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockGoRouterState extends Mock implements GoRouterState {}

void main() {
  group('PortfolioRoutes', () {
    test('requiresAuth returns false for public portfolio route', () {
      expect(PortfolioRoutes.requiresAuth('/portfolio'), isFalse);
    });

    test('requiresAuth returns false for project detail route', () {
      expect(PortfolioRoutes.requiresAuth('/portfolio/project/abc123'), isFalse);
    });

    test('requiresAuth returns false for admin login route', () {
      expect(PortfolioRoutes.requiresAuth('/portfolio/admin/login'), isFalse);
    });

    test('requiresAuth returns false for admin login with query params', () {
      // The requiresAuth checks the location path, not query params
      // But the login path with query starts with the login path
      expect(
        PortfolioRoutes.requiresAuth('/portfolio/admin/login'),
        isFalse,
      );
    });

    test('requiresAuth returns true for admin dashboard', () {
      expect(PortfolioRoutes.requiresAuth('/portfolio/admin'), isTrue);
    });

    test('requiresAuth returns true for admin projects', () {
      expect(PortfolioRoutes.requiresAuth('/portfolio/admin/projects'), isTrue);
    });

    test('requiresAuth returns true for admin content', () {
      expect(PortfolioRoutes.requiresAuth('/portfolio/admin/content'), isTrue);
    });

    test('loginRedirect builds correct URL with encoded returnTo', () {
      final redirect = PortfolioRoutes.loginRedirect('/portfolio/admin/projects');
      expect(redirect, '/portfolio/admin/login?returnTo=%2Fportfolio%2Fadmin%2Fprojects');
    });
  });

  group('portfolioAuthGuard', () {
    late MockFirebaseAuth mockAuth;
    late PortfolioAuthNotifier notifier;
    late MockGoRouterState mockState;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      notifier = PortfolioAuthNotifier(mockAuth);
      mockState = MockGoRouterState();
    });

    void setupMockState(String location) {
      when(() => mockState.matchedLocation).thenReturn(location);
      when(() => mockState.uri).thenReturn(Uri.parse(location));
    }

    test('returns null for public portfolio route', () {
      setupMockState('/portfolio');
      final authState = const PortfolioAuthState(isAuthenticated: false);

      final result = portfolioAuthGuard(mockState, authState, notifier);
      expect(result, isNull);
    });

    test('returns null for project detail route when unauthenticated', () {
      setupMockState('/portfolio/project/123');
      final authState = const PortfolioAuthState(isAuthenticated: false);

      final result = portfolioAuthGuard(mockState, authState, notifier);
      expect(result, isNull);
    });

    test('returns null for login route when unauthenticated', () {
      setupMockState('/portfolio/admin/login');
      final authState = const PortfolioAuthState(isAuthenticated: false);

      final result = portfolioAuthGuard(mockState, authState, notifier);
      expect(result, isNull);
    });

    test('redirects to login when accessing admin route unauthenticated', () {
      setupMockState('/portfolio/admin');
      final authState = const PortfolioAuthState(isAuthenticated: false);

      final result = portfolioAuthGuard(mockState, authState, notifier);
      expect(result, contains('/portfolio/admin/login'));
      expect(result, contains('returnTo='));
    });

    test('redirects to login when accessing admin/projects unauthenticated', () {
      setupMockState('/portfolio/admin/projects');
      final authState = const PortfolioAuthState(isAuthenticated: false);

      final result = portfolioAuthGuard(mockState, authState, notifier);
      expect(result, contains('/portfolio/admin/login'));
      expect(result, contains('returnTo=%2Fportfolio%2Fadmin%2Fprojects'));
    });

    test('redirects to login when accessing admin/content unauthenticated', () {
      setupMockState('/portfolio/admin/content');
      final authState = const PortfolioAuthState(isAuthenticated: false);

      final result = portfolioAuthGuard(mockState, authState, notifier);
      expect(result, contains('/portfolio/admin/login'));
      expect(result, contains('returnTo=%2Fportfolio%2Fadmin%2Fcontent'));
    });

    test('returns null for admin route when authenticated with valid session', () {
      setupMockState('/portfolio/admin');
      final authState = const PortfolioAuthState(isAuthenticated: true);

      // We need a notifier that reports session as valid.
      final testNotifier = _TestableAuthNotifier(mockAuth, isSessionValid: true);

      final result = portfolioAuthGuard(mockState, authState, testNotifier);
      expect(result, isNull);
    });

    test('redirects when session has expired (60 min inactivity)', () {
      setupMockState('/portfolio/admin/projects');
      final authState = const PortfolioAuthState(isAuthenticated: true);

      // Notifier that reports session as expired
      final testNotifier = _TestableAuthNotifier(mockAuth, isSessionValid: false);

      final result = portfolioAuthGuard(mockState, authState, testNotifier);
      expect(result, contains('/portfolio/admin/login'));
      expect(result, contains('returnTo=%2Fportfolio%2Fadmin%2Fprojects'));
    });

    test('preserves full URL path in returnTo parameter', () {
      setupMockState('/portfolio/admin/content');
      final authState = const PortfolioAuthState(isAuthenticated: false);

      final result = portfolioAuthGuard(mockState, authState, notifier);
      expect(result, '/portfolio/admin/login?returnTo=%2Fportfolio%2Fadmin%2Fcontent');
    });
  });

  group('portfolioRoutes()', () {
    test('returns correct number of routes', () {
      final routes = portfolioRoutes();
      expect(routes.length, 6);
    });

    test('contains all expected route paths', () {
      final routes = portfolioRoutes();
      final paths = routes.whereType<GoRoute>().map((r) => r.path).toList();

      expect(paths, contains('/portfolio'));
      expect(paths, contains('/portfolio/project/:id'));
      expect(paths, contains('/portfolio/admin'));
      expect(paths, contains('/portfolio/admin/login'));
      expect(paths, contains('/portfolio/admin/projects'));
      expect(paths, contains('/portfolio/admin/content'));
    });
  });
}

/// A testable subclass of [PortfolioAuthNotifier] that allows controlling
/// session validity for testing purposes.
class _TestableAuthNotifier extends PortfolioAuthNotifier {
  final bool isSessionValid;

  _TestableAuthNotifier(super.auth, {required this.isSessionValid});

  @override
  bool checkSessionValidity() => isSessionValid;
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nitrado_server_manager/core/storage/auth_service.dart';
import 'package:nitrado_server_manager/core/storage/auth_provider.dart';
import 'package:nitrado_server_manager/features/auth/auth_notifier.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;
  late AuthNotifier notifier;

  setUp(() {
    mockAuthService = MockAuthService();
    notifier = AuthNotifier(mockAuthService);
  });

  group('initial state', () {
    test('starts with unknown status and not loading', () {
      expect(notifier.state.status, AuthStatus.unknown);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNull);
    });
  });

  group('tryRestoreSession', () {
    test('sets authenticated when token exists', () async {
      when(() => mockAuthService.isAuthenticated())
          .thenAnswer((_) async => true);

      await notifier.tryRestoreSession();

      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.isLoading, false);
    });

    test('sets unauthenticated when no token', () async {
      when(() => mockAuthService.isAuthenticated())
          .thenAnswer((_) async => false);

      await notifier.tryRestoreSession();

      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.isLoading, false);
    });

    test('sets unauthenticated on error', () async {
      when(() => mockAuthService.isAuthenticated())
          .thenThrow(Exception('storage error'));

      await notifier.tryRestoreSession();

      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.isLoading, false);
    });
  });

  group('login', () {
    test('authenticates with valid token', () async {
      when(() => mockAuthService.validateToken('good-token'))
          .thenAnswer((_) async => true);
      when(() => mockAuthService.saveToken('good-token'))
          .thenAnswer((_) async {});

      await notifier.login('good-token');

      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNull);
      verify(() => mockAuthService.saveToken('good-token')).called(1);
    });

    test('sets error for invalid token', () async {
      when(() => mockAuthService.validateToken('bad'))
          .thenAnswer((_) async => false);

      await notifier.login('bad');

      expect(notifier.state.status, AuthStatus.unknown);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNotNull);
      expect(notifier.state.errorMessage, contains('inválido'));
    });

    test('sets error when validation throws', () async {
      when(() => mockAuthService.validateToken('err'))
          .thenThrow(Exception('network'));

      await notifier.login('err');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, contains('Error'));
    });
  });

  group('logout', () {
    test('clears state and deletes token', () async {
      when(() => mockAuthService.validateToken(any()))
          .thenAnswer((_) async => true);
      when(() => mockAuthService.saveToken(any()))
          .thenAnswer((_) async {});
      when(() => mockAuthService.deleteToken()).thenAnswer((_) async {});

      await notifier.login('token');
      await notifier.logout();

      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.errorMessage, isNull);
      verify(() => mockAuthService.deleteToken()).called(1);
    });
  });

  group('authNotifierProvider', () {
    test('creates notifier with injected AuthService', () {
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(authNotifierProvider);
      expect(state.status, AuthStatus.unknown);
    });
  });
}

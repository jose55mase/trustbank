import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nitrado_server_manager/core/storage/auth_service.dart';
import 'package:nitrado_server_manager/core/storage/auth_service_impl.dart';
import 'package:nitrado_server_manager/core/storage/auth_provider.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late AuthServiceImpl authService;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    authService = AuthServiceImpl(storage: mockStorage);
  });

  group('saveToken', () {
    test('writes token to secure storage', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await authService.saveToken('my-oauth-token');

      verify(() => mockStorage.write(
            key: 'nitrado_oauth_token',
            value: 'my-oauth-token',
          )).called(1);
    });
  });

  group('getToken', () {
    test('returns stored token', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'stored-token');

      final result = await authService.getToken();

      expect(result, 'stored-token');
    });

    test('returns null when no token stored', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      final result = await authService.getToken();

      expect(result, isNull);
    });
  });

  group('validateToken', () {
    test('returns true for non-empty token', () async {
      final result = await authService.validateToken('valid-token');
      expect(result, isTrue);
    });

    test('returns false for empty token', () async {
      final result = await authService.validateToken('');
      expect(result, isFalse);
    });
  });

  group('deleteToken', () {
    test('removes token from secure storage', () async {
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      await authService.deleteToken();

      verify(() => mockStorage.delete(key: 'nitrado_oauth_token')).called(1);
    });
  });

  group('isAuthenticated', () {
    test('returns true when a non-empty token is stored', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'some-token');

      final result = await authService.isAuthenticated();

      expect(result, isTrue);
    });

    test('returns false when no token is stored', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      final result = await authService.isAuthenticated();

      expect(result, isFalse);
    });

    test('returns false when stored token is empty', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => '');

      final result = await authService.isAuthenticated();

      expect(result, isFalse);
    });
  });

  group('authServiceProvider', () {
    test('provides an AuthService instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(authServiceProvider);

      expect(service, isA<AuthService>());
      expect(service, isA<AuthServiceImpl>());
    });
  });
}

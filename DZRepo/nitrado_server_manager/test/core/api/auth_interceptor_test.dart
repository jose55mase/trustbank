import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nitrado_server_manager/core/api/auth_interceptor.dart';
import 'package:nitrado_server_manager/core/storage/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  late MockAuthService mockAuthService;
  late AuthInterceptor interceptor;

  setUp(() {
    mockAuthService = MockAuthService();
    interceptor = AuthInterceptor(mockAuthService);
  });

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  group('AuthInterceptor', () {
    test('adds Bearer token header when token is available', () async {
      when(() => mockAuthService.getToken())
          .thenAnswer((_) async => 'test-token-123');

      final options = RequestOptions(path: '/services');
      var nextCalled = false;

      final handler = RequestInterceptorHandler();

      // We test by calling onRequest and checking the options are modified
      await interceptor.onRequest(
        options,
        handler,
      );

      expect(options.headers['Authorization'], 'Bearer test-token-123');
    });

    test('does not add header when token is null', () async {
      when(() => mockAuthService.getToken()).thenAnswer((_) async => null);

      final options = RequestOptions(path: '/services');
      final handler = RequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('Authorization'), isFalse);
    });

    test('does not add header when token is empty', () async {
      when(() => mockAuthService.getToken()).thenAnswer((_) async => '');

      final options = RequestOptions(path: '/services');
      final handler = RequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('Authorization'), isFalse);
    });
  });
}

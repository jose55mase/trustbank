import 'package:flutter_test/flutter_test.dart';
import 'package:nitrado_server_manager/core/api/api_exceptions.dart';

void main() {
  group('ApiException', () {
    test('stores message and statusCode', () {
      const ex = ApiException('Something went wrong', statusCode: 400);
      expect(ex.message, 'Something went wrong');
      expect(ex.statusCode, 400);
    });

    test('toString includes status code and message', () {
      const ex = ApiException('Bad request', statusCode: 400);
      expect(ex.toString(), 'ApiException(400): Bad request');
    });

    test('statusCode defaults to null', () {
      const ex = ApiException('Network error');
      expect(ex.statusCode, isNull);
    });
  });

  group('UnauthorizedException', () {
    test('has default message', () {
      const ex = UnauthorizedException();
      expect(ex.message, 'Token inválido o expirado');
      expect(ex.statusCode, 401);
    });

    test('accepts custom message', () {
      const ex = UnauthorizedException('Token expired');
      expect(ex.message, 'Token expired');
      expect(ex.statusCode, 401);
    });

    test('is an ApiException', () {
      const ex = UnauthorizedException();
      expect(ex, isA<ApiException>());
    });

    test('toString includes message', () {
      const ex = UnauthorizedException('Expired');
      expect(ex.toString(), 'UnauthorizedException: Expired');
    });
  });
}

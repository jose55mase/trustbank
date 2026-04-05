import 'package:dio/dio.dart';
import 'package:nitrado_server_manager/core/storage/auth_service.dart';

/// Dio interceptor that injects the OAuth Bearer token into every request.
///
/// Reads the token from [AuthService] and adds it as an
/// `Authorization: Bearer {token}` header.
class AuthInterceptor extends Interceptor {
  final AuthService _authService;

  AuthInterceptor(this._authService);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _authService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Base exception for all Nitrado API errors.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thrown when the OAuth token is invalid or expired (401/403).
///
/// Signals that the user should be redirected to the auth screen.
class UnauthorizedException extends ApiException {
  const UnauthorizedException([String message = 'Token inválido o expirado'])
      : super(message, statusCode: 401);

  @override
  String toString() => 'UnauthorizedException: $message';
}

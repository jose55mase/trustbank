/// Tipos de error que puede producir la API de comentarios.
enum CommentErrorType {
  /// Error de red (sin conexión, timeout, etc.)
  network,

  /// Error de validación (400): texto vacío o excede 2000 caracteres.
  validation,

  /// Error de permisos (403): el usuario no es el autor del comentario.
  forbidden,

  /// Recurso no encontrado (404): lead o comentario eliminado por otra sesión.
  notFound,

  /// Sesión expirada (401): redirigir a login.
  unauthorized,

  /// Otro error no clasificado.
  unknown,
}

/// Excepción tipada para errores del API de comentarios de leads.
/// Permite al BLoC diferenciar el tipo de error y mostrar la UI adecuada.
class CommentApiException implements Exception {
  final CommentErrorType type;
  final String message;

  const CommentApiException({
    required this.type,
    required this.message,
  });

  @override
  String toString() => message;
}

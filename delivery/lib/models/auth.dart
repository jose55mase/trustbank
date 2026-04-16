/// Tipos de usuario que pueden autenticarse.
enum TipoUsuario {
  repartidor,
  administrador,
}

/// Resultado de un intento de autenticación.
class AuthResult {
  final bool exitoso;
  final String? mensaje;
  final String? userId;
  final TipoUsuario? tipo;

  const AuthResult({
    required this.exitoso,
    this.mensaje,
    this.userId,
    this.tipo,
  });
}

/// Representa una sesión activa de un usuario autenticado.
class SesionActiva {
  final String userId;
  final TipoUsuario tipo;

  const SesionActiva({
    required this.userId,
    required this.tipo,
  });
}

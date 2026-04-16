import '../models/auth.dart';

/// Interfaz abstracta para el repositorio de autenticación.
/// Define el contrato para login, logout y gestión de sesiones.
abstract class AuthRepository {
  /// Autentica un repartidor o administrador
  Future<AuthResult> login(String usuario, String password, TipoUsuario tipo);

  /// Cierra la sesión actual
  Future<void> logout();

  /// Obtiene la sesión activa actual (si existe)
  Future<SesionActiva?> obtenerSesionActiva();
}

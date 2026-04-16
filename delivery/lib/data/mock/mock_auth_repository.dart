import 'package:delivery_app/models/auth.dart';
import 'package:delivery_app/repositories/auth_repository.dart';

import 'mock_data.dart';

/// Implementación mock del repositorio de autenticación.
/// Valida credenciales contra los datos mock y gestiona sesiones en memoria.
class MockAuthRepository implements AuthRepository {
  SesionActiva? _sesionActiva;

  @override
  Future<AuthResult> login(
      String usuario, String password, TipoUsuario tipo) async {
    if (tipo == TipoUsuario.repartidor) {
      for (final repartidor in mockRepartidores) {
        if (repartidor.usuario == usuario && repartidor.password == password) {
          _sesionActiva = SesionActiva(
            userId: repartidor.id,
            tipo: TipoUsuario.repartidor,
          );
          return AuthResult(
            exitoso: true,
            userId: repartidor.id,
            tipo: TipoUsuario.repartidor,
          );
        }
      }
    } else if (tipo == TipoUsuario.administrador) {
      for (final admin in mockAdministradores) {
        if (admin.usuario == usuario && admin.password == password) {
          _sesionActiva = SesionActiva(
            userId: admin.id,
            tipo: TipoUsuario.administrador,
          );
          return AuthResult(
            exitoso: true,
            userId: admin.id,
            tipo: TipoUsuario.administrador,
          );
        }
      }
    }

    return const AuthResult(
      exitoso: false,
      mensaje: 'Credenciales incorrectas',
    );
  }

  @override
  Future<void> logout() async {
    _sesionActiva = null;
  }

  @override
  Future<SesionActiva?> obtenerSesionActiva() async {
    return _sesionActiva;
  }
}

// Feature: delivery-app, Property 10: Autenticación redirige al panel correcto según rol
// **Validates: Requirements 5.2, 5.3**
//
// For any valid credential of Repartidor or Administrador, the auth result
// must indicate the correct user type, enabling redirection to the
// corresponding panel (Panel_Repartidor or Panel_Admin).

import 'package:delivery_app/data/mock/mock_auth_repository.dart';
import 'package:delivery_app/data/mock/mock_data.dart';
import 'package:delivery_app/models/auth.dart';
import 'package:glados/glados.dart';

/// Represents a valid credential picked from mock data.
class CredencialValida {
  final String usuario;
  final String password;
  final TipoUsuario tipo;
  final String expectedUserId;

  const CredencialValida({
    required this.usuario,
    required this.password,
    required this.tipo,
    required this.expectedUserId,
  });

  @override
  String toString() =>
      'CredencialValida(usuario: $usuario, tipo: $tipo, expectedUserId: $expectedUserId)';
}

extension AuthGenerators on Any {
  /// Generator that picks a valid credential from the combined pool of
  /// mock repartidores and administradores.
  Generator<CredencialValida> get credencialValida {
    final todas = <CredencialValida>[
      ...mockRepartidores.map((r) => CredencialValida(
            usuario: r.usuario,
            password: r.password,
            tipo: TipoUsuario.repartidor,
            expectedUserId: r.id,
          )),
      ...mockAdministradores.map((a) => CredencialValida(
            usuario: a.usuario,
            password: a.password,
            tipo: TipoUsuario.administrador,
            expectedUserId: a.id,
          )),
    ];
    return choose(todas);
  }
}

void main() {
  Glados(any.credencialValida, ExploreConfig(numRuns: 100)).test(
    'Property 10: Valid credentials return correct user type for role-based redirection',
    (credencial) async {
      final repo = MockAuthRepository();

      final result = await repo.login(
        credencial.usuario,
        credencial.password,
        credencial.tipo,
      );

      // Login must succeed
      expect(result.exitoso, isTrue,
          reason:
              'Login should succeed for valid credential: ${credencial.usuario}');

      // The returned tipo must match the expected role
      expect(result.tipo, equals(credencial.tipo),
          reason:
              'Auth result tipo should be ${credencial.tipo} for user ${credencial.usuario}');

      // The returned userId must match the expected user
      expect(result.userId, equals(credencial.expectedUserId),
          reason:
              'Auth result userId should be ${credencial.expectedUserId} for user ${credencial.usuario}');
    },
  );
}

// Feature: delivery-app, Property 11: Credenciales inválidas son rechazadas
// **Validates: Requirements 5.4**
//
// For any username/password combination that doesn't match any registered
// Repartidor or Administrador, login must return a non-successful result.

import 'package:delivery_app/data/mock/mock_auth_repository.dart';
import 'package:delivery_app/data/mock/mock_data.dart';
import 'package:delivery_app/models/auth.dart';
import 'package:glados/glados.dart';

/// Collects all valid (usuario, password) pairs from mock data.
final _credencialesValidas = <(String, String, TipoUsuario)>{
  ...mockRepartidores
      .map((r) => (r.usuario, r.password, TipoUsuario.repartidor)),
  ...mockAdministradores
      .map((a) => (a.usuario, a.password, TipoUsuario.administrador)),
};

bool _esCredencialValida(String usuario, String password, TipoUsuario tipo) {
  return _credencialesValidas.contains((usuario, password, tipo));
}

extension InvalidAuthGenerators on Any {
  Generator<TipoUsuario> get tipoUsuario => choose(TipoUsuario.values);
}

void main() {
  Glados3(any.nonEmptyLetterOrDigits, any.nonEmptyLetterOrDigits,
          any.tipoUsuario, ExploreConfig(numRuns: 100))
      .test(
    'Property 11: Invalid credentials are rejected with non-successful result',
    (usuario, password, tipo) async {
      // Skip if this happens to be a valid credential
      if (_esCredencialValida(usuario, password, tipo)) return;

      final repo = MockAuthRepository();

      final result = await repo.login(usuario, password, tipo);

      // Login must NOT succeed
      expect(result.exitoso, isFalse,
          reason:
              'Login should fail for invalid credentials: usuario=$usuario, tipo=$tipo');

      // userId and tipo should be null on failure
      expect(result.userId, isNull,
          reason: 'userId should be null for failed login');
      expect(result.tipo, isNull,
          reason: 'tipo should be null for failed login');

      // Should have an error message
      expect(result.mensaje, isNotNull,
          reason: 'Failed login should include an error message');
      expect(result.mensaje!.isNotEmpty, isTrue,
          reason: 'Error message should not be empty');
    },
  );
}

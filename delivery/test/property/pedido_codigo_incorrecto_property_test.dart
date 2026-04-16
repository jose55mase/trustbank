// Feature: delivery-app, Property 8: Código de confirmación incorrecto es rechazado
// **Validates: Requirements 3.3**
//
// For any active order and any code that doesn't match its confirmation code,
// the confirmation attempt must be rejected and the order must remain active.

import 'package:delivery_app/data/mock/mock_pedido_repository.dart';
import 'package:delivery_app/models/pedido.dart';
import 'package:glados/glados.dart';

extension CodigoIncorrectoGenerators on Any {
  Generator<String> get wrongCode => nonEmptyLetterOrDigits;
}

void main() {
  Glados(any.wrongCode, ExploreConfig(numRuns: 100)).test(
    'Property 8: An incorrect confirmation code is rejected and order stays active',
    (wrongCode) async {
      final repo = MockPedidoRepository();

      // Create an order
      final pedido = await repo.crearPedido(const CrearPedidoRequest(
        direccionEntrega: 'Calle 45 #12-34',
        nombreUsuario: 'Test User',
        telefonoUsuario: '3001234567',
        descripcion: 'Test package',
        precioProducto: 25000.0,
        tipoEntrega: TipoEntrega.estandar,
      ));

      // Assign repartidor
      await repo.asignarRepartidor(pedido.id, 'rep-001');

      // Ensure the wrong code is actually different from the real code
      final codeToUse = wrongCode == pedido.codigoConfirmacion
          ? '${wrongCode}X'
          : wrongCode;

      // Attempt confirmation with wrong code
      final result = await repo.confirmarEntrega(pedido.id, codeToUse);
      expect(result, isFalse,
          reason: 'Wrong code must be rejected');

      // Order must still be in active list
      final activos = await repo.obtenerPedidosActivos();
      final stillActive = activos.any((p) => p.id == pedido.id);
      expect(stillActive, isTrue,
          reason: 'Order must remain active after wrong code');

      // Order state must be unchanged
      final activePedido = activos.firstWhere((p) => p.id == pedido.id);
      expect(activePedido.codigoConfirmacion,
          equals(pedido.codigoConfirmacion));
    },
  );
}

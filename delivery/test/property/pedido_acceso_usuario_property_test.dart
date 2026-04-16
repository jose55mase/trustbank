// Feature: delivery-app, Property 13: Usuario solo accede a sus propios pedidos
// **Validates: Requirements 8.1, 8.3**
//
// For any user identified by phone, querying active orders or history must
// return only orders associated with that phone number.

import 'package:delivery_app/data/mock/mock_pedido_repository.dart';
import 'package:delivery_app/models/pedido.dart';
import 'package:glados/glados.dart';

extension AccesoUsuarioGenerators on Any {
  Generator<int> get userIndex => intInRange(0, 2);
}

void main() {
  final phones = ['3001111111', '3002222222', '3003333333'];

  Glados(any.userIndex, ExploreConfig(numRuns: 100)).test(
    'Property 13: A user only sees their own active orders and history',
    (queryIndex) async {
      final repo = MockPedidoRepository();

      // Create one active order per user
      for (var i = 0; i < phones.length; i++) {
        final pedido = await repo.crearPedido(CrearPedidoRequest(
          direccionEntrega: 'Dirección usuario $i',
          nombreUsuario: 'Usuario $i',
          telefonoUsuario: phones[i],
          descripcion: 'Pedido de usuario $i',
          precioProducto: 10000.0 + i * 5000,
          tipoEntrega: TipoEntrega.estandar,
        ));

        // Complete some orders to populate history
        if (i < queryIndex) {
          await repo.asignarRepartidor(pedido.id, 'rep-001');
          await repo.confirmarEntrega(pedido.id, pedido.codigoConfirmacion);
        }
      }

      final queryPhone = phones[queryIndex];

      // Check active order for this user
      final activePedido =
          await repo.obtenerPedidoActivoPorUsuario(queryPhone);
      if (activePedido != null) {
        expect(activePedido.telefonoUsuario, equals(queryPhone),
            reason: 'Active order must belong to queried user');
      }

      // Check history for this user
      final historial = await repo.obtenerHistorialUsuario(queryPhone);
      for (final entry in historial) {
        expect(entry.telefonoUsuario, equals(queryPhone),
            reason:
                'History entry must belong to queried user, got ${entry.telefonoUsuario}');
      }
    },
  );
}

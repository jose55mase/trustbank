// Feature: delivery-app, Property 4: Pedidos activos ordenados por fecha descendente
// **Validates: Requirements 2.1**
//
// For any set of active orders, listing them must return them sorted
// by creation date descending (most recent first).

import 'package:delivery_app/data/mock/mock_pedido_repository.dart';
import 'package:delivery_app/models/pedido.dart';
import 'package:glados/glados.dart';

extension OrdenamientoGenerators on Any {
  Generator<int> get orderCount => intInRange(2, 8);
}

void main() {
  Glados(any.orderCount, ExploreConfig(numRuns: 100)).test(
    'Property 4: Active orders are returned sorted by creation date descending',
    (count) async {
      final repo = MockPedidoRepository();

      // Create multiple orders with unique phones
      for (var i = 0; i < count; i++) {
        await repo.crearPedido(CrearPedidoRequest(
          direccionEntrega: 'Dirección $i',
          nombreUsuario: 'Usuario $i',
          telefonoUsuario: '300${i.toString().padLeft(7, '0')}',
          descripcion: 'Pedido $i',
          precioProducto: 10000.0 + i * 1000,
          tipoEntrega: TipoEntrega.estandar,
        ));
      }

      final activos = await repo.obtenerPedidosActivos();
      expect(activos.length, equals(count));

      // Verify descending order by fechaCreacion
      for (var i = 0; i < activos.length - 1; i++) {
        expect(
          activos[i].fechaCreacion.isAfter(activos[i + 1].fechaCreacion) ||
              activos[i]
                  .fechaCreacion
                  .isAtSameMomentAs(activos[i + 1].fechaCreacion),
          isTrue,
          reason:
              'Order at index $i (${activos[i].fechaCreacion}) should be >= order at index ${i + 1} (${activos[i + 1].fechaCreacion})',
        );
      }
    },
  );
}

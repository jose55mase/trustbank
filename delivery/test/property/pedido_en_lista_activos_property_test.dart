// Feature: delivery-app, Property 5: Nuevo pedido aparece en lista de activos
// **Validates: Requirements 2.2**
//
// For any successfully created order, querying active orders must include it.

import 'package:delivery_app/data/mock/mock_pedido_repository.dart';
import 'package:delivery_app/models/pedido.dart';
import 'package:glados/glados.dart';

extension NuevoPedidoGenerators on Any {
  Generator<TipoEntrega> get tipoEntrega => choose(TipoEntrega.values);

  Generator<CrearPedidoRequest> get validRequest => combine5(
        nonEmptyLetterOrDigits, // direccionEntrega
        nonEmptyLetterOrDigits, // nombreUsuario
        nonEmptyLetterOrDigits, // descripcion
        doubleInRange(1.0, 999999.99), // precioProducto
        tipoEntrega,
        (String direccion, String nombre, String descripcion, double precio,
                TipoEntrega tipo) =>
            CrearPedidoRequest(
          direccionEntrega: direccion,
          nombreUsuario: nombre,
          telefonoUsuario: '3001234567',
          descripcion: descripcion,
          precioProducto: precio,
          tipoEntrega: tipo,
        ),
      );
}

void main() {
  Glados(any.validRequest, ExploreConfig(numRuns: 100)).test(
    'Property 5: A newly created order appears in the active orders list',
    (request) async {
      final repo = MockPedidoRepository();

      final pedido = await repo.crearPedido(request);
      final activos = await repo.obtenerPedidosActivos();

      // The created order must be in the active list
      final found = activos.any((p) => p.id == pedido.id);
      expect(found, isTrue,
          reason: 'Newly created order ${pedido.id} must appear in active list');

      // Verify the order data matches
      final match = activos.firstWhere((p) => p.id == pedido.id);
      expect(match.direccionEntrega, equals(request.direccionEntrega));
      expect(match.nombreUsuario, equals(request.nombreUsuario));
      expect(match.descripcion, equals(request.descripcion));
      expect(match.precioProducto, equals(request.precioProducto));
      expect(match.codigoConfirmacion, equals(pedido.codigoConfirmacion));
    },
  );
}

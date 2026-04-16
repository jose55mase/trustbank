// Feature: delivery-app, Property 3: Invariante de pedido único por usuario
// **Validates: Requirements 1.4, 8.2**
//
// For any user with an active order, attempting to create a new order
// must be rejected, maintaining at most 1 active order per user.

import 'package:delivery_app/data/mock/mock_pedido_repository.dart';
import 'package:delivery_app/models/pedido.dart';
import 'package:glados/glados.dart';

extension PedidoUnicoGenerators on Any {
  Generator<TipoEntrega> get tipoEntrega => choose(TipoEntrega.values);

  Generator<CrearPedidoRequest> get validRequest => combine4(
        nonEmptyLetterOrDigits, // direccionEntrega
        nonEmptyLetterOrDigits, // nombreUsuario
        nonEmptyLetterOrDigits, // descripcion
        doubleInRange(1.0, 999999.99), // precioProducto
        (String direccion, String nombre, String descripcion, double precio) =>
            CrearPedidoRequest(
          direccionEntrega: direccion,
          nombreUsuario: nombre,
          telefonoUsuario: '3001234567', // Same phone for both attempts
          descripcion: descripcion,
          precioProducto: precio,
          tipoEntrega: TipoEntrega.estandar,
        ),
      );
}

void main() {
  Glados(any.validRequest, ExploreConfig(numRuns: 100)).test(
    'Property 3: A user with an active order cannot create another',
    (request) async {
      final repo = MockPedidoRepository();

      // First order should succeed
      final pedido = await repo.crearPedido(request);
      expect(pedido.estado, equals(EstadoPedido.pendiente));

      // Second order with same phone must be rejected
      final secondRequest = CrearPedidoRequest(
        direccionEntrega: 'Otra dirección',
        nombreUsuario: 'Otro nombre',
        telefonoUsuario: request.telefonoUsuario,
        descripcion: 'Otra descripción',
        precioProducto: 10000.0,
        tipoEntrega: TipoEntrega.express,
      );

      expect(
        () => repo.crearPedido(secondRequest),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('ya tiene un pedido activo'),
        )),
      );
    },
  );
}

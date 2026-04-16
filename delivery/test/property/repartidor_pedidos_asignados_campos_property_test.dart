// Feature: delivery-app, Property 17: Panel de repartidor muestra pedidos asignados con campos requeridos
// **Validates: Requirements 13.1**
//
// For any Repartidor with assigned orders, the order list must include
// for each order: delivery address, user name, order description, and product price.

import 'package:delivery_app/data/mock/mock_pedido_repository.dart';
import 'package:delivery_app/data/mock/mock_repartidor_repository.dart';
import 'package:delivery_app/models/pedido.dart';
import 'package:glados/glados.dart';

extension _PedidoRequestGenerators on Any {
  Generator<TipoEntrega> get tipoEntrega => choose(TipoEntrega.values);

  Generator<CrearPedidoRequest> get crearPedidoRequest => combine5(
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
          telefonoUsuario: '300${nombre.hashCode.abs() % 10000000}',
          descripcion: descripcion,
          precioProducto: precio,
          tipoEntrega: tipo,
        ),
      );
}

void main() {
  Glados(any.listWithLengthInRange(1, 5, any.crearPedidoRequest),
          ExploreConfig(numRuns: 100))
      .test(
    'Property 17: Assigned orders for a repartidor include required fields '
    '(address, user name, description, product price)',
    (requests) async {
      final pedidoRepo = MockPedidoRepository(initialHistorial: []);
      final repartidorRepo = MockRepartidorRepository(pedidoRepo);

      const repartidorId = 'rep-001';

      // Create orders with unique phones and assign them to the repartidor
      final createdPedidos = <Pedido>[];
      for (var i = 0; i < requests.length; i++) {
        final req = requests[i];
        final uniquePhone = '3${i.toString().padLeft(9, '0')}';
        final pedido = await pedidoRepo.crearPedido(CrearPedidoRequest(
          direccionEntrega: req.direccionEntrega,
          nombreUsuario: req.nombreUsuario,
          telefonoUsuario: uniquePhone,
          descripcion: req.descripcion,
          precioProducto: req.precioProducto,
          tipoEntrega: req.tipoEntrega,
        ));
        await pedidoRepo.asignarRepartidor(pedido.id, repartidorId);
        createdPedidos.add(pedido);
      }

      // Fetch assigned orders via the repartidor repository
      final asignados =
          await repartidorRepo.obtenerPedidosAsignados(repartidorId);

      // Must have the same count
      expect(asignados.length, equals(createdPedidos.length),
          reason: 'All created orders should be assigned to the repartidor');

      // Each assigned order must contain the required fields
      for (final pedido in asignados) {
        expect(pedido.direccionEntrega.isNotEmpty, isTrue,
            reason: 'Assigned order must have a non-empty delivery address');
        expect(pedido.nombreUsuario.isNotEmpty, isTrue,
            reason: 'Assigned order must have a non-empty user name');
        expect(pedido.descripcion.isNotEmpty, isTrue,
            reason: 'Assigned order must have a non-empty description');
        expect(pedido.precioProducto > 0, isTrue,
            reason: 'Assigned order must have a positive product price');
      }

      // Verify the data matches what was originally created
      for (final original in createdPedidos) {
        final found = asignados.any((p) =>
            p.direccionEntrega == original.direccionEntrega &&
            p.nombreUsuario == original.nombreUsuario &&
            p.descripcion == original.descripcion &&
            p.precioProducto == original.precioProducto);
        expect(found, isTrue,
            reason:
                'Each created order data must be preserved in assigned list');
      }
    },
  );
}

// Feature: delivery-app, Property 1: Creación de pedido genera código único
// **Validates: Requirements 1.2**
//
// For any set of valid form data, creating an order must produce a
// Pedido_Activo with a unique Código_Confirmación that does not match
// any other existing code in the system.

import 'package:delivery_app/data/mock/mock_pedido_repository.dart';
import 'package:delivery_app/models/pedido.dart';
import 'package:glados/glados.dart';

extension CrearPedidoGenerators on Any {
  Generator<TipoEntrega> get tipoEntrega => choose(TipoEntrega.values);

  Generator<CrearPedidoRequest> get crearPedidoRequest => combine5(
        nonEmptyLetterOrDigits, // direccionEntrega
        nonEmptyLetterOrDigits, // nombreUsuario
        nonEmptyLetterOrDigits, // descripcion
        doubleInRange(1.0, 999999.99), // precioProducto
        tipoEntrega, // tipoEntrega
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
  Glados(any.listWithLengthInRange(2, 10, any.crearPedidoRequest),
          ExploreConfig(numRuns: 100))
      .test(
    'Property 1: Creating orders produces unique confirmation codes',
    (requests) async {
      final repo = MockPedidoRepository();
      final codes = <String>{};

      // Ensure each request has a unique phone to avoid the 1-active-per-user constraint
      final uniqueRequests = <CrearPedidoRequest>[];
      final usedPhones = <String>{};
      for (final req in requests) {
        final phone = '3${uniqueRequests.length.toString().padLeft(9, '0')}';
        if (!usedPhones.contains(phone)) {
          usedPhones.add(phone);
          uniqueRequests.add(CrearPedidoRequest(
            direccionEntrega: req.direccionEntrega,
            nombreUsuario: req.nombreUsuario,
            telefonoUsuario: phone,
            descripcion: req.descripcion,
            precioProducto: req.precioProducto,
            tipoEntrega: req.tipoEntrega,
          ));
        }
      }

      for (final request in uniqueRequests) {
        final pedido = await repo.crearPedido(request);

        // Code must be non-empty
        expect(pedido.codigoConfirmacion.isNotEmpty, isTrue,
            reason: 'Confirmation code must not be empty');

        // Code must be unique across all created orders
        expect(codes.contains(pedido.codigoConfirmacion), isFalse,
            reason:
                'Confirmation code ${pedido.codigoConfirmacion} was already used');

        codes.add(pedido.codigoConfirmacion);
      }
    },
  );
}

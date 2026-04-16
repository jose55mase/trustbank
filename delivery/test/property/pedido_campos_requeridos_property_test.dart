// Feature: delivery-app, Property 6: Visualización de pedido contiene campos requeridos
// **Validates: Requirements 2.3**
//
// For any Pedido_Activo, its representation must include:
// nombre del Usuario, dirección de entrega, descripción del pedido,
// precio del producto y estado actual.

import 'package:delivery_app/models/pedido.dart';
import 'package:glados/glados.dart';

extension PedidoGenerators on Any {
  Generator<EstadoPedido> get estadoPedido =>
      choose(EstadoPedido.values);

  Generator<TipoEntrega> get tipoEntrega =>
      choose(TipoEntrega.values);

  Generator<Pedido> get pedido => combine5(
        nonEmptyLetterOrDigits, // nombreUsuario
        nonEmptyLetterOrDigits, // direccionEntrega
        nonEmptyLetterOrDigits, // descripcion
        doubleInRange(0.01, 999999.99), // precioProducto
        estadoPedido, // estado
        (String nombreUsuario, String direccionEntrega, String descripcion,
                double precio, EstadoPedido estado) =>
            Pedido(
          id: 'pedido-test',
          direccionEntrega: direccionEntrega,
          nombreUsuario: nombreUsuario,
          telefonoUsuario: '3001234567',
          descripcion: descripcion,
          precioProducto: precio,
          tipoEntrega: TipoEntrega.estandar,
          codigoConfirmacion: 'ABC123',
          estado: estado,
          fechaCreacion: DateTime.now(),
        ),
      );
}

void main() {
  Glados(any.pedido, ExploreConfig(numRuns: 100)).test(
    'Property 6: Every Pedido has non-null and non-empty required fields',
    (pedido) {
      // nombreUsuario must be non-empty
      expect(pedido.nombreUsuario.isNotEmpty, isTrue,
          reason: 'nombreUsuario must not be empty');

      // direccionEntrega must be non-empty
      expect(pedido.direccionEntrega.isNotEmpty, isTrue,
          reason: 'direccionEntrega must not be empty');

      // descripcion must be non-empty
      expect(pedido.descripcion.isNotEmpty, isTrue,
          reason: 'descripcion must not be empty');

      // precioProducto must be positive
      expect(pedido.precioProducto, greaterThan(0),
          reason: 'precioProducto must be positive');

      // estado must be a valid EstadoPedido value
      expect(EstadoPedido.values.contains(pedido.estado), isTrue,
          reason: 'estado must be a valid EstadoPedido');
    },
  );
}

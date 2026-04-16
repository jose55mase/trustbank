// Feature: delivery-app, Property 7: Round-trip de completación de pedido
// **Validates: Requirements 3.2, 3.4, 3.5, 9.1, 9.2**
//
// For any active order with assigned repartidor, confirming delivery with
// correct code must: (a) add it to history with all original data plus
// repartidor name, completion date, and receptor name, and (b) remove it
// from active orders.

import 'package:delivery_app/data/mock/mock_pedido_repository.dart';
import 'package:delivery_app/models/pedido.dart';
import 'package:glados/glados.dart';

extension RoundtripGenerators on Any {
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
    'Property 7: Completing an order moves it to history and removes from active',
    (request) async {
      final repo = MockPedidoRepository();

      // Create and assign a repartidor
      final pedido = await repo.crearPedido(request);
      final assigned =
          await repo.asignarRepartidor(pedido.id, 'rep-001');
      expect(assigned.repartidorId, equals('rep-001'));

      // Confirm delivery with correct code
      final result =
          await repo.confirmarEntrega(pedido.id, pedido.codigoConfirmacion);
      expect(result, isTrue, reason: 'Correct code must confirm delivery');

      // (b) Order must be removed from active orders
      final activos = await repo.obtenerPedidosActivos();
      final stillActive = activos.any((p) => p.id == pedido.id);
      expect(stillActive, isFalse,
          reason: 'Completed order must not be in active list');

      // (a) Order must appear in history with original data
      final historial = await repo.obtenerHistorial();
      final histEntry =
          historial.where((h) => h.pedidoOriginalId == pedido.id);
      expect(histEntry.isNotEmpty, isTrue,
          reason: 'Completed order must appear in history');

      final entry = histEntry.first;
      expect(entry.direccionEntrega, equals(pedido.direccionEntrega));
      expect(entry.nombreUsuario, equals(pedido.nombreUsuario));
      expect(entry.telefonoUsuario, equals(pedido.telefonoUsuario));
      expect(entry.descripcion, equals(pedido.descripcion));
      expect(entry.precioProducto, equals(pedido.precioProducto));
      expect(entry.tipoEntrega, equals(pedido.tipoEntrega));
      expect(entry.nombreRepartidor.isNotEmpty, isTrue,
          reason: 'History must include repartidor name');
      expect(entry.fechaCompletacion, isNotNull,
          reason: 'History must include completion date');
      expect(entry.nombreReceptor.isNotEmpty, isTrue,
          reason: 'History must include receptor name');
    },
  );
}

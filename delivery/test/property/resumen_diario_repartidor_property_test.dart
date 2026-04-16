// Feature: delivery-app, Property 18: Resumen diario del repartidor agrega correctamente
// **Validates: Requirements 13.3**
//
// For any Repartidor and set of deliveries completed today, the daily summary
// must show the correct count and correct sum of earnings.

import 'package:delivery_app/data/mock/mock_pedido_repository.dart';
import 'package:delivery_app/data/mock/mock_repartidor_repository.dart';
import 'package:delivery_app/models/pedido.dart';
import 'package:glados/glados.dart';

/// A helper that represents a delivery to be created and completed today.
class DeliverySpec {
  final String direccion;
  final String nombre;
  final String descripcion;
  final double precio;
  final TipoEntrega tipo;

  DeliverySpec({
    required this.direccion,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.tipo,
  });
}

extension DeliveryGenerators on Any {
  Generator<TipoEntrega> get tipoEntrega => choose(TipoEntrega.values);

  Generator<DeliverySpec> get deliverySpec => combine5(
        nonEmptyLetterOrDigits,
        nonEmptyLetterOrDigits,
        nonEmptyLetterOrDigits,
        doubleInRange(100.0, 200000.0),
        tipoEntrega,
        (String dir, String nombre, String desc, double precio,
                TipoEntrega tipo) =>
            DeliverySpec(
          direccion: dir,
          nombre: nombre,
          descripcion: desc,
          precio: precio,
          tipo: tipo,
        ),
      );
}

void main() {
  // Use repartidor rep-001 from mock data
  const repartidorId = 'rep-001';

  Glados(any.listWithLengthInRange(0, 5, any.deliverySpec),
          ExploreConfig(numRuns: 100))
      .test(
    'Property 18: Daily summary correctly aggregates completed deliveries count and earnings',
    (deliveries) async {
      final pedidoRepo = MockPedidoRepository();
      final repartidorRepo = MockRepartidorRepository(pedidoRepo);

      // Create pedidos, assign to repartidor, and confirm them so they
      // appear in today's history.
      final completedPrices = <double>[];

      for (var i = 0; i < deliveries.length; i++) {
        final spec = deliveries[i];
        final phone = '39${i.toString().padLeft(8, '0')}';

        final pedido = await pedidoRepo.crearPedido(CrearPedidoRequest(
          direccionEntrega: spec.direccion,
          nombreUsuario: spec.nombre,
          telefonoUsuario: phone,
          descripcion: spec.descripcion,
          precioProducto: spec.precio,
          tipoEntrega: spec.tipo,
        ));

        await pedidoRepo.asignarRepartidor(pedido.id, repartidorId);
        final confirmed =
            await pedidoRepo.confirmarEntrega(pedido.id, pedido.codigoConfirmacion);

        if (confirmed) {
          completedPrices.add(spec.precio);
        }
      }

      final resumen = await repartidorRepo.obtenerResumenDiario(repartidorId);

      // The count must match the number of deliveries completed today
      expect(resumen.entregasCompletadas, equals(completedPrices.length),
          reason:
              'Daily summary count should equal the number of completed deliveries today');

      // The earnings must equal the sum of prices of completed deliveries
      final expectedEarnings =
          completedPrices.fold<double>(0.0, (sum, p) => sum + p);
      expect(resumen.gananciasDia, closeTo(expectedEarnings, 0.01),
          reason:
              'Daily earnings should equal the sum of prices of completed deliveries');
    },
  );
}

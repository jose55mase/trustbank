// Feature: delivery-app, Property 12: Agregación de ganancias es correcta
// **Validates: Requirements 6.2, 6.3, 6.4, 6.5**
//
// For any set of PedidoHistorial records and any time period (day, month, year),
// reported earnings must equal the sum of product prices of completed orders
// within that period.

import 'package:delivery_app/data/mock/mock_pedido_repository.dart';
import 'package:delivery_app/data/mock/mock_reporte_ganancias_repository.dart';
import 'package:delivery_app/models/pedido.dart';
import 'package:glados/glados.dart';

extension HistorialGenerators on Any {
  Generator<TipoEntrega> get tipoEntrega => choose(TipoEntrega.values);

  Generator<PedidoHistorial> pedidoHistorialInYear(int year) => combine3(
        intInRange(1, 13), // month
        doubleInRange(100.0, 100000.0), // precioProducto
        tipoEntrega,
        (int month, double precio, TipoEntrega tipo) {
          final day = (month == 2) ? 15 : 20;
          return PedidoHistorial(
            id: 'hist-$year-$month-${precio.hashCode}',
            pedidoOriginalId: 'ped-$year-$month',
            direccionEntrega: 'Calle $month, Bogotá',
            nombreUsuario: 'Usuario $month',
            telefonoUsuario: '310${month}000000',
            descripcion: 'Pedido de prueba $month',
            precioProducto: precio,
            tipoEntrega: tipo,
            nombreRepartidor: 'Repartidor $month',
            repartidorId: 'rep-00${(month % 3) + 1}',
            fechaCreacion: DateTime(year, month, day, 10, 0),
            fechaCompletacion: DateTime(year, month, day, 11, 0),
            nombreReceptor: 'Receptor $month',
          );
        },
      );
}

void main() {
  // Property 12: Yearly aggregation — total must equal sum of all product prices
  // for the year, and each year's breakdown must match.
  Glados(
    any.listWithLengthInRange(
        1, 15, any.pedidoHistorialInYear(DateTime.now().year)),
    ExploreConfig(numRuns: 100),
  ).test(
    'Property 12: Earnings aggregation is correct — annual report',
    (records) async {
      final pedidoRepo = MockPedidoRepository(initialHistorial: records);
      final reporteRepo = MockReporteGananciasRepository(pedidoRepo);

      final reporte = await reporteRepo.obtenerReporteAnual();

      // Expected: sum of all records in the current year
      final now = DateTime.now();
      final recordsThisYear = records
          .where((h) => h.fechaCompletacion.year == now.year)
          .toList();
      final expectedTotal =
          recordsThisYear.fold<double>(0.0, (sum, h) => sum + h.precioProducto);

      expect(reporte.totalActual, closeTo(expectedTotal, 0.01),
          reason: 'Annual total must equal sum of product prices');

      // Each year in desglose must match its records
      for (final periodo in reporte.desglose) {
        final year = int.parse(periodo.etiqueta);
        final yearRecords =
            records.where((h) => h.fechaCompletacion.year == year).toList();
        final yearTotal =
            yearRecords.fold<double>(0.0, (sum, h) => sum + h.precioProducto);

        expect(periodo.total, closeTo(yearTotal, 0.01),
            reason: 'Year ${periodo.etiqueta} total must match');
        expect(periodo.cantidadPedidos, equals(yearRecords.length),
            reason: 'Year ${periodo.etiqueta} count must match');
      }
    },
  );

  // Property 12: Monthly aggregation
  Glados(
    any.listWithLengthInRange(
        1, 15, any.pedidoHistorialInYear(DateTime.now().year)),
    ExploreConfig(numRuns: 100),
  ).test(
    'Property 12: Earnings aggregation is correct — monthly report',
    (records) async {
      final pedidoRepo = MockPedidoRepository(initialHistorial: records);
      final reporteRepo = MockReporteGananciasRepository(pedidoRepo);

      final reporte = await reporteRepo.obtenerReporteMensual();

      final now = DateTime.now();
      // Expected: sum of records in current month of current year
      final recordsThisMonth = records
          .where((h) =>
              h.fechaCompletacion.year == now.year &&
              h.fechaCompletacion.month == now.month)
          .toList();
      final expectedTotal = recordsThisMonth.fold<double>(
          0.0, (sum, h) => sum + h.precioProducto);

      expect(reporte.totalActual, closeTo(expectedTotal, 0.01),
          reason: 'Monthly total must equal sum of product prices for current month');

      // Sum of all desglose totals must equal sum of all records in current year
      final recordsThisYear = records
          .where((h) => h.fechaCompletacion.year == now.year)
          .toList();
      final expectedYearTotal = recordsThisYear.fold<double>(
          0.0, (sum, h) => sum + h.precioProducto);
      final desgloseTotal =
          reporte.desglose.fold<double>(0.0, (sum, p) => sum + p.total);

      expect(desgloseTotal, closeTo(expectedYearTotal, 0.01),
          reason: 'Sum of monthly breakdown must equal yearly total');
    },
  );
}

import '../../models/pedido.dart';
import '../../models/reporte.dart';
import '../../repositories/reporte_ganancias_repository.dart';
import 'mock_pedido_repository.dart';

/// Implementación mock de [ReporteGananciasRepository].
/// Calcula ganancias a partir del historial de pedidos completados
/// agrupando por día, mes o año.
class MockReporteGananciasRepository implements ReporteGananciasRepository {
  final MockPedidoRepository _pedidoRepo;

  MockReporteGananciasRepository(this._pedidoRepo);

  @override
  Future<ReporteGanancias> obtenerReporteDiario() async {
    final now = DateTime.now();
    final historial = await _pedidoRepo.obtenerHistorial();

    // Filter to current month for the daily breakdown
    final historialMes = historial
        .where((h) =>
            h.fechaCompletacion.year == now.year &&
            h.fechaCompletacion.month == now.month)
        .toList();

    // Group by day
    final porDia = <int, List<PedidoHistorial>>{};
    for (final h in historialMes) {
      porDia.putIfAbsent(h.fechaCompletacion.day, () => []).add(h);
    }

    // Today's total
    final historialHoy = porDia[now.day] ?? [];
    final totalHoy =
        historialHoy.fold<double>(0.0, (sum, h) => sum + h.precioProducto);

    // Build daily breakdown for the month
    final desglose = porDia.entries.map((entry) {
      final total =
          entry.value.fold<double>(0.0, (sum, h) => sum + h.precioProducto);
      final fecha = DateTime(now.year, now.month, entry.key);
      return GananciaPeriodo(
        etiqueta:
            '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}',
        total: total,
        cantidadPedidos: entry.value.length,
      );
    }).toList()
      ..sort((a, b) => a.etiqueta.compareTo(b.etiqueta));

    return ReporteGanancias(totalActual: totalHoy, desglose: desglose);
  }

  @override
  Future<ReporteGanancias> obtenerReporteMensual() async {
    final now = DateTime.now();
    final historial = await _pedidoRepo.obtenerHistorial();

    // Filter to current year for the monthly breakdown
    final historialAnio = historial
        .where((h) => h.fechaCompletacion.year == now.year)
        .toList();

    // Group by month
    final porMes = <int, List<PedidoHistorial>>{};
    for (final h in historialAnio) {
      porMes.putIfAbsent(h.fechaCompletacion.month, () => []).add(h);
    }

    // Current month total
    final historialMesActual = porMes[now.month] ?? [];
    final totalMes = historialMesActual.fold<double>(
        0.0, (sum, h) => sum + h.precioProducto);

    // Month names in Spanish
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];

    final desglose = porMes.entries.map((entry) {
      final total =
          entry.value.fold<double>(0.0, (sum, h) => sum + h.precioProducto);
      return GananciaPeriodo(
        etiqueta: '${meses[entry.key - 1]} ${now.year}',
        total: total,
        cantidadPedidos: entry.value.length,
      );
    }).toList()
      ..sort((a, b) {
        // Sort by month number
        final monthA = porMes.keys.firstWhere(
            (k) => meses[k - 1] == a.etiqueta.split(' ').first);
        final monthB = porMes.keys.firstWhere(
            (k) => meses[k - 1] == b.etiqueta.split(' ').first);
        return monthA.compareTo(monthB);
      });

    return ReporteGanancias(totalActual: totalMes, desglose: desglose);
  }

  @override
  Future<ReporteGanancias> obtenerReporteAnual() async {
    final now = DateTime.now();
    final historial = await _pedidoRepo.obtenerHistorial();

    // Group by year
    final porAnio = <int, List<PedidoHistorial>>{};
    for (final h in historial) {
      porAnio.putIfAbsent(h.fechaCompletacion.year, () => []).add(h);
    }

    // Current year total
    final historialAnioActual = porAnio[now.year] ?? [];
    final totalAnio = historialAnioActual.fold<double>(
        0.0, (sum, h) => sum + h.precioProducto);

    final desglose = porAnio.entries.map((entry) {
      final total =
          entry.value.fold<double>(0.0, (sum, h) => sum + h.precioProducto);
      return GananciaPeriodo(
        etiqueta: '${entry.key}',
        total: total,
        cantidadPedidos: entry.value.length,
      );
    }).toList()
      ..sort((a, b) => a.etiqueta.compareTo(b.etiqueta));

    return ReporteGanancias(totalActual: totalAnio, desglose: desglose);
  }
}

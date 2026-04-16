import '../models/reporte.dart';

/// Interfaz abstracta para el repositorio de reportes de ganancias.
/// Define el contrato para consultar ganancias por período.
abstract class ReporteGananciasRepository {
  /// Obtiene ganancias del día actual y listado diario del mes
  Future<ReporteGanancias> obtenerReporteDiario();

  /// Obtiene ganancias del mes actual y listado mensual del año
  Future<ReporteGanancias> obtenerReporteMensual();

  /// Obtiene ganancias del año actual y comparativo con años anteriores
  Future<ReporteGanancias> obtenerReporteAnual();
}

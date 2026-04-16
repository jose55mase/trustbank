/// Reporte de ganancias con total y desglose por período.
class ReporteGanancias {
  final double totalActual;
  final List<GananciaPeriodo> desglose;

  const ReporteGanancias({
    required this.totalActual,
    required this.desglose,
  });
}

/// Ganancias de un período específico (día, mes o año).
class GananciaPeriodo {
  final String etiqueta;
  final double total;
  final int cantidadPedidos;

  const GananciaPeriodo({
    required this.etiqueta,
    required this.total,
    required this.cantidadPedidos,
  });
}

/// Resumen diario de un repartidor.
class ResumenDiario {
  final int entregasCompletadas;
  final double gananciasDia;

  const ResumenDiario({
    required this.entregasCompletadas,
    required this.gananciasDia,
  });
}

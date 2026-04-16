import '../models/pedido.dart';
import '../models/repartidor.dart';
import '../models/reporte.dart';

/// Interfaz abstracta para el repositorio de repartidores.
/// Define el contrato para gestión de repartidores, pedidos asignados y resúmenes.
abstract class RepartidorRepository {
  /// Obtiene todos los repartidores (para admin)
  Future<List<Repartidor>> obtenerRepartidores();

  /// Obtiene repartidores disponibles para asignación
  Future<List<Repartidor>> obtenerRepartidoresDisponibles();

  /// Obtiene los pedidos activos asignados a un repartidor
  Future<List<Pedido>> obtenerPedidosAsignados(String repartidorId);

  /// Obtiene el historial de entregas de un repartidor con filtros
  Future<List<PedidoHistorial>> obtenerHistorialRepartidor(
    String repartidorId, {
    DateTime? fechaInicio,
    DateTime? fechaFin,
  });

  /// Obtiene el resumen diario de un repartidor (entregas y ganancias del día)
  Future<ResumenDiario> obtenerResumenDiario(String repartidorId);
}

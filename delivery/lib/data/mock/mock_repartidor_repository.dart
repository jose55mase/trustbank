import '../../models/pedido.dart';
import '../../models/repartidor.dart';
import '../../models/reporte.dart';
import '../../repositories/repartidor_repository.dart';
import 'mock_data.dart';
import 'mock_pedido_repository.dart';

/// Implementación mock de [RepartidorRepository].
/// Usa datos de [mockRepartidores] y delega al [MockPedidoRepository]
/// para acceder a pedidos activos e historial.
class MockRepartidorRepository implements RepartidorRepository {
  final MockPedidoRepository _pedidoRepo;

  MockRepartidorRepository(this._pedidoRepo);

  @override
  Future<List<Repartidor>> obtenerRepartidores() async {
    return List.of(mockRepartidores);
  }

  @override
  Future<List<Repartidor>> obtenerRepartidoresDisponibles() async {
    return mockRepartidores
        .where((r) => r.estado == EstadoRepartidor.disponible)
        .toList();
  }

  @override
  Future<List<Pedido>> obtenerPedidosAsignados(String repartidorId) async {
    final activos = await _pedidoRepo.obtenerPedidosActivos();
    return activos.where((p) => p.repartidorId == repartidorId).toList();
  }

  @override
  Future<List<PedidoHistorial>> obtenerHistorialRepartidor(
    String repartidorId, {
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    return _pedidoRepo.obtenerHistorial(
      repartidorId: repartidorId,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );
  }

  @override
  Future<ResumenDiario> obtenerResumenDiario(String repartidorId) async {
    final now = DateTime.now();
    final inicioDelDia = DateTime(now.year, now.month, now.day);
    final finDelDia = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    final historialHoy = await _pedidoRepo.obtenerHistorial(
      repartidorId: repartidorId,
      fechaInicio: inicioDelDia,
      fechaFin: finDelDia,
    );

    final gananciasDia =
        historialHoy.fold<double>(0.0, (sum, h) => sum + h.precioProducto);

    return ResumenDiario(
      entregasCompletadas: historialHoy.length,
      gananciasDia: gananciasDia,
    );
  }
}

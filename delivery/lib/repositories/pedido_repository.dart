import '../models/pedido.dart';

/// Interfaz abstracta para el repositorio de pedidos.
/// Define el contrato entre la capa de dominio y la capa de datos.
abstract class PedidoRepository {
  /// Crea un nuevo pedido activo y retorna el pedido con su código de confirmación
  Future<Pedido> crearPedido(CrearPedidoRequest request);

  /// Obtiene todos los pedidos activos (para admin)
  Future<List<Pedido>> obtenerPedidosActivos();

  /// Obtiene el pedido activo de un usuario por su teléfono
  Future<Pedido?> obtenerPedidoActivoPorUsuario(String telefono);

  /// Asigna un repartidor a un pedido activo
  Future<Pedido> asignarRepartidor(String pedidoId, String repartidorId);

  /// Actualiza el estado de un pedido (recogido, en_camino, en_destino)
  Future<Pedido> actualizarEstadoPedido(String pedidoId, EstadoPedido estado);

  /// Confirma la entrega con el código de confirmación.
  /// Mueve el pedido de activos a historial.
  /// Retorna true si el código es correcto, false si no.
  Future<bool> confirmarEntrega(String pedidoId, String codigoConfirmacion);

  /// Obtiene el historial de pedidos completados con filtros opcionales
  Future<List<PedidoHistorial>> obtenerHistorial({
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? repartidorId,
    String? telefonoUsuario,
  });

  /// Obtiene el historial de pedidos de un usuario específico
  Future<List<PedidoHistorial>> obtenerHistorialUsuario(String telefono);
}

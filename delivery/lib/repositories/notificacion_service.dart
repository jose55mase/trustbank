import '../models/pedido.dart';

/// Interfaz abstracta para el servicio de notificaciones.
/// Define el contrato para enviar notificaciones al usuario sobre cambios en pedidos.
abstract class NotificacionService {
  /// Notifica al usuario que un repartidor fue asignado
  Future<void> notificarRepartidorAsignado(
      String telefono, String nombreRepartidor);

  /// Notifica al usuario un cambio de estado del pedido
  Future<void> notificarCambioEstado(String telefono, EstadoPedido nuevoEstado);

  /// Notifica al usuario que la entrega fue completada
  Future<void> notificarEntregaCompletada(String telefono);
}

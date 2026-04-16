import '../../models/pedido.dart';
import '../../repositories/notificacion_service.dart';

/// Representa una notificación almacenada en memoria.
class Notificacion {
  final String telefono;
  final String titulo;
  final String mensaje;
  final DateTime timestamp;

  const Notificacion({
    required this.telefono,
    required this.titulo,
    required this.mensaje,
    required this.timestamp,
  });
}

/// Implementación mock de [NotificacionService].
/// Almacena notificaciones en memoria para testing y las imprime en consola.
class MockNotificacionService implements NotificacionService {
  final List<Notificacion> _notificaciones = [];

  /// Returns all stored notifications (for testing).
  List<Notificacion> get notificaciones => List.unmodifiable(_notificaciones);

  /// Returns notifications for a specific phone number.
  List<Notificacion> notificacionesPorTelefono(String telefono) =>
      _notificaciones.where((n) => n.telefono == telefono).toList();

  @override
  Future<void> notificarRepartidorAsignado(
    String telefono,
    String nombreRepartidor,
  ) async {
    final notificacion = Notificacion(
      telefono: telefono,
      titulo: 'Repartidor asignado',
      mensaje: '$nombreRepartidor ha sido asignado a tu pedido.',
      timestamp: DateTime.now(),
    );
    _notificaciones.add(notificacion);
    // ignore: avoid_print
    print('[Notificación] $telefono: ${notificacion.titulo} - ${notificacion.mensaje}');
  }

  @override
  Future<void> notificarCambioEstado(
    String telefono,
    EstadoPedido nuevoEstado,
  ) async {
    final descripcionEstado = _descripcionEstado(nuevoEstado);
    final notificacion = Notificacion(
      telefono: telefono,
      titulo: 'Estado actualizado',
      mensaje: 'Tu pedido ahora está: $descripcionEstado.',
      timestamp: DateTime.now(),
    );
    _notificaciones.add(notificacion);
    // ignore: avoid_print
    print('[Notificación] $telefono: ${notificacion.titulo} - ${notificacion.mensaje}');
  }

  @override
  Future<void> notificarEntregaCompletada(String telefono) async {
    final notificacion = Notificacion(
      telefono: telefono,
      titulo: 'Entrega completada',
      mensaje: 'Tu pedido ha sido entregado exitosamente.',
      timestamp: DateTime.now(),
    );
    _notificaciones.add(notificacion);
    // ignore: avoid_print
    print('[Notificación] $telefono: ${notificacion.titulo} - ${notificacion.mensaje}');
  }

  String _descripcionEstado(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.pendiente:
        return 'pendiente';
      case EstadoPedido.asignado:
        return 'asignado';
      case EstadoPedido.recogido:
        return 'recogido';
      case EstadoPedido.enCamino:
        return 'en camino';
      case EstadoPedido.enDestino:
        return 'en destino';
      case EstadoPedido.completado:
        return 'completado';
    }
  }
}

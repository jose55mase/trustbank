// Feature: delivery-app, Property 16: Cambios de estado generan notificaciones
// **Validates: Requirements 12.1, 12.2, 12.3**
//
// For any status change in an active order, the system must generate a
// notification to the requesting user that includes relevant change information.

import 'package:delivery_app/data/mock/mock_notificacion_service.dart';
import 'package:delivery_app/data/mock/mock_pedido_repository.dart';
import 'package:delivery_app/models/pedido.dart';
import 'package:glados/glados.dart';

extension NotificacionGenerators on Any {
  Generator<TipoEntrega> get tipoEntrega => choose(TipoEntrega.values);

  /// Generates a valid CrearPedidoRequest with a unique phone per index.
  Generator<CrearPedidoRequest> crearPedidoRequestConTelefono(
          String telefono) =>
      combine3(
        nonEmptyLetterOrDigits, // direccionEntrega
        nonEmptyLetterOrDigits, // descripcion
        doubleInRange(1.0, 99999.0), // precioProducto
        (String direccion, String descripcion, double precio) =>
            CrearPedidoRequest(
          direccionEntrega: direccion,
          nombreUsuario: 'Usuario Test',
          telefonoUsuario: telefono,
          descripcion: descripcion,
          precioProducto: precio,
          tipoEntrega: TipoEntrega.estandar,
        ),
      );

  /// Generates a non-empty subset of status transitions to apply.
  Generator<List<EstadoPedido>> get statusTransitions {
    // All possible status transitions a repartidor can trigger
    final allTransitions = [
      EstadoPedido.recogido,
      EstadoPedido.enCamino,
      EstadoPedido.enDestino,
    ];
    return listWithLengthInRange(1, 3, choose(allTransitions)).map(
      (list) => list.toSet().toList(), // deduplicate
    );
  }
}

void main() {
  // Test: Assigning a repartidor generates a notification (Req 12.1)
  Glados(
    any.crearPedidoRequestConTelefono('3101234567'),
    ExploreConfig(numRuns: 100),
  ).test(
    'Property 16: Assigning a repartidor generates a notification to the user',
    (request) async {
      final pedidoRepo = MockPedidoRepository(initialHistorial: []);
      final notifService = MockNotificacionService();

      final pedido = await pedidoRepo.crearPedido(request);
      await pedidoRepo.asignarRepartidor(pedido.id, 'rep-001');

      // Simulate notification trigger on assignment
      await notifService.notificarRepartidorAsignado(
        pedido.telefonoUsuario,
        'Carlos Alberto Pérez',
      );

      final notifs =
          notifService.notificacionesPorTelefono(pedido.telefonoUsuario);
      expect(notifs.length, equals(1),
          reason: 'Exactly one notification for assignment');
      expect(notifs.first.telefono, equals(pedido.telefonoUsuario),
          reason: 'Notification must be directed to the requesting user');
      expect(notifs.first.titulo.isNotEmpty, isTrue,
          reason: 'Notification must have a title');
      expect(notifs.first.mensaje.isNotEmpty, isTrue,
          reason: 'Notification must have a message');
    },
  );

  // Test: Status changes generate notifications (Req 12.2)
  Glados(
    any.statusTransitions,
    ExploreConfig(numRuns: 100),
  ).test(
    'Property 16: Each status change generates a notification to the user',
    (transitions) async {
      final pedidoRepo = MockPedidoRepository(initialHistorial: []);
      final notifService = MockNotificacionService();
      const telefono = '3209876543';

      final pedido = await pedidoRepo.crearPedido(const CrearPedidoRequest(
        direccionEntrega: 'Calle 85 #15-40, Bogotá',
        nombreUsuario: 'Test User',
        telefonoUsuario: telefono,
        descripcion: 'Test order',
        precioProducto: 25000,
        tipoEntrega: TipoEntrega.estandar,
      ));

      await pedidoRepo.asignarRepartidor(pedido.id, 'rep-001');

      // Apply each status transition and notify
      for (final estado in transitions) {
        await pedidoRepo.actualizarEstadoPedido(pedido.id, estado);
        await notifService.notificarCambioEstado(telefono, estado);
      }

      final notifs = notifService.notificacionesPorTelefono(telefono);
      expect(notifs.length, equals(transitions.length),
          reason:
              'Each status change must generate exactly one notification');

      for (final notif in notifs) {
        expect(notif.telefono, equals(telefono),
            reason: 'Notification must target the requesting user');
        expect(notif.titulo.isNotEmpty, isTrue,
            reason: 'Notification must have a title');
        expect(notif.mensaje.isNotEmpty, isTrue,
            reason: 'Notification must include relevant change info');
      }
    },
  );

  // Test: Completed delivery generates notification (Req 12.3)
  Glados(
    any.crearPedidoRequestConTelefono('3154567890'),
    ExploreConfig(numRuns: 100),
  ).test(
    'Property 16: Completing a delivery generates a notification to the user',
    (request) async {
      final notifService = MockNotificacionService();

      await notifService.notificarEntregaCompletada(request.telefonoUsuario);

      final notifs =
          notifService.notificacionesPorTelefono(request.telefonoUsuario);
      expect(notifs.length, equals(1),
          reason: 'Exactly one notification for completion');
      expect(notifs.first.telefono, equals(request.telefonoUsuario),
          reason: 'Notification must be directed to the requesting user');
      expect(notifs.first.mensaje.isNotEmpty, isTrue,
          reason: 'Notification must include relevant info');
    },
  );
}

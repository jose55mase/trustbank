import 'package:uuid/uuid.dart';

import '../../models/pedido.dart';
import '../../models/repartidor.dart';
import '../../repositories/pedido_repository.dart';
import 'mock_data.dart';

/// Implementación mock de [PedidoRepository].
/// Mantiene pedidos activos e historial en memoria.
class MockPedidoRepository implements PedidoRepository {
  final _uuid = const Uuid();
  final List<Pedido> _pedidosActivos = [];
  final List<PedidoHistorial> _historial;

  /// Creates a mock repository. Optionally accepts [initialHistorial]
  /// for testing; defaults to [mockHistorial].
  MockPedidoRepository({List<PedidoHistorial>? initialHistorial})
      : _historial = List.of(initialHistorial ?? mockHistorial);

  @override
  Future<Pedido> crearPedido(CrearPedidoRequest request) async {
    // Validar campos obligatorios
    final camposFaltantes = <String>[];
    if (request.direccionEntrega.trim().isEmpty) {
      camposFaltantes.add('direccionEntrega');
    }
    if (request.nombreUsuario.trim().isEmpty) {
      camposFaltantes.add('nombreUsuario');
    }
    if (request.telefonoUsuario.trim().isEmpty) {
      camposFaltantes.add('telefonoUsuario');
    }
    if (request.descripcion.trim().isEmpty) {
      camposFaltantes.add('descripcion');
    }
    if (request.precioProducto <= 0) {
      camposFaltantes.add('precioProducto');
    }
    if (camposFaltantes.isNotEmpty) {
      throw Exception(
        'Campos obligatorios faltantes: ${camposFaltantes.join(', ')}',
      );
    }

    // Validar que el usuario no tenga un pedido activo
    final existente = _pedidosActivos.any(
      (p) => p.telefonoUsuario == request.telefonoUsuario,
    );
    if (existente) {
      throw Exception(
        'El usuario ya tiene un pedido activo. Debe esperar a que se complete.',
      );
    }

    final pedido = Pedido(
      id: _uuid.v4(),
      direccionEntrega: request.direccionEntrega,
      nombreUsuario: request.nombreUsuario,
      telefonoUsuario: request.telefonoUsuario,
      descripcion: request.descripcion,
      precioProducto: request.precioProducto,
      tipoEntrega: request.tipoEntrega,
      codigoConfirmacion: _uuid.v4().substring(0, 6).toUpperCase(),
      estado: EstadoPedido.pendiente,
      fechaCreacion: DateTime.now(),
    );

    _pedidosActivos.add(pedido);
    return pedido;
  }

  @override
  Future<List<Pedido>> obtenerPedidosActivos() async {
    final sorted = List<Pedido>.of(_pedidosActivos)
      ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
    return sorted;
  }

  @override
  Future<Pedido?> obtenerPedidoActivoPorUsuario(String telefono) async {
    try {
      return _pedidosActivos.firstWhere(
        (p) => p.telefonoUsuario == telefono,
      );
    } on StateError {
      return null;
    }
  }

  @override
  Future<Pedido> asignarRepartidor(
    String pedidoId,
    String repartidorId,
  ) async {
    final index = _pedidosActivos.indexWhere((p) => p.id == pedidoId);
    if (index == -1) {
      throw Exception('Pedido no encontrado: $pedidoId');
    }

    final actualizado = _pedidosActivos[index].copyWith(
      estado: EstadoPedido.asignado,
      repartidorId: repartidorId,
    );
    _pedidosActivos[index] = actualizado;
    return actualizado;
  }

  @override
  Future<Pedido> actualizarEstadoPedido(
    String pedidoId,
    EstadoPedido estado,
  ) async {
    final index = _pedidosActivos.indexWhere((p) => p.id == pedidoId);
    if (index == -1) {
      throw Exception('Pedido no encontrado: $pedidoId');
    }

    final actualizado = _pedidosActivos[index].copyWith(estado: estado);
    _pedidosActivos[index] = actualizado;
    return actualizado;
  }

  @override
  Future<bool> confirmarEntrega(
    String pedidoId,
    String codigoConfirmacion,
  ) async {
    final index = _pedidosActivos.indexWhere((p) => p.id == pedidoId);
    if (index == -1) {
      throw Exception('Pedido no encontrado: $pedidoId');
    }

    final pedido = _pedidosActivos[index];
    if (pedido.codigoConfirmacion != codigoConfirmacion) {
      return false;
    }

    // Buscar nombre del repartidor
    final repartidor = mockRepartidores.cast<Repartidor?>().firstWhere(
          (r) => r!.id == pedido.repartidorId,
          orElse: () => null,
        );

    final historial = PedidoHistorial(
      id: _uuid.v4(),
      pedidoOriginalId: pedido.id,
      direccionEntrega: pedido.direccionEntrega,
      nombreUsuario: pedido.nombreUsuario,
      telefonoUsuario: pedido.telefonoUsuario,
      descripcion: pedido.descripcion,
      precioProducto: pedido.precioProducto,
      tipoEntrega: pedido.tipoEntrega,
      nombreRepartidor: repartidor?.nombreCompleto ?? 'Desconocido',
      repartidorId: pedido.repartidorId ?? '',
      fechaCreacion: pedido.fechaCreacion,
      fechaCompletacion: DateTime.now(),
      nombreReceptor: pedido.nombreUsuario,
    );

    _historial.add(historial);
    _pedidosActivos.removeAt(index);
    return true;
  }

  @override
  Future<List<PedidoHistorial>> obtenerHistorial({
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? repartidorId,
    String? telefonoUsuario,
  }) async {
    return _historial.where((h) {
      if (fechaInicio != null && h.fechaCompletacion.isBefore(fechaInicio)) {
        return false;
      }
      if (fechaFin != null && h.fechaCompletacion.isAfter(fechaFin)) {
        return false;
      }
      if (repartidorId != null && h.repartidorId != repartidorId) {
        return false;
      }
      if (telefonoUsuario != null && h.telefonoUsuario != telefonoUsuario) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<List<PedidoHistorial>> obtenerHistorialUsuario(
    String telefono,
  ) async {
    return _historial.where((h) => h.telefonoUsuario == telefono).toList();
  }
}

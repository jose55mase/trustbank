/// Estados posibles de un pedido activo.
enum EstadoPedido {
  pendiente,
  asignado,
  recogido,
  enCamino,
  enDestino,
  completado,
}

/// Tipos de entrega disponibles.
enum TipoEntrega {
  estandar,
  express,
}

/// Representa un pedido activo en el sistema.
class Pedido {
  final String id;
  final String direccionEntrega;
  final String nombreUsuario;
  final String telefonoUsuario;
  final String descripcion;
  final double precioProducto;
  final TipoEntrega tipoEntrega;
  final String codigoConfirmacion;
  final EstadoPedido estado;
  final String? repartidorId;
  final DateTime fechaCreacion;

  const Pedido({
    required this.id,
    required this.direccionEntrega,
    required this.nombreUsuario,
    required this.telefonoUsuario,
    required this.descripcion,
    required this.precioProducto,
    required this.tipoEntrega,
    required this.codigoConfirmacion,
    required this.estado,
    this.repartidorId,
    required this.fechaCreacion,
  });

  Pedido copyWith({
    String? id,
    String? direccionEntrega,
    String? nombreUsuario,
    String? telefonoUsuario,
    String? descripcion,
    double? precioProducto,
    TipoEntrega? tipoEntrega,
    String? codigoConfirmacion,
    EstadoPedido? estado,
    String? repartidorId,
    DateTime? fechaCreacion,
  }) {
    return Pedido(
      id: id ?? this.id,
      direccionEntrega: direccionEntrega ?? this.direccionEntrega,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      telefonoUsuario: telefonoUsuario ?? this.telefonoUsuario,
      descripcion: descripcion ?? this.descripcion,
      precioProducto: precioProducto ?? this.precioProducto,
      tipoEntrega: tipoEntrega ?? this.tipoEntrega,
      codigoConfirmacion: codigoConfirmacion ?? this.codigoConfirmacion,
      estado: estado ?? this.estado,
      repartidorId: repartidorId ?? this.repartidorId,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}

/// Request para crear un nuevo pedido.
class CrearPedidoRequest {
  final String direccionEntrega;
  final String nombreUsuario;
  final String telefonoUsuario;
  final String descripcion;
  final double precioProducto;
  final TipoEntrega tipoEntrega;

  const CrearPedidoRequest({
    required this.direccionEntrega,
    required this.nombreUsuario,
    required this.telefonoUsuario,
    required this.descripcion,
    required this.precioProducto,
    required this.tipoEntrega,
  });
}

/// Registro de un pedido completado en el historial.
class PedidoHistorial {
  final String id;
  final String pedidoOriginalId;
  final String direccionEntrega;
  final String nombreUsuario;
  final String telefonoUsuario;
  final String descripcion;
  final double precioProducto;
  final TipoEntrega tipoEntrega;
  final String nombreRepartidor;
  final String repartidorId;
  final DateTime fechaCreacion;
  final DateTime fechaCompletacion;
  final String nombreReceptor;

  const PedidoHistorial({
    required this.id,
    required this.pedidoOriginalId,
    required this.direccionEntrega,
    required this.nombreUsuario,
    required this.telefonoUsuario,
    required this.descripcion,
    required this.precioProducto,
    required this.tipoEntrega,
    required this.nombreRepartidor,
    required this.repartidorId,
    required this.fechaCreacion,
    required this.fechaCompletacion,
    required this.nombreReceptor,
  });
}

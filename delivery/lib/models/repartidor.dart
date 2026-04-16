/// Estados posibles de un repartidor.
enum EstadoRepartidor {
  disponible,
  enEntrega,
  inactivo,
}

/// Representa un repartidor del sistema.
class Repartidor {
  final String id;
  final String nombreCompleto;
  final int totalEntregas;
  final EstadoRepartidor estado;
  final String usuario;
  final String password;

  const Repartidor({
    required this.id,
    required this.nombreCompleto,
    required this.totalEntregas,
    required this.estado,
    required this.usuario,
    required this.password,
  });

  Repartidor copyWith({
    String? id,
    String? nombreCompleto,
    int? totalEntregas,
    EstadoRepartidor? estado,
    String? usuario,
    String? password,
  }) {
    return Repartidor(
      id: id ?? this.id,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      totalEntregas: totalEntregas ?? this.totalEntregas,
      estado: estado ?? this.estado,
      usuario: usuario ?? this.usuario,
      password: password ?? this.password,
    );
  }
}

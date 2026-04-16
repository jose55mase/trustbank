/// Representa un usuario que solicita entregas.
/// Se identifica por su número de teléfono (sin registro).
class Usuario {
  final String telefono;
  final String nombre;

  const Usuario({
    required this.telefono,
    required this.nombre,
  });
}

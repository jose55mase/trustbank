/// Representa una ubicación geográfica con marca de tiempo.
class Ubicacion {
  final double latitud;
  final double longitud;
  final DateTime timestamp;

  const Ubicacion({
    required this.latitud,
    required this.longitud,
    required this.timestamp,
  });
}

import '../models/ubicacion.dart';

/// Interfaz abstracta para el repositorio de geolocalización.
/// Define el contrato para rastreo de ubicación de repartidores.
abstract class GeolocalizacionRepository {
  /// Inicia el rastreo de ubicación de un repartidor para un pedido
  Future<void> iniciarRastreo(String repartidorId, String pedidoId);

  /// Detiene el rastreo de ubicación
  Future<void> detenerRastreo(String repartidorId, String pedidoId);

  /// Obtiene la ubicación actual del repartidor
  Future<Ubicacion?> obtenerUbicacion(String repartidorId);

  /// Stream de actualizaciones de ubicación (cada 10 segundos)
  Stream<Ubicacion> streamUbicacion(String repartidorId);
}

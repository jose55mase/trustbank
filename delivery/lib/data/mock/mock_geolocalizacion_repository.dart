import 'dart:async';
import 'dart:math';

import '../../models/ubicacion.dart';
import '../../repositories/geolocalizacion_repository.dart';

/// Implementación mock de [GeolocalizacionRepository].
/// Simula rastreo de ubicación con coordenadas aleatorias alrededor de Bogotá.
/// Emite ubicaciones cada 10 segundos mientras el rastreo está activo.
class MockGeolocalizacionRepository implements GeolocalizacionRepository {
  final _random = Random();

  /// Base coordinates: Bogotá, Colombia
  static const double _baseLat = 4.6;
  static const double _baseLng = -74.08;
  static const double _offsetRange = 0.02;

  /// Active tracking streams keyed by repartidorId.
  final Map<String, StreamController<Ubicacion>> _controllers = {};

  /// Active tracking timers keyed by repartidorId.
  final Map<String, Timer> _timers = {};

  /// Last known location per repartidor.
  final Map<String, Ubicacion> _lastUbicacion = {};

  /// Tracking keys: "repartidorId:pedidoId" to link tracking to orders.
  final Map<String, String> _trackingKeys = {};

  Ubicacion _generateRandomUbicacion() {
    final lat = _baseLat + (_random.nextDouble() * 2 - 1) * _offsetRange;
    final lng = _baseLng + (_random.nextDouble() * 2 - 1) * _offsetRange;
    return Ubicacion(latitud: lat, longitud: lng, timestamp: DateTime.now());
  }

  @override
  Future<void> iniciarRastreo(String repartidorId, String pedidoId) async {
    final key = '$repartidorId:$pedidoId';
    _trackingKeys[repartidorId] = key;

    // Create controller if not already tracking this repartidor
    if (!_controllers.containsKey(repartidorId)) {
      _controllers[repartidorId] = StreamController<Ubicacion>.broadcast();
    }

    // Cancel existing timer if any
    _timers[repartidorId]?.cancel();

    // Emit initial location immediately
    final initial = _generateRandomUbicacion();
    _lastUbicacion[repartidorId] = initial;
    _controllers[repartidorId]?.add(initial);

    // Emit new location every 10 seconds
    _timers[repartidorId] = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        final ubicacion = _generateRandomUbicacion();
        _lastUbicacion[repartidorId] = ubicacion;
        if (_controllers.containsKey(repartidorId) &&
            !_controllers[repartidorId]!.isClosed) {
          _controllers[repartidorId]!.add(ubicacion);
        }
      },
    );
  }

  @override
  Future<void> detenerRastreo(String repartidorId, String pedidoId) async {
    _timers[repartidorId]?.cancel();
    _timers.remove(repartidorId);

    if (_controllers.containsKey(repartidorId)) {
      await _controllers[repartidorId]!.close();
      _controllers.remove(repartidorId);
    }

    _trackingKeys.remove(repartidorId);
  }

  @override
  Future<Ubicacion?> obtenerUbicacion(String repartidorId) async {
    return _lastUbicacion[repartidorId];
  }

  @override
  Stream<Ubicacion> streamUbicacion(String repartidorId) {
    if (!_controllers.containsKey(repartidorId)) {
      _controllers[repartidorId] = StreamController<Ubicacion>.broadcast();
    }
    return _controllers[repartidorId]!.stream;
  }

  /// Dispose all resources. Call when the repository is no longer needed.
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }
}

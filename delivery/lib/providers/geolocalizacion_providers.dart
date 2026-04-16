import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ubicacion.dart';
import '../repositories/geolocalizacion_repository.dart';

/// Provider for the GeolocalizacionRepository interface.
/// Override this in main.dart with the mock (or real) implementation.
final geolocalizacionRepositoryProvider =
    Provider<GeolocalizacionRepository>((ref) {
  throw UnimplementedError(
    'geolocalizacionRepositoryProvider must be overridden with a concrete implementation',
  );
});

/// Stream of real-time location updates for a specific repartidor.
/// Validates: Requisitos 7.1, 7.2, 7.3
final ubicacionStreamProvider =
    StreamProvider.family<Ubicacion, String>((ref, repartidorId) {
  final repo = ref.watch(geolocalizacionRepositoryProvider);
  return repo.streamUbicacion(repartidorId);
});

/// Fetches the last known location for a specific repartidor.
final ubicacionActualProvider =
    FutureProvider.family<Ubicacion?, String>((ref, repartidorId) {
  final repo = ref.watch(geolocalizacionRepositoryProvider);
  return repo.obtenerUbicacion(repartidorId);
});

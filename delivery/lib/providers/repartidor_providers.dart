import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pedido.dart';
import '../models/repartidor.dart';
import '../models/reporte.dart';
import '../repositories/repartidor_repository.dart';

/// Provider for the RepartidorRepository interface.
/// Override this in main.dart with the mock (or real) implementation.
final repartidorRepositoryProvider = Provider<RepartidorRepository>((ref) {
  throw UnimplementedError(
    'repartidorRepositoryProvider must be overridden with a concrete implementation',
  );
});

/// Fetches all repartidores (for admin panel).
/// Validates: Requisitos 4.1
final repartidoresProvider = FutureProvider<List<Repartidor>>((ref) {
  final repo = ref.watch(repartidorRepositoryProvider);
  return repo.obtenerRepartidores();
});

/// Fetches repartidores available for assignment.
final repartidoresDisponiblesProvider =
    FutureProvider<List<Repartidor>>((ref) {
  final repo = ref.watch(repartidorRepositoryProvider);
  return repo.obtenerRepartidoresDisponibles();
});

/// Fetches active pedidos assigned to a specific repartidor.
/// Validates: Requisitos 13.1
final pedidosAsignadosProvider =
    FutureProvider.family<List<Pedido>, String>((ref, repartidorId) {
  final repo = ref.watch(repartidorRepositoryProvider);
  return repo.obtenerPedidosAsignados(repartidorId);
});

/// Fetches the daily summary for a specific repartidor.
/// Validates: Requisitos 13.3
final resumenDiarioProvider =
    FutureProvider.family<ResumenDiario, String>((ref, repartidorId) {
  final repo = ref.watch(repartidorRepositoryProvider);
  return repo.obtenerResumenDiario(repartidorId);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pedido.dart';
import '../repositories/pedido_repository.dart';

/// Provider for the PedidoRepository interface.
/// Override this in main.dart with the mock (or real) implementation.
final pedidoRepositoryProvider = Provider<PedidoRepository>((ref) {
  throw UnimplementedError(
    'pedidoRepositoryProvider must be overridden with a concrete implementation',
  );
});

/// Fetches all active pedidos, sorted by date descending.
/// Validates: Requisitos 2.1
final pedidosActivosProvider = FutureProvider<List<Pedido>>((ref) {
  final repo = ref.watch(pedidoRepositoryProvider);
  return repo.obtenerPedidosActivos();
});

/// Fetches the full order history with optional filters.
/// Validates: Requisitos 9.1
final historialPedidosProvider = FutureProvider<List<PedidoHistorial>>((ref) {
  final repo = ref.watch(pedidoRepositoryProvider);
  return repo.obtenerHistorial();
});

/// Fetches the active pedido for a specific user by phone number.
/// Validates: Requisitos 1.2
final pedidoActivoUsuarioProvider =
    FutureProvider.family<Pedido?, String>((ref, telefono) {
  final repo = ref.watch(pedidoRepositoryProvider);
  return repo.obtenerPedidoActivoPorUsuario(telefono);
});

/// Fetches the order history for a specific user by phone number.
final historialUsuarioProvider =
    FutureProvider.family<List<PedidoHistorial>, String>((ref, telefono) {
  final repo = ref.watch(pedidoRepositoryProvider);
  return repo.obtenerHistorialUsuario(telefono);
});

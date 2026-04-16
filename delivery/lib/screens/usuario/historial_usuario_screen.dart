import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/pedido.dart';
import '../../providers/pedido_providers.dart';

/// Pantalla de historial de pedidos completados del usuario.
/// Filtra por teléfono para mostrar solo los pedidos del usuario.
///
/// Requisitos: 8.1, 8.4
class HistorialUsuarioScreen extends ConsumerWidget {
  final String telefono;

  const HistorialUsuarioScreen({super.key, required this.telefono});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historialAsync = ref.watch(historialUsuarioProvider(telefono));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Historial'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: historialAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: AppTheme.error),
          ),
        ),
        data: (historial) {
          if (historial.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64, color: AppTheme.textHint),
                  SizedBox(height: 16),
                  Text(
                    'No tienes pedidos completados',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: historial.length,
            itemBuilder: (context, index) =>
                _HistorialCard(pedido: historial[index]),
          );
        },
      ),
    );
  }
}

class _HistorialCard extends StatelessWidget {
  final PedidoHistorial pedido;

  const _HistorialCard({required this.pedido});

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: description + price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    pedido.descripcion,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '\$${pedido.precioProducto.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Address
            Row(
              children: [
                const Icon(Icons.location_on,
                    size: 16, color: AppTheme.textHint),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    pedido.direccionEntrega,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Repartidor
            Row(
              children: [
                const Icon(Icons.delivery_dining,
                    size: 16, color: AppTheme.textHint),
                const SizedBox(width: 4),
                Text(
                  pedido.nombreRepartidor,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Tipo de entrega
            Row(
              children: [
                const Icon(Icons.local_shipping,
                    size: 16, color: AppTheme.textHint),
                const SizedBox(width: 4),
                Text(
                  pedido.tipoEntrega == TipoEntrega.express
                      ? 'Express'
                      : 'Estándar',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Dates
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Creado: ${_formatDate(pedido.fechaCreacion)}',
                  style: const TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 11,
                  ),
                ),
                Text(
                  'Completado: ${_formatDate(pedido.fechaCompletacion)}',
                  style: const TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/pedido.dart';
import '../../providers/auth_providers.dart';
import '../../providers/repartidor_providers.dart';

/// Panel principal del repartidor.
/// Muestra pedidos activos asignados, resumen diario y opción de logout.
///
/// Requisitos: 13.1, 13.3, 13.4
class PanelRepartidorScreen extends ConsumerWidget {
  const PanelRepartidorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesionAsync = ref.watch(sesionActivaProvider);

    return sesionAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (sesion) {
        if (sesion == null) {
          return const Scaffold(
            body: Center(child: Text('Sesión no encontrada')),
          );
        }
        return _PanelContent(repartidorId: sesion.userId);
      },
    );
  }
}

class _PanelContent extends ConsumerWidget {
  final String repartidorId;

  const _PanelContent({required this.repartidorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pedidosAsync = ref.watch(pedidosAsignadosProvider(repartidorId));
    final resumenAsync = ref.watch(resumenDiarioProvider(repartidorId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Repartidor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              final repo = ref.read(authRepositoryProvider);
              await repo.logout();
              ref.invalidate(sesionActivaProvider);
              if (context.mounted) {
                context.go('/');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(pedidosAsignadosProvider(repartidorId));
          ref.invalidate(resumenDiarioProvider(repartidorId));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Daily summary (Req 13.3)
            resumenAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error cargando resumen: $e'),
                ),
              ),
              data: (resumen) => Card(
                color: AppTheme.surfaceVariant,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: AppTheme.success,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${resumen.entregasCompletadas}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const Text(
                              'Entregas hoy',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 60,
                        color: AppTheme.divider,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.attach_money,
                              color: AppTheme.accent,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '\$${resumen.gananciasDia.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const Text(
                              'Ganancias hoy',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Section title
            const Text(
              'Pedidos Asignados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Active orders list (Req 13.1, 13.4)
            pedidosAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('Error cargando pedidos: $e'),
                ),
              ),
              data: (pedidos) {
                if (pedidos.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: AppTheme.textHint,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay entregas pendientes',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: pedidos
                      .map((pedido) => _PedidoCard(pedido: pedido))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PedidoCard extends StatelessWidget {
  final Pedido pedido;

  const _PedidoCard({required this.pedido});

  String _estadoLabel(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.pendiente:
        return 'Pendiente';
      case EstadoPedido.asignado:
        return 'Asignado';
      case EstadoPedido.recogido:
        return 'Recogido';
      case EstadoPedido.enCamino:
        return 'En camino';
      case EstadoPedido.enDestino:
        return 'En destino';
      case EstadoPedido.completado:
        return 'Completado';
    }
  }

  Color _estadoColor(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.pendiente:
        return AppTheme.warning;
      case EstadoPedido.asignado:
        return AppTheme.primary;
      case EstadoPedido.recogido:
        return AppTheme.primaryLight;
      case EstadoPedido.enCamino:
        return AppTheme.accent;
      case EstadoPedido.enDestino:
        return AppTheme.success;
      case EstadoPedido.completado:
        return AppTheme.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/repartidor/detalle/${pedido.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pedido.nombreUsuario,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _estadoColor(pedido.estado).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _estadoLabel(pedido.estado),
                      style: TextStyle(
                        color: _estadoColor(pedido.estado),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppTheme.textHint,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      pedido.direccionEntrega,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.description,
                    size: 16,
                    color: AppTheme.textHint,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      pedido.descripcion,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.attach_money,
                    size: 16,
                    color: AppTheme.accent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '\$${pedido.precioProducto.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../core/theme/app_theme.dart';
import '../../models/pedido.dart';
import '../../providers/auth_providers.dart';
import '../../providers/pedido_providers.dart';
import '../../providers/repartidor_providers.dart';

/// Pantalla de detalle de un pedido asignado al repartidor.
/// Muestra información completa y botones para actualizar estado.
///
/// Requisitos: 13.2
class DetallePedidoScreen extends ConsumerStatefulWidget {
  final String pedidoId;

  const DetallePedidoScreen({super.key, required this.pedidoId});

  @override
  ConsumerState<DetallePedidoScreen> createState() =>
      _DetallePedidoScreenState();
}

class _DetallePedidoScreenState extends ConsumerState<DetallePedidoScreen> {
  bool _isUpdating = false;

  Future<void> _actualizarEstado(EstadoPedido nuevoEstado, Pedido pedido) async {
    setState(() => _isUpdating = true);

    try {
      final repo = ref.read(pedidoRepositoryProvider);
      await repo.actualizarEstadoPedido(widget.pedidoId, nuevoEstado);

      // Notify user of status change (Req 12.2)
      final notificacionService = ref.read(notificacionServiceProvider);
      await notificacionService.notificarCambioEstado(
        pedido.telefonoUsuario,
        nuevoEstado,
      );

      // Invalidate providers to refresh data
      final sesion = await ref.read(sesionActivaProvider.future);
      if (sesion != null) {
        ref.invalidate(pedidosAsignadosProvider(sesion.userId));
      }
      ref.invalidate(pedidosActivosProvider);

      if (!mounted) return;
      setState(() => _isUpdating = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado a: ${_estadoLabel(nuevoEstado)}'),
        ),
      );

      // If status is enDestino, navigate to confirmation screen
      if (nuevoEstado == EstadoPedido.enDestino) {
        context.go('/repartidor/confirmar/${widget.pedidoId}');
      }
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

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

  /// Returns the next available status transitions for the current state.
  List<(EstadoPedido, String, IconData)> _nextActions(EstadoPedido current) {
    switch (current) {
      case EstadoPedido.asignado:
        return [(EstadoPedido.recogido, 'Marcar como Recogido', Icons.inventory)];
      case EstadoPedido.recogido:
        return [(EstadoPedido.enCamino, 'Marcar En Camino', Icons.directions_bike)];
      case EstadoPedido.enCamino:
        return [(EstadoPedido.enDestino, 'Marcar En Destino', Icons.flag)];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
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

        final pedidosAsync =
            ref.watch(pedidosAsignadosProvider(sesion.userId));

        return pedidosAsync.when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Scaffold(
            appBar: AppBar(title: const Text('Detalle Pedido')),
            body: Center(child: Text('Error: $e')),
          ),
          data: (pedidos) {
            final pedido = pedidos.where((p) => p.id == widget.pedidoId).firstOrNull;

            if (pedido == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Detalle Pedido')),
                body: const Center(
                  child: Text(
                    'Pedido no encontrado',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              );
            }

            return _buildDetail(context, pedido);
          },
        );
      },
    );
  }

  Widget _buildDetail(BuildContext context, Pedido pedido) {
    final actions = _nextActions(pedido.estado);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle Pedido'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/repartidor'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _estadoColor(pedido.estado).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _estadoLabel(pedido.estado),
                  style: TextStyle(
                    color: _estadoColor(pedido.estado),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Order details card
            Card(
              color: AppTheme.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(
                      icon: Icons.person,
                      label: 'Cliente',
                      value: pedido.nombreUsuario,
                    ),
                    const Divider(color: AppTheme.divider),
                    _DetailRow(
                      icon: Icons.location_on,
                      label: 'Dirección',
                      value: pedido.direccionEntrega,
                    ),
                    const Divider(color: AppTheme.divider),
                    _DetailRow(
                      icon: Icons.phone,
                      label: 'Teléfono',
                      value: pedido.telefonoUsuario,
                    ),
                    const Divider(color: AppTheme.divider),
                    _DetailRow(
                      icon: Icons.description,
                      label: 'Descripción',
                      value: pedido.descripcion,
                    ),
                    const Divider(color: AppTheme.divider),
                    _DetailRow(
                      icon: Icons.attach_money,
                      label: 'Precio',
                      value: '\$${pedido.precioProducto.toStringAsFixed(0)}',
                    ),
                    const Divider(color: AppTheme.divider),
                    _DetailRow(
                      icon: Icons.local_shipping,
                      label: 'Tipo de entrega',
                      value: pedido.tipoEntrega == TipoEntrega.express
                          ? 'Express'
                          : 'Estándar',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons (Req 13.2)
            if (actions.isNotEmpty) ...[
              const Text(
                'Actualizar Estado',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...actions.map(
                (action) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isUpdating
                          ? null
                          : () => _actualizarEstado(action.$1, pedido),
                      icon: _isUpdating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.textPrimary,
                              ),
                            )
                          : Icon(action.$3),
                      label: Text(action.$2),
                    ),
                  ),
                ),
              ),
            ],

            // If in enDestino, show button to confirm delivery
            if (pedido.estado == EstadoPedido.enDestino) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                  ),
                  onPressed: () =>
                      context.go('/repartidor/confirmar/${pedido.id}'),
                  icon: const Icon(Icons.verified),
                  label: const Text('Confirmar Entrega'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.textHint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

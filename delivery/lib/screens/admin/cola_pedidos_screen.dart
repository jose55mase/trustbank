import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../core/theme/app_theme.dart';
import '../../models/pedido.dart';
import '../../models/repartidor.dart';
import '../../providers/geolocalizacion_providers.dart';
import '../../providers/pedido_providers.dart';
import '../../providers/repartidor_providers.dart';

/// Lista de pedidos activos ordenados por fecha (más reciente primero).
/// Permite asignar repartidor disponible a cada pedido.
///
/// Requisitos: 2.1, 2.2, 2.3, 2.4
class ColaPedidosScreen extends ConsumerWidget {
  const ColaPedidosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pedidosAsync = ref.watch(pedidosActivosProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(pedidosActivosProvider);
      },
      child: pedidosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (pedidos) {
          if (pedidos.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: AppTheme.textHint),
                  SizedBox(height: 16),
                  Text(
                    'No hay pedidos activos',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pedidos.length,
            itemBuilder: (context, index) => _PedidoActivoCard(
              pedido: pedidos[index],
            ),
          );
        },
      ),
    );
  }
}

class _PedidoActivoCard extends ConsumerWidget {
  final Pedido pedido;

  const _PedidoActivoCard({required this.pedido});

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

  void _mostrarDialogoAsignar(BuildContext context, WidgetRef ref) {
    final disponiblesAsync = ref.read(repartidoresDisponiblesProvider);

    disponiblesAsync.when(
      loading: () {},
      error: (e, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando repartidores: $e')),
        );
      },
      data: (repartidores) {
        showModalBottomSheet(
          context: context,
          backgroundColor: AppTheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (ctx) => _AsignarRepartidorSheet(
            pedido: pedido,
            repartidores: repartidores,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure repartidores are loaded for assignment
    ref.watch(repartidoresDisponiblesProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _mostrarDialogoAsignar(context, ref),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  const Icon(Icons.location_on, size: 16, color: AppTheme.textHint),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      pedido.direccionEntrega,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.description, size: 16, color: AppTheme.textHint),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      pedido.descripcion,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16, color: AppTheme.accent),
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

class _AsignarRepartidorSheet extends ConsumerWidget {
  final Pedido pedido;
  final List<Repartidor> repartidores;

  const _AsignarRepartidorSheet({
    required this.pedido,
    required this.repartidores,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (repartidores.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No hay repartidores disponibles',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Asignar Repartidor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...repartidores.map(
            (r) => ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.primaryDark,
                child: Icon(Icons.person, color: AppTheme.textPrimary),
              ),
              title: Text(
                r.nombreCompleto,
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              subtitle: Text(
                '${r.totalEntregas} entregas',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              onTap: () async {
                final repo = ref.read(pedidoRepositoryProvider);
                final notificacionService = ref.read(notificacionServiceProvider);
                final geoRepo = ref.read(geolocalizacionRepositoryProvider);
                try {
                  await repo.asignarRepartidor(pedido.id, r.id);

                  // Notify user that repartidor was assigned (Req 12.1)
                  await notificacionService.notificarRepartidorAsignado(
                    pedido.telefonoUsuario,
                    r.nombreCompleto,
                  );

                  // Start geolocation tracking (Req 7.1)
                  await geoRepo.iniciarRastreo(r.id, pedido.id);

                  ref.invalidate(pedidosActivosProvider);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Repartidor ${r.nombreCompleto} asignado'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

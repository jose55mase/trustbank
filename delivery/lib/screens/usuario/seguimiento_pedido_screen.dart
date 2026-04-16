import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../models/pedido.dart';
import '../../providers/geolocalizacion_providers.dart';
import '../../providers/pedido_providers.dart';

/// Pantalla de seguimiento del pedido activo del usuario.
/// Muestra el estado actual y un mapa con la ubicación del repartidor.
///
/// Requisitos: 7.3, 7.5
class SeguimientoPedidoScreen extends ConsumerWidget {
  final String telefono;

  const SeguimientoPedidoScreen({super.key, required this.telefono});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pedidoAsync = ref.watch(pedidoActivoUsuarioProvider(telefono));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento de Pedido'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: pedidoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: AppTheme.error),
          ),
        ),
        data: (pedido) {
          if (pedido == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox, size: 64, color: AppTheme.textHint),
                    SizedBox(height: 16),
                    Text(
                      'No tienes un pedido activo',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return _PedidoSeguimientoBody(pedido: pedido);
        },
      ),
    );
  }
}

class _PedidoSeguimientoBody extends ConsumerWidget {
  final Pedido pedido;

  const _PedidoSeguimientoBody({required this.pedido});

  String _estadoLabel(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.pendiente:
        return 'Pendiente';
      case EstadoPedido.asignado:
        return 'Repartidor asignado';
      case EstadoPedido.recogido:
        return 'Producto recogido';
      case EstadoPedido.enCamino:
        return 'En camino';
      case EstadoPedido.enDestino:
        return 'En destino';
      case EstadoPedido.completado:
        return 'Completado';
    }
  }

  IconData _estadoIcon(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.pendiente:
        return Icons.hourglass_empty;
      case EstadoPedido.asignado:
        return Icons.person_pin;
      case EstadoPedido.recogido:
        return Icons.inventory;
      case EstadoPedido.enCamino:
        return Icons.delivery_dining;
      case EstadoPedido.enDestino:
        return Icons.place;
      case EstadoPedido.completado:
        return Icons.check_circle;
    }
  }

  Color _estadoColor(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.pendiente:
        return AppTheme.warning;
      case EstadoPedido.asignado:
        return AppTheme.primaryLight;
      case EstadoPedido.recogido:
        return AppTheme.accent;
      case EstadoPedido.enCamino:
        return AppTheme.accent;
      case EstadoPedido.enDestino:
        return AppTheme.success;
      case EstadoPedido.completado:
        return AppTheme.success;
    }
  }

  int _estadoStep(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.pendiente:
        return 0;
      case EstadoPedido.asignado:
        return 1;
      case EstadoPedido.recogido:
        return 2;
      case EstadoPedido.enCamino:
        return 3;
      case EstadoPedido.enDestino:
        return 4;
      case EstadoPedido.completado:
        return 5;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep = _estadoStep(pedido.estado);

    return Column(
      children: [
        // Status card
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _estadoIcon(pedido.estado),
                      color: _estadoColor(pedido.estado),
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _estadoLabel(pedido.estado),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _estadoColor(pedido.estado),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pedido.direccionEntrega,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress indicator
                _StatusProgressBar(currentStep: currentStep),
              ],
            ),
          ),
        ),

        // Map section (only when repartidor is assigned)
        Expanded(
          child: pedido.repartidorId != null
              ? _MapSection(repartidorId: pedido.repartidorId!)
              : const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map, size: 48, color: AppTheme.textHint),
                      SizedBox(height: 12),
                      Text(
                        'El mapa estará disponible cuando\nse asigne un repartidor',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textHint,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _StatusProgressBar extends StatelessWidget {
  final int currentStep;

  const _StatusProgressBar({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const steps = ['Pendiente', 'Asignado', 'Recogido', 'En camino', 'Destino'];
    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index <= currentStep;
        return Expanded(
          child: Column(
            children: [
              Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.accent : AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[index],
                style: TextStyle(
                  fontSize: 9,
                  color: isActive ? AppTheme.textPrimary : AppTheme.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _MapSection extends ConsumerWidget {
  final String repartidorId;

  const _MapSection({required this.repartidorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ubicacionAsync = ref.watch(ubicacionStreamProvider(repartidorId));

    return ubicacionAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off, size: 48, color: AppTheme.warning),
            SizedBox(height: 12),
            Text(
              'Ubicación no disponible temporalmente',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
      data: (ubicacion) {
        final position = LatLng(ubicacion.latitud, ubicacion.longitud);
        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: position,
            zoom: 15,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('repartidor'),
              position: position,
              infoWindow: const InfoWindow(title: 'Repartidor'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet,
              ),
            ),
          },
          myLocationEnabled: false,
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
        );
      },
    );
  }
}

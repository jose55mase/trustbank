import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_providers.dart';
import '../../providers/geolocalizacion_providers.dart';
import '../../providers/pedido_providers.dart';
import '../../providers/repartidor_providers.dart';

/// Pantalla de confirmación de entrega.
/// El repartidor ingresa el Código_Confirmación para completar el pedido.
///
/// Requisitos: 3.1, 3.2, 3.3, 3.4, 3.5
class ConfirmacionEntregaScreen extends ConsumerStatefulWidget {
  final String pedidoId;

  const ConfirmacionEntregaScreen({super.key, required this.pedidoId});

  @override
  ConsumerState<ConfirmacionEntregaScreen> createState() =>
      _ConfirmacionEntregaScreenState();
}

class _ConfirmacionEntregaScreenState
    extends ConsumerState<ConfirmacionEntregaScreen> {
  final _codigoController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _entregaExitosa = false;

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _confirmarEntrega() async {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) {
      setState(() => _errorMessage = 'Ingresa el código de confirmación');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(pedidoRepositoryProvider);

      // Get pedido data before confirming (for notifications and geo)
      final pedidos = await repo.obtenerPedidosActivos();
      final pedido = pedidos.where((p) => p.id == widget.pedidoId).firstOrNull;

      final resultado = await repo.confirmarEntrega(widget.pedidoId, codigo);

      if (!mounted) return;

      if (resultado) {
        // Notify user that delivery is completed (Req 12.3)
        if (pedido != null) {
          final notificacionService = ref.read(notificacionServiceProvider);
          await notificacionService.notificarEntregaCompletada(
            pedido.telefonoUsuario,
          );

          // Stop geolocation tracking (Req 7.4)
          if (pedido.repartidorId != null) {
            final geoRepo = ref.read(geolocalizacionRepositoryProvider);
            await geoRepo.detenerRastreo(pedido.repartidorId!, pedido.id);
          }
        }

        // Success: invalidate providers and show success (Req 3.2, 3.4, 3.5)
        final sesion = await ref.read(sesionActivaProvider.future);
        if (sesion != null) {
          ref.invalidate(pedidosAsignadosProvider(sesion.userId));
          ref.invalidate(resumenDiarioProvider(sesion.userId));
        }
        ref.invalidate(pedidosActivosProvider);
        ref.invalidate(historialPedidosProvider);

        setState(() {
          _isLoading = false;
          _entregaExitosa = true;
        });
      } else {
        // Wrong code (Req 3.3)
        setState(() {
          _isLoading = false;
          _errorMessage = 'Código incorrecto. Intenta de nuevo.';
        });
      }
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_entregaExitosa) {
      return _buildSuccessView(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Entrega'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.go('/repartidor/detalle/${widget.pedidoId}'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.verified_user,
                size: 64,
                color: AppTheme.accent,
              ),
              const SizedBox(height: 16),
              Text(
                'Confirmar Entrega',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingresa el código de confirmación que tiene el cliente',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),

              // Code input field (Req 3.1)
              TextFormField(
                controller: _codigoController,
                decoration: const InputDecoration(
                  labelText: 'Código de confirmación',
                  prefixIcon: Icon(Icons.lock_outline),
                  hintText: 'Ej: ABC123',
                ),
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: AppTheme.textPrimary,
                ),
                onFieldSubmitted: (_) => _confirmarEntrega(),
              ),
              const SizedBox(height: 16),

              // Error message (Req 3.3)
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.error.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.error,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_errorMessage != null) const SizedBox(height: 16),

              // Confirm button
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _confirmarEntrega,
                  icon: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.textPrimary,
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                size: 80,
                color: AppTheme.success,
              ),
              const SizedBox(height: 24),
              Text(
                '¡Entrega Completada!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.success,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'El pedido ha sido marcado como completado exitosamente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/repartidor'),
                  child: const Text('Volver al Panel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/server_action.dart';
import '../../shared/widgets/nav_menu_button.dart';
import '../server_selection/server_selection_notifier.dart';
import 'is_control_enabled.dart';
import 'server_control_notifier.dart';

/// Screen with Start, Stop and Restart buttons for the selected server.
///
/// Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 10.3, 10.4
class ServerControlScreen extends ConsumerWidget {
  const ServerControlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controlState = ref.watch(serverControlNotifierProvider);
    final server = ref.watch(selectedServerProvider);
    final enabled = server != null && isControlEnabled(server.status);

    // Show SnackBar on success or error (Req 3.4, 10.4).
    ref.listen<ServerControlState>(serverControlNotifierProvider,
        (prev, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(serverControlNotifierProvider.notifier).clearMessages();
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        ref.read(serverControlNotifierProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Control del Servidor'),
        leading: NavMenuButton.maybeOf(context),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (server != null)
              Text(
                server.name,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 8),
            if (server != null)
              Text(
                'Estado: ${_statusLabel(server.status)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: 32),

            // Loading indicator during operations (Req 3.5, 10.3).
            if (controlState.isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Center(child: CircularProgressIndicator()),
              ),

            _ControlButton(
              label: 'Iniciar',
              icon: Icons.play_arrow,
              color: Colors.green,
              enabled: enabled && !controlState.isLoading,
              onPressed: () => _confirmAction(
                context,
                ref,
                ServerAction.start,
                '¿Iniciar el servidor?',
              ),
            ),
            const SizedBox(height: 16),
            _ControlButton(
              label: 'Detener',
              icon: Icons.stop,
              color: Colors.red,
              enabled: enabled && !controlState.isLoading,
              onPressed: () => _confirmAction(
                context,
                ref,
                ServerAction.stop,
                '¿Detener el servidor?',
              ),
            ),
            const SizedBox(height: 16),
            _ControlButton(
              label: 'Reiniciar',
              icon: Icons.restart_alt,
              color: Colors.orange,
              enabled: enabled && !controlState.isLoading,
              onPressed: () => _confirmAction(
                context,
                ref,
                ServerAction.restart,
                '¿Reiniciar el servidor?',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'started':
        return 'Online';
      case 'stopped':
        return 'Offline';
      case 'restarting':
        return 'Reiniciando';
      case 'installing':
        return 'Instalando';
      default:
        return status;
    }
  }

  /// Shows a confirmation dialog before executing the [action].
  Future<void> _confirmAction(
    BuildContext context,
    WidgetRef ref,
    ServerAction action,
    String message,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar acción'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(serverControlNotifierProvider.notifier).executeAction(action);
    }
  }
}

class _ControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? color : null,
        foregroundColor: enabled ? Colors.white : null,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 18),
      ),
    );
  }
}

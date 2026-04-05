import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/game_server.dart';
import '../../shared/widgets/nav_menu_button.dart';
import '../server_selection/server_selection_notifier.dart';
import 'dashboard_notifier.dart';
import 'status_color.dart';

/// Dashboard screen that displays full server information with a
/// color-coded status indicator and auto-refresh.
///
/// Requirements: 2.1, 2.2, 2.3, 2.4, 2.5
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(dashboardNotifierProvider.notifier).fetchStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashState = ref.watch(dashboardNotifierProvider);
    final selected = ref.watch(selectedServerProvider);

    // Use the freshest data available: dashState.server or the selected server.
    final server = dashState.server ?? selected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        leading: NavMenuButton.maybeOf(context),
      ),
      body: _buildBody(dashState, server),
    );
  }

  Widget _buildBody(DashboardState dashState, GameServer? server) {
    // Error state with retry (Req 2.4).
    if (dashState.errorMessage != null && server == null) {
      return _ErrorView(
        message: dashState.errorMessage!,
        onRetry: () =>
            ref.read(dashboardNotifierProvider.notifier).retry(),
      );
    }

    // No server selected – shouldn't happen, but handle gracefully.
    if (server == null) {
      return const Center(child: Text('No hay servidor seleccionado'));
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(dashboardNotifierProvider.notifier).fetchStatus(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Error banner when we have stale data but the refresh failed.
          if (dashState.errorMessage != null)
            _ErrorBanner(
              message: dashState.errorMessage!,
              onRetry: () =>
                  ref.read(dashboardNotifierProvider.notifier).retry(),
            ),

          // Loading indicator during refresh.
          if (dashState.isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),

          // Status indicator card (Req 2.5).
          _StatusCard(status: server.status),

          const SizedBox(height: 16),

          // Server info card (Req 2.3).
          _ServerInfoCard(server: server),
        ],
      ),
    );
  }
}

/// Color-coded status indicator card.
class _StatusCard extends StatelessWidget {
  final String status;
  const _StatusCard({required this.status});

  String _label(String s) {
    switch (s) {
      case 'started':
        return 'Online';
      case 'stopped':
        return 'Offline';
      case 'restarting':
        return 'Reiniciando';
      case 'installing':
        return 'Instalando';
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, radius: 12),
        title: Text(
          _label(status),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        subtitle: const Text('Estado del servidor'),
      ),
    );
  }
}

/// Card showing full server details.
class _ServerInfoCard extends StatelessWidget {
  final GameServer server;
  const _ServerInfoCard({required this.server});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              server.name as String,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            _InfoRow(icon: Icons.dns, label: 'IP', value: server.ip as String),
            _InfoRow(
              icon: Icons.numbers,
              label: 'Puerto',
              value: '${server.port}',
            ),
            _InfoRow(
              icon: Icons.people,
              label: 'Jugadores',
              value: '${server.currentPlayers}/${server.maxPlayers}',
            ),
            _InfoRow(
              icon: Icons.map,
              label: 'Mapa',
              value: server.map as String,
            ),
            _InfoRow(
              icon: Icons.info_outline,
              label: 'Versión',
              value: server.gameVersion as String,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

/// Full-screen error view with retry button (Req 2.4).
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 64,
              color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

/// Error banner shown above stale data when a refresh fails.
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MaterialBanner(
        content: Text(message),
        leading: Icon(Icons.error_outline,
            color: Theme.of(context).colorScheme.error),
        actions: [
          TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

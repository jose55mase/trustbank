import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/models/game_server.dart';
import 'server_selection_notifier.dart';

/// Screen that displays the list of DayZ servers and allows the user
/// to select one to manage.
///
/// Requirements: 11.1, 11.2, 11.3, 11.4
class ServerSelectionScreen extends ConsumerStatefulWidget {
  const ServerSelectionScreen({super.key});

  @override
  ConsumerState<ServerSelectionScreen> createState() =>
      _ServerSelectionScreenState();
}

class _ServerSelectionScreenState extends ConsumerState<ServerSelectionScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(serverSelectionNotifierProvider.notifier).fetchServers();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'started':
        return Colors.green;
      case 'stopped':
        return Colors.red;
      default:
        return Colors.yellow;
    }
  }

  void _onServerTap(GameServer server) {
    ref.read(selectedServerProvider.notifier).state = server;
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(serverSelectionNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Selección de Servidor')),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(ServerSelectionState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref
                  .read(serverSelectionNotifierProvider.notifier)
                  .fetchServers(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.servers.isEmpty) {
      return const Center(
        child: Text('No se encontraron servidores DayZ activos'),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(serverSelectionNotifierProvider.notifier).fetchServers(),
      child: ListView.builder(
        itemCount: state.servers.length,
        itemBuilder: (context, index) {
          final server = state.servers[index];
          return _ServerTile(
            server: server,
            statusColor: _statusColor(server.status),
            onTap: () => _onServerTap(server),
          );
        },
      ),
    );
  }
}

class _ServerTile extends StatelessWidget {
  final GameServer server;
  final Color statusColor;
  final VoidCallback onTap;

  const _ServerTile({
    required this.server,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor,
        radius: 8,
      ),
      title: Text(server.name),
      subtitle: Text(
        '${server.ip}:${server.port}  •  '
        '${server.currentPlayers}/${server.maxPlayers} jugadores',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

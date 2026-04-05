import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/banned_player.dart';
import '../../shared/models/player.dart';
import '../../shared/widgets/nav_menu_button.dart';
import 'players_notifier.dart';

/// Screen for managing connected and banned players.
///
/// Two tabs: "Conectados" (online players) and "Baneados" (ban list).
/// Requirements: 4.1, 4.2, 4.3, 4.4, 4.5
class PlayersScreen extends ConsumerStatefulWidget {
  const PlayersScreen({super.key});

  @override
  ConsumerState<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends ConsumerState<PlayersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(playersNotifierProvider.notifier).fetchPlayers();
      ref.read(playersNotifierProvider.notifier).fetchBanList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final playersState = ref.watch(playersNotifierProvider);

    // Show SnackBar on success or error (Req 10.4).
    ref.listen<PlayersState>(playersNotifierProvider, (prev, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(playersNotifierProvider.notifier).clearMessages();
      }
    });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Jugadores'),
          leading: NavMenuButton.maybeOf(context),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Conectados'),
              Tab(text: 'Baneados'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ConnectedPlayersTab(state: playersState),
            _BannedPlayersTab(state: playersState),
          ],
        ),
      ),
    );
  }
}

/// Tab showing connected players with kick/ban actions.
class _ConnectedPlayersTab extends ConsumerWidget {
  final PlayersState state;
  const _ConnectedPlayersTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Error state (Req 4.5).
    if (state.errorMessage != null && state.players.isEmpty) {
      return _ErrorView(
        message: state.errorMessage!,
        onRetry: () =>
            ref.read(playersNotifierProvider.notifier).fetchPlayers(),
      );
    }

    if (state.isLoading && state.players.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.players.isEmpty) {
      return const Center(
        child: Text('No hay jugadores conectados'),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(playersNotifierProvider.notifier).fetchPlayers(),
      child: ListView.builder(
        itemCount: state.players.length,
        itemBuilder: (context, index) {
          final player = state.players[index];
          return _PlayerTile(player: player);
        },
      ),
    );
  }
}

/// Tile for a single connected player with kick/ban actions.
class _PlayerTile extends ConsumerWidget {
  final Player player;
  const _PlayerTile({required this.player});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.person),
      title: Text(player.name),
      subtitle: Text('ID: ${player.id}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.orange),
            tooltip: 'Expulsar',
            onPressed: () => _confirmKick(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.block, color: Colors.red),
            tooltip: 'Banear',
            onPressed: () => _showBanDialog(context, ref),
          ),
        ],
      ),
    );
  }

  /// Confirmation dialog before kicking (Req 4.2).
  Future<void> _confirmKick(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Expulsar jugador'),
        content: Text('¿Expulsar a ${player.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Expulsar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(playersNotifierProvider.notifier).kickPlayer(player.id);
    }
  }

  /// Ban dialog with optional reason field (Req 4.3).
  Future<void> _showBanDialog(BuildContext context, WidgetRef ref) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Banear jugador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Banear a ${player.name}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Banear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final reason =
          reasonController.text.trim().isEmpty ? null : reasonController.text.trim();
      ref
          .read(playersNotifierProvider.notifier)
          .banPlayer(player.id, reason: reason);
    }
    reasonController.dispose();
  }
}

/// Tab showing banned players with unban option (Req 4.4).
class _BannedPlayersTab extends ConsumerWidget {
  final PlayersState state;
  const _BannedPlayersTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.banListError != null && state.bannedPlayers.isEmpty) {
      return _ErrorView(
        message: state.banListError!,
        onRetry: () =>
            ref.read(playersNotifierProvider.notifier).fetchBanList(),
      );
    }

    if (state.isBanListLoading && state.bannedPlayers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.bannedPlayers.isEmpty) {
      return const Center(
        child: Text('No hay jugadores baneados'),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(playersNotifierProvider.notifier).fetchBanList(),
      child: ListView.builder(
        itemCount: state.bannedPlayers.length,
        itemBuilder: (context, index) {
          final banned = state.bannedPlayers[index];
          return _BannedPlayerTile(banned: banned);
        },
      ),
    );
  }
}

/// Tile for a single banned player with unban action.
class _BannedPlayerTile extends ConsumerWidget {
  final BannedPlayer banned;
  const _BannedPlayerTile({required this.banned});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.block, color: Colors.red),
      title: Text(banned.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (banned.reason != null) Text('Motivo: ${banned.reason}'),
          if (banned.bannedAt != null)
            Text(
              'Fecha: ${banned.bannedAt!.toLocal().toString().split('.').first}',
            ),
        ],
      ),
      isThreeLine: banned.reason != null || banned.bannedAt != null,
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle_outline, color: Colors.green),
        tooltip: 'Desbanear',
        onPressed: () => _confirmUnban(context, ref),
      ),
    );
  }

  /// Confirmation dialog before unbanning.
  Future<void> _confirmUnban(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desbanear jugador'),
        content: Text('¿Desbanear a ${banned.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Desbanear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(playersNotifierProvider.notifier).unbanPlayer(banned.id);
    }
  }
}

/// Error view with retry button (Req 4.5).
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
          Icon(Icons.cloud_off,
              size: 64, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/nav_menu_button.dart';
import 'models/player_stats_model.dart';
import 'player_stats_notifier.dart';
import 'widgets/player_stats_card.dart';
import 'widgets/stats_table.dart';

/// Screen that displays a table of all linked players with their statistics.
///
/// Fetches all players on init, shows a loading indicator while fetching,
/// an error view with retry on failure, and a [StatsTable] with all players.
/// Supports pull-to-refresh and tapping a row to see a detail card.
///
/// Requirements: 12.4
class PlayerStatsScreen extends ConsumerStatefulWidget {
  const PlayerStatsScreen({super.key});

  @override
  ConsumerState<PlayerStatsScreen> createState() => _PlayerStatsScreenState();
}

class _PlayerStatsScreenState extends ConsumerState<PlayerStatsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(playerStatsNotifierProvider.notifier).fetchAllPlayers();
    });
  }

  Future<void> _refresh() async {
    await ref.read(playerStatsNotifierProvider.notifier).fetchAllPlayers();
  }

  void _showPlayerDetail(PlayerStatsModel player) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: PlayerStatsCard(player: player),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerStatsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas de Jugadores'),
        leading: NavMenuButton.maybeOf(context),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(PlayerStatsState state) {
    if (state.isLoading && state.players.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.players.isEmpty) {
      return _ErrorView(
        message: state.errorMessage!,
        onRetry: _refresh,
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary header
            Text(
              '${state.players.length} jugador${state.players.length == 1 ? '' : 'es'} vinculado${state.players.length == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),

            // Stats table
            StatsTable(
              players: state.players,
              onPlayerTap: _showPlayerDetail,
            ),
          ],
        ),
      ),
    );
  }
}

/// Error view with retry button, matching the pattern used in other screens.
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

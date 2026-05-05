import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/nav_menu_button.dart';
import 'game_logs_notifier.dart';
import 'models/game_log_category.dart';
import 'models/game_log_event.dart';

/// Screen for viewing parsed game log events with category filters and search.
///
/// Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 5.1–5.5
class GameLogsScreen extends ConsumerStatefulWidget {
  const GameLogsScreen({super.key});

  @override
  ConsumerState<GameLogsScreen> createState() => _GameLogsScreenState();
}

class _GameLogsScreenState extends ConsumerState<GameLogsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(gameLogsNotifierProvider.notifier).loadEvents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameLogsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Logs'),
        leading: NavMenuButton.maybeOf(context),
        actions: [
          IconButton(
            icon: state.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: state.isLoading
                ? null
                : () => ref.read(gameLogsNotifierProvider.notifier).refresh(),
            tooltip: 'Actualizar eventos',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search field (Req 4.4, 5.5)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar eventos...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(gameLogsNotifierProvider.notifier)
                              .updateSearch('');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref
                    .read(gameLogsNotifierProvider.notifier)
                    .updateSearch(value);
                setState(() {}); // Update clear button visibility
              },
            ),
          ),
          // Category filter chips (Req 5.1, 5.2, 5.3, 5.4)
          _buildCategoryChips(state.selectedCategory),
          // Event list content
          Expanded(child: _buildContent(context, state)),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(GameLogCategory? selectedCategory) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          _CategoryChip(
            label: 'Todos',
            selected: selectedCategory == null,
            onSelected: () => ref
                .read(gameLogsNotifierProvider.notifier)
                .selectCategory(null),
          ),
          const SizedBox(width: 8),
          _CategoryChip(
            label: 'Conexiones',
            selected: selectedCategory == GameLogCategory.connection,
            onSelected: () => ref
                .read(gameLogsNotifierProvider.notifier)
                .selectCategory(GameLogCategory.connection),
          ),
          const SizedBox(width: 8),
          _CategoryChip(
            label: 'Desconexiones',
            selected: selectedCategory == GameLogCategory.disconnection,
            onSelected: () => ref
                .read(gameLogsNotifierProvider.notifier)
                .selectCategory(GameLogCategory.disconnection),
          ),
          const SizedBox(width: 8),
          _CategoryChip(
            label: 'Kills PvP',
            selected: selectedCategory == GameLogCategory.playerKill,
            onSelected: () => ref
                .read(gameLogsNotifierProvider.notifier)
                .selectCategory(GameLogCategory.playerKill),
          ),
          const SizedBox(width: 8),
          _CategoryChip(
            label: 'Kills Zombies',
            selected: selectedCategory == GameLogCategory.zombieKill,
            onSelected: () => ref
                .read(gameLogsNotifierProvider.notifier)
                .selectCategory(GameLogCategory.zombieKill),
          ),
          const SizedBox(width: 8),
          _CategoryChip(
            label: 'Chat',
            selected: selectedCategory == GameLogCategory.chat,
            onSelected: () => ref
                .read(gameLogsNotifierProvider.notifier)
                .selectCategory(GameLogCategory.chat),
          ),
          const SizedBox(width: 8),
          _CategoryChip(
            label: 'Otros',
            selected: selectedCategory == GameLogCategory.unknown,
            onSelected: () => ref
                .read(gameLogsNotifierProvider.notifier)
                .selectCategory(GameLogCategory.unknown),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, GameLogsState state) {
    // Error state with no events loaded
    if (state.error != null && state.events.isEmpty) {
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
                state.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(gameLogsNotifierProvider.notifier).loadEvents(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    // Loading state with no events yet
    if (state.isLoading && state.events.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Empty state
    if (state.events.isEmpty) {
      return const Center(child: Text('No hay eventos'));
    }

    final filtered =
        ref.read(gameLogsNotifierProvider.notifier).filteredEvents;

    // No results for current filters
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No se encontraron eventos',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final event = filtered[index];
        return _GameEventTile(event: event);
      },
    );
  }
}

/// A FilterChip wrapper for category selection.
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

/// A single game event tile with colored left border and icon by category.
class _GameEventTile extends StatelessWidget {
  final GameLogEvent event;

  const _GameEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final color = _colorForCategory(event.category);
    final icon = _iconForCategory(event.category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      event.timestamp,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                    ),
                    if (event.playerName.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        event.playerName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  event.message,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForCategory(GameLogCategory category) {
    return switch (category) {
      GameLogCategory.connection => Colors.green,
      GameLogCategory.disconnection => Colors.red,
      GameLogCategory.playerKill => Colors.orange,
      GameLogCategory.zombieKill => Colors.purple,
      GameLogCategory.chat => Colors.blue,
      GameLogCategory.hit => Colors.amber,
      GameLogCategory.unknown => Colors.grey,
    };
  }

  IconData _iconForCategory(GameLogCategory category) {
    return switch (category) {
      GameLogCategory.connection => Icons.login,
      GameLogCategory.disconnection => Icons.logout,
      GameLogCategory.playerKill => Icons.sports_martial_arts,
      GameLogCategory.zombieKill => Icons.pest_control,
      GameLogCategory.chat => Icons.chat,
      GameLogCategory.hit => Icons.flash_on,
      GameLogCategory.unknown => Icons.help_outline,
    };
  }
}

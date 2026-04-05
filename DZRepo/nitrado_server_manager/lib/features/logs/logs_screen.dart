import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'logs_helpers.dart';
import 'logs_notifier.dart';
import '../../shared/widgets/nav_menu_button.dart';

/// Screen for viewing server logs with visual differentiation by level.
///
/// Requirements: 9.1, 9.2, 9.3, 9.4
class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(logsNotifierProvider.notifier).loadLogs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(logsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs del Servidor'),
        leading: NavMenuButton.maybeOf(context),
        actions: [
          // Manual refresh button (Req 9.4)
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
                : () => ref.read(logsNotifierProvider.notifier).refresh(),
            tooltip: 'Actualizar logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search field (Req 9.3)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar en logs...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(logsNotifierProvider.notifier)
                              .updateSearch('');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(logsNotifierProvider.notifier).updateSearch(value);
                setState(() {}); // Update clear button visibility
              },
            ),
          ),
          // Log content
          Expanded(child: _buildLogContent(context, state)),
        ],
      ),
    );
  }

  Widget _buildLogContent(BuildContext context, LogsState state) {
    if (state.error != null && state.allLogs.isEmpty) {
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
                  ref.read(logsNotifierProvider.notifier).loadLogs(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.isLoading && state.allLogs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.allLogs.isEmpty) {
      return const Center(child: Text('No hay logs disponibles'));
    }

    if (state.filteredLogs.isEmpty && state.searchQuery.isNotEmpty) {
      return Center(
        child: Text(
          'No se encontraron logs para "${state.searchQuery}"',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.builder(
      itemCount: state.filteredLogs.length,
      itemBuilder: (context, index) {
        final line = state.filteredLogs[index];
        final level = classifyLogLevel(line);
        return _LogEntryTile(line: line, level: level);
      },
    );
  }
}

/// A single log entry with visual differentiation by level (Req 9.2).
class _LogEntryTile extends StatelessWidget {
  final String line;
  final LogLevel level;

  const _LogEntryTile({required this.line, required this.level});

  @override
  Widget build(BuildContext context) {
    final color = _colorForLevel(level);
    final icon = _iconForLevel(level);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              line,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return Colors.red;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.info:
        return Colors.grey.shade700;
    }
  }

  IconData _iconForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return Icons.error_outline;
      case LogLevel.warning:
        return Icons.warning_amber;
      case LogLevel.info:
        return Icons.info_outline;
    }
  }
}

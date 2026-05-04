import 'package:flutter/material.dart';

import '../models/player_stats_model.dart';

/// Formats a number with thousands separators (e.g. 1234567 → "1,234,567").
String _formatNumber(int value) {
  final str = value.toString();
  final buffer = StringBuffer();
  final len = str.length;
  for (var i = 0; i < len; i++) {
    if (i > 0 && (len - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(str[i]);
  }
  return buffer.toString();
}

/// Column identifier for sorting the stats table.
enum _SortColumn { name, kills, deaths, kd, zombieKills, balance }

/// A table widget that displays a summary of all linked players' statistics.
///
/// Columns: Nombre DayZ, Kills, Muertes, K/D, Zombie Kills, Balance.
/// Supports sorting by clicking column headers.
///
/// Requirements: 12.4
class StatsTable extends StatefulWidget {
  /// The list of players to display.
  final List<PlayerStatsModel> players;

  /// Called when a player row is tapped.
  final ValueChanged<PlayerStatsModel>? onPlayerTap;

  const StatsTable({
    super.key,
    required this.players,
    this.onPlayerTap,
  });

  @override
  State<StatsTable> createState() => _StatsTableState();
}

class _StatsTableState extends State<StatsTable> {
  _SortColumn _sortColumn = _SortColumn.kills;
  bool _sortAscending = false;

  List<PlayerStatsModel> get _sortedPlayers {
    final sorted = List<PlayerStatsModel>.from(widget.players);
    sorted.sort((a, b) {
      int result;
      switch (_sortColumn) {
        case _SortColumn.name:
          result = a.dayzPlayerName
              .toLowerCase()
              .compareTo(b.dayzPlayerName.toLowerCase());
        case _SortColumn.kills:
          result = a.playerKills.compareTo(b.playerKills);
        case _SortColumn.deaths:
          result = a.deaths.compareTo(b.deaths);
        case _SortColumn.kd:
          result = _parseKd(a.kdRatio).compareTo(_parseKd(b.kdRatio));
        case _SortColumn.zombieKills:
          result = a.zombieKills.compareTo(b.zombieKills);
        case _SortColumn.balance:
          result = a.balance.compareTo(b.balance);
      }
      return _sortAscending ? result : -result;
    });
    return sorted;
  }

  /// Parses a K/D ratio string to a double for sorting.
  /// Returns -1 for "N/A" so those sort to the bottom.
  double _parseKd(String kd) {
    if (kd == 'N/A') return -1;
    return double.tryParse(kd) ?? -1;
  }

  void _onSort(_SortColumn column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.players.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline,
                size: 64,
                color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No hay jugadores vinculados',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    final sorted = _sortedPlayers;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        sortColumnIndex: _sortColumn.index,
        sortAscending: _sortAscending,
        showCheckboxColumn: false,
        columns: [
          DataColumn(
            label: const Text('Nombre DayZ'),
            onSort: (_, __) => _onSort(_SortColumn.name),
          ),
          DataColumn(
            label: const Text('Kills'),
            numeric: true,
            onSort: (_, __) => _onSort(_SortColumn.kills),
          ),
          DataColumn(
            label: const Text('Muertes'),
            numeric: true,
            onSort: (_, __) => _onSort(_SortColumn.deaths),
          ),
          DataColumn(
            label: const Text('K/D'),
            numeric: true,
            onSort: (_, __) => _onSort(_SortColumn.kd),
          ),
          DataColumn(
            label: const Text('Zombie Kills'),
            numeric: true,
            onSort: (_, __) => _onSort(_SortColumn.zombieKills),
          ),
          DataColumn(
            label: const Text('Balance'),
            numeric: true,
            onSort: (_, __) => _onSort(_SortColumn.balance),
          ),
        ],
        rows: sorted.map((player) {
          return DataRow(
            onSelectChanged: widget.onPlayerTap != null
                ? (_) => widget.onPlayerTap!(player)
                : null,
            cells: [
              DataCell(Text(player.dayzPlayerName)),
              DataCell(Text(_formatNumber(player.playerKills))),
              DataCell(Text(_formatNumber(player.deaths))),
              DataCell(Text(player.kdRatio)),
              DataCell(Text(_formatNumber(player.zombieKills))),
              DataCell(Text(_formatNumber(player.balance))),
            ],
          );
        }).toList(),
      ),
    );
  }
}

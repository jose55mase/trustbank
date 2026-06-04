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

/// Formats a [DateTime] to a readable Spanish-friendly string.
String _formatDate(DateTime dt) {
  final day = dt.day.toString().padLeft(2, '0');
  final month = dt.month.toString().padLeft(2, '0');
  final year = dt.year;
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}

/// A card widget that displays detailed statistics for a single player.
///
/// Shows: name, kills, deaths, K/D, zombie kills, zombie melee kills,
/// balance, and last activity date.
///
/// Requirements: 12.4
class PlayerStatsCard extends StatelessWidget {
  /// The player whose stats to display.
  final PlayerStatsModel player;

  const PlayerStatsCard({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with player name
            Row(
              children: [
                Icon(Icons.person, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    player.dayzPlayerName,
                    style: theme.textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Stats grid
            _StatRow(
              icon: Icons.gps_fixed,
              label: 'Kills de jugadores',
              value: _formatNumber(player.playerKills),
            ),
            const SizedBox(height: 8),
            _StatRow(
              icon: Icons.dangerous_outlined,
              label: 'Muertes',
              value: _formatNumber(player.deaths),
            ),
            const SizedBox(height: 8),
            _StatRow(
              icon: Icons.trending_up,
              label: 'Ratio K/D',
              value: player.kdRatio,
            ),
            const SizedBox(height: 8),
            _StatRow(
              icon: Icons.bug_report_outlined,
              label: 'Zombie kills',
              value: _formatNumber(player.zombieKills),
            ),
            const SizedBox(height: 8),
            _StatRow(
              icon: Icons.sports_martial_arts,
              label: 'Zombie kills (melee)',
              value: _formatNumber(player.zombieMeleeKills),
            ),
            const SizedBox(height: 8),
            _StatRow(
              icon: Icons.monetization_on_outlined,
              label: 'Balance TNT Coins',
              value: _formatNumber(player.balance),
              valueColor: theme.colorScheme.primary,
            ),
            if (player.lastActivity != null) ...[
              const SizedBox(height: 8),
              _StatRow(
                icon: Icons.access_time,
                label: 'Última actividad',
                value: _formatDate(player.lastActivity!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A single row in the stats card showing an icon, label, and value.
class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.outline),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

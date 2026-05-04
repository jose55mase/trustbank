import 'package:flutter/material.dart';

/// Card with a switch to enable or disable the economy system.
///
/// Displays a descriptive label and the current state (enabled/disabled).
///
/// Requirements: 11.1
class EconomyToggleCard extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const EconomyToggleCard({
    super.key,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              enabled ? Icons.monetization_on : Icons.monetization_on_outlined,
              color: enabled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sistema de economía',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    enabled ? 'Habilitado' : 'Deshabilitado',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: enabled
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: enabled,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

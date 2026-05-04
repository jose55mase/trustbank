import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/nav_menu_button.dart';
import 'economy_config_notifier.dart';
import 'models/economy_config_model.dart';
import 'widgets/economy_toggle_card.dart';
import 'widgets/melee_weapons_editor.dart';

/// Placeholder guild ID — will be replaced by actual guild selection in a
/// future iteration.
const _kDefaultGuildId = 'default';

/// Screen for viewing and editing the economy configuration.
///
/// Fetches the current config on init, displays a form with editable fields
/// (coins per zombie kill, melee weapons list, enable/disable toggle), and
/// sends updates to the backend when the user taps Save.
///
/// Requirements: 11.1, 11.2
class EconomyConfigScreen extends ConsumerStatefulWidget {
  const EconomyConfigScreen({super.key});

  @override
  ConsumerState<EconomyConfigScreen> createState() =>
      _EconomyConfigScreenState();
}

class _EconomyConfigScreenState extends ConsumerState<EconomyConfigScreen> {
  final _coinsController = TextEditingController();

  // Local mutable copies of the config fields so the form is interactive
  // before the user saves.
  List<String> _meleeWeapons = [];
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(economyConfigNotifierProvider.notifier)
          .fetchConfig(_kDefaultGuildId);
    });
  }

  @override
  void dispose() {
    _coinsController.dispose();
    super.dispose();
  }

  /// Syncs local form state when the notifier delivers a fresh config.
  void _syncFormFromConfig(EconomyConfigModel config) {
    _coinsController.text = config.coinsPerZombieKill.toString();
    _meleeWeapons = List<String>.from(config.meleeWeapons);
    _enabled = config.enabled;
  }

  Future<void> _save() async {
    final coins = int.tryParse(_coinsController.text.trim());
    if (coins == null || coins <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las monedas por kill deben ser un número positivo'),
        ),
      );
      return;
    }

    final updatedConfig = EconomyConfigModel(
      coinsPerZombieKill: coins,
      meleeWeapons: _meleeWeapons,
      enabled: _enabled,
    );

    await ref
        .read(economyConfigNotifierProvider.notifier)
        .updateConfig(_kDefaultGuildId, updatedConfig);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(economyConfigNotifierProvider);

    // When a fresh config arrives (after fetch or save), sync the form.
    ref.listen<EconomyConfigState>(economyConfigNotifierProvider,
        (prev, next) {
      // Sync form when config is loaded for the first time or refreshed.
      if (next.config != null && prev?.config != next.config) {
        setState(() => _syncFormFromConfig(next.config!));
      }

      // Show success snackbar after a save completes.
      if (prev?.isSaving == true &&
          !next.isSaving &&
          next.errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Show error snackbar.
      if (next.errorMessage != null && prev?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Economía'),
        leading: NavMenuButton.maybeOf(context),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(EconomyConfigState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.config == null) {
      return _ErrorView(
        message: state.errorMessage!,
        onRetry: () => ref
            .read(economyConfigNotifierProvider.notifier)
            .fetchConfig(_kDefaultGuildId),
      );
    }

    if (state.config == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toggle card
          EconomyToggleCard(
            enabled: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
          ),
          const SizedBox(height: 16),

          // Coins per zombie kill
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monedas por kill de zombie',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cantidad de TNT Coins otorgadas por cada kill con arma melee',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _coinsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Monedas por kill',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.monetization_on_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Melee weapons editor
          MeleeWeaponsEditor(
            weapons: _meleeWeapons,
            onChanged: (weapons) => setState(() => _meleeWeapons = weapons),
          ),
          const SizedBox(height: 24),

          // Save button
          FilledButton.icon(
            onPressed: state.isSaving ? null : _save,
            icon: state.isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Guardar cambios'),
          ),
        ],
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

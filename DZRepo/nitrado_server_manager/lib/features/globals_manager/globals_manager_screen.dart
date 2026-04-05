import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/global_variable.dart';
import '../../shared/widgets/nav_menu_button.dart';
import 'globals_helpers.dart';
import 'globals_manager_notifier.dart';

/// Known descriptions for common DayZ global variables.
const _variableDescriptions = <String, String>{
  'AnimalMaxCount': 'Máximo de animales en el mapa',
  'CleanupAvoidance': 'Evitar limpieza automática (0=no, 1=sí)',
  'CleanupLifetimeDeadAnimal': 'Tiempo de limpieza de animales muertos (seg)',
  'CleanupLifetimeDeadInfected': 'Tiempo de limpieza de infectados muertos (seg)',
  'CleanupLifetimeDeadPlayer': 'Tiempo de limpieza de jugadores muertos (seg)',
  'CleanupLifetimeDefault': 'Tiempo de limpieza por defecto (seg)',
  'CleanupLifetimeLimit': 'Límite de tiempo de limpieza (seg)',
  'CleanupLifetimeRuined': 'Tiempo de limpieza de items destruidos (seg)',
  'FlagRefreshFrequency': 'Frecuencia de refresco de banderas (seg)',
  'FlagRefreshMaxDuration': 'Duración máxima de refresco de banderas (seg)',
  'FoodDecay': 'Descomposición de comida (0=no, 1=sí)',
  'IdleModeCountdown': 'Cuenta regresiva para modo inactivo (seg)',
  'IdleModeStartup': 'Modo inactivo al iniciar (0=no, 1=sí)',
  'InitialSpawn': 'Spawn inicial de items',
  'LootDamageMax': 'Daño máximo del loot (0.0-1.0)',
  'LootDamageMin': 'Daño mínimo del loot (0.0-1.0)',
  'LootProxyPlacement': 'Colocación proxy de loot (0=no, 1=sí)',
  'LootSpawnAvoidance': 'Distancia de evitación de spawn de loot',
  'RespawnAttempt': 'Intentos de respawn',
  'RespawnLimit': 'Límite de respawn',
  'RespawnTypes': 'Tipos de respawn',
  'RestartSpawn': 'Spawn al reiniciar (0=no, 1=sí)',
  'SpawnInitial': 'Spawn inicial',
  'TimeHopping': 'Tiempo anti server-hopping (seg)',
  'TimeLogin': 'Tiempo de login (seg)',
  'TimeLogout': 'Tiempo de logout (seg)',
  'TimePenalty': 'Penalización de tiempo (seg)',
  'WorldWetTempUpdate': 'Actualización de temperatura/humedad (0=no, 1=sí)',
  'ZombieMaxCount': 'Máximo de zombies en el mapa',
  'ZoneSpawnDist': 'Distancia de spawn por zona',
};

/// Screen for visual management of globals.xml variables.
///
/// Requirements: 7.1, 7.2, 7.3, 7.4
class GlobalsManagerScreen extends ConsumerStatefulWidget {
  const GlobalsManagerScreen({super.key});

  @override
  ConsumerState<GlobalsManagerScreen> createState() =>
      _GlobalsManagerScreenState();
}

class _GlobalsManagerScreenState extends ConsumerState<GlobalsManagerScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(globalsManagerNotifierProvider.notifier).loadGlobals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(globalsManagerNotifierProvider);

    ref.listen<GlobalsManagerState>(globalsManagerNotifierProvider,
        (prev, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(globalsManagerNotifierProvider.notifier).clearMessages();
      }
      if (next.saveError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.saveError!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        ref.read(globalsManagerNotifierProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Variables Globales'),
        leading: NavMenuButton.maybeOf(context),
        actions: [
          if (!state.isLoading && state.globals.isNotEmpty)
            IconButton(
              icon: state.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              onPressed: state.isSaving
                  ? null
                  : () => ref
                      .read(globalsManagerNotifierProvider.notifier)
                      .saveToServer(),
              tooltip: 'Guardar en servidor',
            ),
        ],
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, GlobalsManagerState state) {
    if (state.error != null && state.globals.isEmpty) {
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
              onPressed: () => ref
                  .read(globalsManagerNotifierProvider.notifier)
                  .loadGlobals(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.isLoading && state.globals.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.globals.isEmpty) {
      return const Center(child: Text('No se encontraron variables globales'));
    }

    return ListView.builder(
      itemCount: state.globals.length,
      itemBuilder: (context, index) {
        final variable = state.globals[index];
        final isEditing = state.editingIndex == index;
        final description = _variableDescriptions[variable.name];
        final typeLabel = variable.type == 1 ? 'decimal' : 'entero';

        if (isEditing) {
          return _EditingTile(
            variable: variable,
            editingValue: state.editingValue ?? variable.value,
            validationError: state.validationError,
            description: description,
            typeLabel: typeLabel,
          );
        }

        return ListTile(
          title: Text(variable.name),
          subtitle: Text(
            [
              'Valor: ${variable.value}',
              '($typeLabel)',
              if (description != null) description,
            ].join(' · '),
          ),
          trailing: const Icon(Icons.edit, size: 20),
          onTap: () => ref
              .read(globalsManagerNotifierProvider.notifier)
              .startEditing(index),
        );
      },
    );
  }
}

/// Tile shown when a variable is being edited.
class _EditingTile extends ConsumerStatefulWidget {
  final GlobalVariable variable;
  final String editingValue;
  final String? validationError;
  final String? description;
  final String typeLabel;

  const _EditingTile({
    required this.variable,
    required this.editingValue,
    this.validationError,
    this.description,
    required this.typeLabel,
  });

  @override
  ConsumerState<_EditingTile> createState() => _EditingTileState();
}

class _EditingTileState extends ConsumerState<_EditingTile> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.editingValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(globalsManagerNotifierProvider.notifier);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.variable.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (widget.description != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  widget.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Valor (${widget.typeLabel})',
                border: const OutlineInputBorder(),
                errorText: widget.validationError,
              ),
              onChanged: notifier.updateEditingValue,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: notifier.cancelEdit,
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: widget.validationError == null &&
                          isValidNumericValue(_controller.text)
                      ? notifier.confirmEdit
                      : null,
                  child: const Text('Confirmar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

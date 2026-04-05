import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/event_child.dart';
import '../../shared/models/spawn_event.dart';
import '../../shared/models/spawn_event_flags.dart';
import '../../shared/widgets/nav_menu_button.dart';
import 'events_helpers.dart';
import 'events_manager_notifier.dart';

/// Screen for visual management of events.xml spawn events.
///
/// Requirements: 8.1, 8.2, 8.3, 8.4, 8.5
class EventsManagerScreen extends ConsumerStatefulWidget {
  const EventsManagerScreen({super.key});

  @override
  ConsumerState<EventsManagerScreen> createState() =>
      _EventsManagerScreenState();
}

class _EventsManagerScreenState extends ConsumerState<EventsManagerScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(eventsManagerNotifierProvider.notifier).loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventsManagerNotifierProvider);

    ref.listen<EventsManagerState>(eventsManagerNotifierProvider,
        (prev, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(eventsManagerNotifierProvider.notifier).clearMessages();
      }
      if (next.saveError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.saveError!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        ref.read(eventsManagerNotifierProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos de Spawn'),
        leading: state.editingIndex != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => ref
                    .read(eventsManagerNotifierProvider.notifier)
                    .cancelEdit(),
              )
            : NavMenuButton.maybeOf(context),
        actions: [
          if (!state.isLoading && state.events.isNotEmpty)
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
                      .read(eventsManagerNotifierProvider.notifier)
                      .saveToServer(),
              tooltip: 'Guardar en servidor',
            ),
        ],
      ),
      body: state.editingEvent != null
          ? _EventEditForm(
              event: state.editingEvent!,
              onChanged: (updated) => ref
                  .read(eventsManagerNotifierProvider.notifier)
                  .updateEditingEvent(updated),
              onSave: () => ref
                  .read(eventsManagerNotifierProvider.notifier)
                  .confirmEdit(),
              onCancel: () => ref
                  .read(eventsManagerNotifierProvider.notifier)
                  .cancelEdit(),
            )
          : _EventListView(state: state),
    );
  }
}

/// List view showing all spawn events (Req 8.1, 8.4).
class _EventListView extends ConsumerWidget {
  final EventsManagerState state;
  const _EventListView({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              onPressed: () => ref
                  .read(eventsManagerNotifierProvider.notifier)
                  .loadEvents(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.isLoading && state.events.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.events.isEmpty) {
      return const Center(child: Text('No se encontraron eventos'));
    }

    return ListView.builder(
      itemCount: state.events.length,
      itemBuilder: (context, index) {
        final event = state.events[index];
        final active = isEventActive(event);

        return ListTile(
          title: Text(
            event.name,
            style: active
                ? null
                : const TextStyle(color: Colors.grey),
          ),
          subtitle: Text(
            [
              'N:${event.nominal}',
              active ? 'Activo' : 'Desactivado',
              event.limit,
            ].join(' · '),
          ),
          trailing: active
              ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
              : const Icon(Icons.cancel, color: Colors.grey, size: 20),
          onTap: () => ref
              .read(eventsManagerNotifierProvider.notifier)
              .startEditing(index),
        );
      },
    );
  }
}


/// Edit form for a single SpawnEvent (Req 8.2).
class _EventEditForm extends StatefulWidget {
  final SpawnEvent event;
  final ValueChanged<SpawnEvent> onChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _EventEditForm({
    required this.event,
    required this.onChanged,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_EventEditForm> createState() => _EventEditFormState();
}

class _EventEditFormState extends State<_EventEditForm> {
  late TextEditingController _nominalCtrl;
  late TextEditingController _minCtrl;
  late TextEditingController _maxCtrl;
  late TextEditingController _lifetimeCtrl;
  late TextEditingController _restockCtrl;
  late TextEditingController _saferadiusCtrl;
  late TextEditingController _distanceradiusCtrl;
  late TextEditingController _cleanupradiusCtrl;

  @override
  void initState() {
    super.initState();
    _nominalCtrl = TextEditingController(text: widget.event.nominal.toString());
    _minCtrl = TextEditingController(text: widget.event.min.toString());
    _maxCtrl = TextEditingController(text: widget.event.max.toString());
    _lifetimeCtrl =
        TextEditingController(text: widget.event.lifetime.toString());
    _restockCtrl =
        TextEditingController(text: widget.event.restock.toString());
    _saferadiusCtrl =
        TextEditingController(text: widget.event.saferadius.toString());
    _distanceradiusCtrl =
        TextEditingController(text: widget.event.distanceradius.toString());
    _cleanupradiusCtrl =
        TextEditingController(text: widget.event.cleanupradius.toString());
  }

  @override
  void dispose() {
    _nominalCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _lifetimeCtrl.dispose();
    _restockCtrl.dispose();
    _saferadiusCtrl.dispose();
    _distanceradiusCtrl.dispose();
    _cleanupradiusCtrl.dispose();
    super.dispose();
  }

  void _emitUpdate() {
    final updated = widget.event.copyWith(
      nominal: int.tryParse(_nominalCtrl.text) ?? widget.event.nominal,
      min: int.tryParse(_minCtrl.text) ?? widget.event.min,
      max: int.tryParse(_maxCtrl.text) ?? widget.event.max,
      lifetime: int.tryParse(_lifetimeCtrl.text) ?? widget.event.lifetime,
      restock: int.tryParse(_restockCtrl.text) ?? widget.event.restock,
      saferadius:
          int.tryParse(_saferadiusCtrl.text) ?? widget.event.saferadius,
      distanceradius:
          int.tryParse(_distanceradiusCtrl.text) ?? widget.event.distanceradius,
      cleanupradius:
          int.tryParse(_cleanupradiusCtrl.text) ?? widget.event.cleanupradius,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event name header.
          Text(
            widget.event.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          // Numeric fields.
          _buildNumberField('Nominal', _nominalCtrl),
          _buildNumberField('Min', _minCtrl),
          _buildNumberField('Max', _maxCtrl),
          _buildNumberField('Lifetime', _lifetimeCtrl),
          _buildNumberField('Restock', _restockCtrl),
          _buildNumberField('Safe Radius', _saferadiusCtrl),
          _buildNumberField('Distance Radius', _distanceradiusCtrl),
          _buildNumberField('Cleanup Radius', _cleanupradiusCtrl),
          const SizedBox(height: 12),

          // Position dropdown.
          DropdownButtonFormField<String>(
            value: widget.event.position,
            decoration: const InputDecoration(
              labelText: 'Position',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'fixed', child: Text('fixed')),
              DropdownMenuItem(value: 'player', child: Text('player')),
            ],
            onChanged: (val) {
              if (val != null) {
                widget.onChanged(widget.event.copyWith(position: val));
              }
            },
          ),
          const SizedBox(height: 12),

          // Active toggle (Req 8.4).
          SwitchListTile(
            title: const Text('Activo'),
            subtitle: Text(
              widget.event.active == 1 ? 'Activo' : 'Desactivado',
            ),
            value: widget.event.active == 1,
            onChanged: (val) {
              widget.onChanged(
                  widget.event.copyWith(active: val ? 1 : 0));
            },
          ),
          const SizedBox(height: 12),

          // Flags checkboxes.
          Text('Flags', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildFlagCheckbox('deletable', widget.event.flags.deletable,
              (v) => _updateFlag(deletable: v)),
          _buildFlagCheckbox('init_random', widget.event.flags.initRandom,
              (v) => _updateFlag(initRandom: v)),
          _buildFlagCheckbox(
              'remove_damaged', widget.event.flags.removeDamaged,
              (v) => _updateFlag(removeDamaged: v)),
          const SizedBox(height: 16),

          // Children list (Req 8.2).
          Text('Children', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...widget.event.children.asMap().entries.map((entry) {
            final i = entry.key;
            final child = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(child.type,
                              style: Theme.of(context).textTheme.titleSmall),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () {
                            final updated =
                                List<EventChild>.from(widget.event.children)
                                  ..removeAt(i);
                            widget.onChanged(
                                widget.event.copyWith(children: updated));
                          },
                        ),
                      ],
                    ),
                    Text(
                      'min:${child.min} max:${child.max} '
                      'lootmin:${child.lootmin} lootmax:${child.lootmax}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          }),
          ActionChip(
            label: const Text('+ Agregar child'),
            onPressed: () => _showAddChildDialog(),
          ),
          const SizedBox(height: 24),

          // Action buttons.
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: widget.onSave,
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => _emitUpdate(),
      ),
    );
  }

  Widget _buildFlagCheckbox(
      String label, int value, ValueChanged<int> onChanged) {
    return CheckboxListTile(
      title: Text(label),
      value: value == 1,
      onChanged: (checked) {
        onChanged(checked == true ? 1 : 0);
      },
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
    );
  }

  void _updateFlag({int? deletable, int? initRandom, int? removeDamaged}) {
    final f = widget.event.flags;
    final updated = widget.event.copyWith(
      flags: SpawnEventFlags(
        deletable: deletable ?? f.deletable,
        initRandom: initRandom ?? f.initRandom,
        removeDamaged: removeDamaged ?? f.removeDamaged,
      ),
    );
    widget.onChanged(updated);
  }

  void _showAddChildDialog() {
    final typeCtrl = TextEditingController();
    final minCtrl = TextEditingController(text: '1');
    final maxCtrl = TextEditingController(text: '1');
    final lootminCtrl = TextEditingController(text: '0');
    final lootmaxCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar child'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: typeCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              TextField(
                controller: minCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Min'),
              ),
              TextField(
                controller: maxCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max'),
              ),
              TextField(
                controller: lootminCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Lootmin'),
              ),
              TextField(
                controller: lootmaxCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Lootmax'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (typeCtrl.text.trim().isNotEmpty) {
                final newChild = EventChild(
                  type: typeCtrl.text.trim(),
                  min: int.tryParse(minCtrl.text) ?? 1,
                  max: int.tryParse(maxCtrl.text) ?? 1,
                  lootmin: int.tryParse(lootminCtrl.text) ?? 0,
                  lootmax: int.tryParse(lootmaxCtrl.text) ?? 0,
                );
                final updated = [
                  ...widget.event.children,
                  newChild,
                ];
                widget.onChanged(widget.event.copyWith(children: updated));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }
}

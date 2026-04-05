import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/dayz_type.dart';
import '../../shared/models/dayz_type_flags.dart';
import '../../shared/widgets/nav_menu_button.dart';
import 'types_helpers.dart';
import 'types_manager_notifier.dart';

/// Screen for visual management of types.xml items.
///
/// Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6
class TypesManagerScreen extends ConsumerStatefulWidget {
  const TypesManagerScreen({super.key});

  @override
  ConsumerState<TypesManagerScreen> createState() => _TypesManagerScreenState();
}

class _TypesManagerScreenState extends ConsumerState<TypesManagerScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(typesManagerNotifierProvider.notifier).loadTypes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(typesManagerNotifierProvider);

    ref.listen<TypesManagerState>(typesManagerNotifierProvider, (prev, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(typesManagerNotifierProvider.notifier).clearMessages();
      }
      if (next.saveError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.saveError!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        ref.read(typesManagerNotifierProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Items'),
        leading: state.editingType != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => ref
                    .read(typesManagerNotifierProvider.notifier)
                    .cancelEdit(),
              )
            : NavMenuButton.maybeOf(context),
        actions: [
          if (!state.isLoading && state.allTypes.isNotEmpty)
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
                      .read(typesManagerNotifierProvider.notifier)
                      .saveToServer(),
              tooltip: 'Guardar en servidor',
            ),
        ],
      ),
      body: state.editingType != null
          ? _ItemEditForm(
              type: state.editingType!,
              onChanged: (updated) => ref
                  .read(typesManagerNotifierProvider.notifier)
                  .updateEditingType(updated),
              onSave: () => ref
                  .read(typesManagerNotifierProvider.notifier)
                  .confirmEdit(),
              onCancel: () => ref
                  .read(typesManagerNotifierProvider.notifier)
                  .cancelEdit(),
            )
          : _ItemListView(state: state),
    );
  }
}

/// List view with search and filter controls (Req 6.1, 6.6).
class _ItemListView extends ConsumerStatefulWidget {
  final TypesManagerState state;
  const _ItemListView({required this.state});

  @override
  ConsumerState<_ItemListView> createState() => _ItemListViewState();
}

class _ItemListViewState extends ConsumerState<_ItemListView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    if (state.error != null && state.allTypes.isEmpty) {
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
                  ref.read(typesManagerNotifierProvider.notifier).loadTypes(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.isLoading && state.allTypes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final notifier = ref.read(typesManagerNotifierProvider.notifier);
    final usageZones = notifier.allUsageZones;

    return Column(
      children: [
        // Search bar.
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: state.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        notifier.setSearchQuery('');
                      },
                    )
                  : null,
            ),
            onChanged: notifier.setSearchQuery,
          ),
        ),
        // Filter chips row.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: state.categoryFilter,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Todas')),
                    ...validCategories.map((c) => DropdownMenuItem(
                        value: c, child: Text(c))),
                  ],
                  onChanged: notifier.setCategoryFilter,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: state.usageFilter,
                  decoration: const InputDecoration(
                    labelText: 'Zona de uso',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Todas')),
                    ...usageZones.map((u) => DropdownMenuItem(
                        value: u, child: Text(u))),
                  ],
                  onChanged: notifier.setUsageFilter,
                ),
              ),
            ],
          ),
        ),
        // Results count.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${state.filteredTypes.length} items',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        // Item list.
        Expanded(
          child: state.filteredTypes.isEmpty
              ? const Center(child: Text('No se encontraron items'))
              : ListView.builder(
                  itemCount: state.filteredTypes.length,
                  itemBuilder: (context, index) {
                    final type = state.filteredTypes[index];
                    final hasWarning = !validateNominalMin(type);
                    return ListTile(
                      title: Text(type.name),
                      subtitle: Text(
                        [
                          'N:${type.nominal}',
                          'Min:${type.min}',
                          if (type.category != null) type.category!,
                        ].join(' · '),
                      ),
                      trailing: hasWarning
                          ? Tooltip(
                              message: 'nominal < min',
                              child: Icon(Icons.warning_amber,
                                  color: Colors.orange.shade700),
                            )
                          : null,
                      onTap: () => notifier.startEditing(index),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Edit form for a single DayzType item (Req 6.2, 6.5).
class _ItemEditForm extends StatefulWidget {
  final DayzType type;
  final ValueChanged<DayzType> onChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _ItemEditForm({
    required this.type,
    required this.onChanged,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_ItemEditForm> createState() => _ItemEditFormState();
}

class _ItemEditFormState extends State<_ItemEditForm> {
  late TextEditingController _nominalCtrl;
  late TextEditingController _lifetimeCtrl;
  late TextEditingController _restockCtrl;
  late TextEditingController _minCtrl;
  late TextEditingController _quantminCtrl;
  late TextEditingController _quantmaxCtrl;
  late TextEditingController _costCtrl;

  @override
  void initState() {
    super.initState();
    _nominalCtrl = TextEditingController(text: widget.type.nominal.toString());
    _lifetimeCtrl =
        TextEditingController(text: widget.type.lifetime.toString());
    _restockCtrl = TextEditingController(text: widget.type.restock.toString());
    _minCtrl = TextEditingController(text: widget.type.min.toString());
    _quantminCtrl =
        TextEditingController(text: widget.type.quantmin.toString());
    _quantmaxCtrl =
        TextEditingController(text: widget.type.quantmax.toString());
    _costCtrl = TextEditingController(text: widget.type.cost.toString());
  }

  @override
  void dispose() {
    _nominalCtrl.dispose();
    _lifetimeCtrl.dispose();
    _restockCtrl.dispose();
    _minCtrl.dispose();
    _quantminCtrl.dispose();
    _quantmaxCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  void _emitUpdate() {
    final updated = widget.type.copyWith(
      nominal: int.tryParse(_nominalCtrl.text) ?? widget.type.nominal,
      lifetime: int.tryParse(_lifetimeCtrl.text) ?? widget.type.lifetime,
      restock: int.tryParse(_restockCtrl.text) ?? widget.type.restock,
      min: int.tryParse(_minCtrl.text) ?? widget.type.min,
      quantmin: int.tryParse(_quantminCtrl.text) ?? widget.type.quantmin,
      quantmax: int.tryParse(_quantmaxCtrl.text) ?? widget.type.quantmax,
      cost: int.tryParse(_costCtrl.text) ?? widget.type.cost,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final hasWarning = !validateNominalMin(widget.type);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item name header.
          Text(
            widget.type.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          // Warning banner (Req 6.5).
          if (hasWarning)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Advertencia: nominal es menor que min',
                      style: TextStyle(color: Colors.deepOrange),
                    ),
                  ),
                ],
              ),
            ),

          // Numeric fields.
          _buildNumberField('Nominal', _nominalCtrl),
          _buildNumberField('Lifetime', _lifetimeCtrl),
          _buildNumberField('Restock', _restockCtrl),
          _buildNumberField('Min', _minCtrl),
          _buildNumberField('Quantmin', _quantminCtrl),
          _buildNumberField('Quantmax', _quantmaxCtrl),
          _buildNumberField('Cost', _costCtrl),
          const SizedBox(height: 16),

          // Flags checkboxes.
          Text('Flags', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildFlagCheckbox('count_in_cargo', widget.type.flags.countInCargo,
              (v) => _updateFlag(countInCargo: v)),
          _buildFlagCheckbox('count_in_hoarder',
              widget.type.flags.countInHoarder, (v) => _updateFlag(countInHoarder: v)),
          _buildFlagCheckbox('count_in_map', widget.type.flags.countInMap,
              (v) => _updateFlag(countInMap: v)),
          _buildFlagCheckbox('count_in_player',
              widget.type.flags.countInPlayer, (v) => _updateFlag(countInPlayer: v)),
          _buildFlagCheckbox('crafted', widget.type.flags.crafted,
              (v) => _updateFlag(crafted: v)),
          _buildFlagCheckbox('deloot', widget.type.flags.deloot,
              (v) => _updateFlag(deloot: v)),
          const SizedBox(height: 16),

          // Category dropdown.
          DropdownButtonFormField<String>(
            value: widget.type.category,
            decoration: const InputDecoration(
              labelText: 'Categoría',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Sin categoría')),
              ...validCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c))),
            ],
            onChanged: (val) {
              widget.onChanged(widget.type.copyWith(category: val));
            },
          ),
          const SizedBox(height: 16),

          // Usage chips.
          Text('Usage zones', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ...widget.type.usages.map((u) => Chip(
                    label: Text(u),
                    onDeleted: () {
                      final updated = List<String>.from(widget.type.usages)
                        ..remove(u);
                      widget.onChanged(widget.type.copyWith(usages: updated));
                    },
                  )),
              ActionChip(
                label: const Text('+ Agregar'),
                onPressed: () => _showAddDialog('usage zone', (val) {
                  final updated = [...widget.type.usages, val];
                  widget.onChanged(widget.type.copyWith(usages: updated));
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Value chips.
          Text('Values', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ...widget.type.values.map((v) => Chip(
                    label: Text(v),
                    onDeleted: () {
                      final updated = List<String>.from(widget.type.values)
                        ..remove(v);
                      widget.onChanged(widget.type.copyWith(values: updated));
                    },
                  )),
              ActionChip(
                label: const Text('+ Agregar'),
                onPressed: () => _showAddDialog('value', (val) {
                  final updated = [...widget.type.values, val];
                  widget.onChanged(widget.type.copyWith(values: updated));
                }),
              ),
            ],
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

  void _updateFlag({
    int? countInCargo,
    int? countInHoarder,
    int? countInMap,
    int? countInPlayer,
    int? crafted,
    int? deloot,
  }) {
    final f = widget.type.flags;
    final updated = widget.type.copyWith(
      flags: DayzTypeFlags(
        countInCargo: countInCargo ?? f.countInCargo,
        countInHoarder: countInHoarder ?? f.countInHoarder,
        countInMap: countInMap ?? f.countInMap,
        countInPlayer: countInPlayer ?? f.countInPlayer,
        crafted: crafted ?? f.crafted,
        deloot: deloot ?? f.deloot,
      ),
    );
    widget.onChanged(updated);
  }

  void _showAddDialog(String label, ValueChanged<String> onAdd) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Agregar $label'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: 'Nombre del $label'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onAdd(controller.text.trim());
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

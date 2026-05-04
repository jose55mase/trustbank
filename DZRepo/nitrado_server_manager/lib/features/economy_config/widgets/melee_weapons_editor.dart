import 'package:flutter/material.dart';

/// Editable list of melee weapons displayed as chips.
///
/// Provides a text field with an add button to append new weapons,
/// and a delete button on each chip to remove existing ones.
///
/// Requirements: 11.1
class MeleeWeaponsEditor extends StatefulWidget {
  final List<String> weapons;
  final ValueChanged<List<String>> onChanged;

  const MeleeWeaponsEditor({
    super.key,
    required this.weapons,
    required this.onChanged,
  });

  @override
  State<MeleeWeaponsEditor> createState() => _MeleeWeaponsEditorState();
}

class _MeleeWeaponsEditorState extends State<MeleeWeaponsEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addWeapon() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    if (widget.weapons.contains(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El arma ya existe en la lista')),
      );
      return;
    }
    widget.onChanged([...widget.weapons, name]);
    _controller.clear();
  }

  void _removeWeapon(int index) {
    final updated = List<String>.from(widget.weapons)..removeAt(index);
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Armas cuerpo a cuerpo',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Solo kills con estas armas otorgan monedas',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            // Input row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Nombre del arma',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addWeapon(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: _addWeapon,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Chips
            if (widget.weapons.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No hay armas configuradas',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (var i = 0; i < widget.weapons.length; i++)
                    InputChip(
                      label: Text(widget.weapons[i]),
                      onDeleted: () => _removeWeapon(i),
                      deleteIcon: const Icon(Icons.close, size: 18),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

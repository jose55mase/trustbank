import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../design_system/colors/tb_colors.dart';
import '../../../../design_system/spacing/tb_spacing.dart';
import '../../../../design_system/typography/tb_typography.dart';
import '../../../../models/assignment_type.dart';
import '../bloc/assignment_types_bloc.dart';

/// Pantalla de gestión de tipos de asignación para el panel administrativo.
///
/// Permite al administrador:
/// - Ver la lista de tipos de asignación con nombre, descripción, estado y conteo de supervisores
/// - Crear nuevos tipos de asignación (nombre, descripción, estado)
/// - Editar tipos existentes
/// - Eliminar tipos (solo si no tienen supervisores asignados)
class AssignmentTypesManagementScreen extends StatelessWidget {
  const AssignmentTypesManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AssignmentTypesBloc()..add(LoadAssignmentTypes()),
      child: const _AssignmentTypesManagementView(),
    );
  }
}

class _AssignmentTypesManagementView extends StatelessWidget {
  const _AssignmentTypesManagementView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TBColors.background,
      body: BlocConsumer<AssignmentTypesBloc, AssignmentTypesState>(
        listener: _blocListener,
        builder: (context, state) {
          if (state is AssignmentTypesLoading) {
            return Column(
              children: [
                _buildHeader(context),
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: TBColors.primary),
                  ),
                ),
              ],
            );
          }
          if (state is AssignmentTypesLoaded) {
            return Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: _AssignmentTypesContent(types: state.types),
                ),
              ],
            );
          }
          if (state is AssignmentTypesError) {
            return Column(
              children: [
                _buildHeader(context),
                Expanded(child: _buildErrorState(context, state.message)),
              ],
            );
          }
          // AssignmentTypesInitial
          return Column(
            children: [
              _buildHeader(context),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: TBColors.primary),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _blocListener(BuildContext context, AssignmentTypesState state) {
    if (state is AssignmentTypesError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: TBColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
    if (state is AssignmentTypesLoaded) {
      // Show success snackbar only after a mutation (not initial load)
      // We detect this by checking if there was a previous loading state
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        TBSpacing.lg,
        TBSpacing.xl,
        TBSpacing.lg,
        TBSpacing.lg,
      ),
      decoration: const BoxDecoration(gradient: TBColors.primaryGradient),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Regresar',
            ),
            const SizedBox(width: TBSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tipos de Asignación',
                    style: TBTypography.headlineMedium.copyWith(
                      color: TBColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Administra los tipos de asignación de supervisores',
                    style: TBTypography.bodyMedium.copyWith(
                      color: TBColors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            _buildCreateButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return Material(
      color: Colors.white24,
      borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        onTap: () => _showCreateDialog(context),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 20),
              SizedBox(width: 6),
              Text(
                'Crear nuevo tipo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: TBColors.error.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 48,
              color: TBColors.error,
            ),
          ),
          const SizedBox(height: TBSpacing.lg),
          Text(
            'Error al cargar tipos de asignación',
            style: TBTypography.titleLarge,
          ),
          const SizedBox(height: TBSpacing.sm),
          Text(
            message,
            style: TBTypography.bodyMedium.copyWith(color: TBColors.grey600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TBSpacing.lg),
          ElevatedButton.icon(
            onPressed: () =>
                context.read<AssignmentTypesBloc>().add(LoadAssignmentTypes()),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TBColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => _AssignmentTypeFormDialog(
        title: 'Crear Nuevo Tipo de Asignación',
        confirmLabel: 'Crear',
        onConfirm: (name, description, active, filterValue) {
          context.read<AssignmentTypesBloc>().add(
                CreateAssignmentType(
                  name: name,
                  description: description,
                  active: active,
                  filterValue: filterValue,
                ),
              );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tipo de asignación creado exitosamente'),
              backgroundColor: TBColors.success,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        },
      ),
    );
  }
}

// ─── CONTENIDO PRINCIPAL: LISTA DE TIPOS DE ASIGNACIÓN ───────────────────

class _AssignmentTypesContent extends StatelessWidget {
  final List<AssignmentType> types;

  const _AssignmentTypesContent({required this.types});

  @override
  Widget build(BuildContext context) {
    if (types.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(TBSpacing.screenPadding),
      itemCount: types.length,
      itemBuilder: (context, index) {
        final type = types[index];
        return _buildTypeCard(context, type);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: TBColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 48,
              color: TBColors.primary,
            ),
          ),
          const SizedBox(height: TBSpacing.lg),
          Text(
            'No hay tipos de asignación',
            style: TBTypography.titleLarge,
          ),
          const SizedBox(height: TBSpacing.sm),
          Text(
            'Crea un tipo de asignación para comenzar a asignar supervisores',
            style: TBTypography.bodyMedium.copyWith(color: TBColors.grey600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(BuildContext context, AssignmentType type) {
    return Container(
      margin: const EdgeInsets.only(bottom: TBSpacing.md),
      decoration: BoxDecoration(
        color: TBColors.surface,
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: TBColors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(TBSpacing.md),
        child: Row(
          children: [
            // Type icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: type.active
                    ? TBColors.primary.withOpacity(0.08)
                    : TBColors.grey300.withOpacity(0.3),
                borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
              ),
              child: Icon(
                Icons.assignment_outlined,
                color: type.active ? TBColors.primary : TBColors.grey500,
                size: 24,
              ),
            ),
            const SizedBox(width: TBSpacing.md),
            // Type info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          type.name,
                          style: TBTypography.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: TBSpacing.sm),
                      _buildStatusBadge(type.active),
                    ],
                  ),
                  if (type.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      type.description,
                      style: TBTypography.bodyMedium.copyWith(
                        color: TBColors.grey600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${type.supervisorCount} ${type.supervisorCount == 1 ? 'supervisor' : 'supervisores'}',
                    style: TBTypography.bodySmall.copyWith(
                      color: TBColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
            // Supervisor count badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: TBColors.secondary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${type.supervisorCount}',
                style: TBTypography.labelMedium.copyWith(
                  color: TBColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: TBSpacing.sm),
            // Actions
            _buildEditButton(context, type),
            _buildDeleteButton(context, type),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: active
            ? TBColors.success.withOpacity(0.12)
            : TBColors.grey400.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        active ? 'Activo' : 'Inactivo',
        style: TBTypography.labelSmall.copyWith(
          color: active ? TBColors.success : TBColors.grey600,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEditButton(BuildContext context, AssignmentType type) {
    return IconButton(
      icon: const Icon(Icons.edit_outlined, size: 20),
      color: TBColors.primary,
      tooltip: 'Editar tipo',
      onPressed: () => _showEditDialog(context, type),
    );
  }

  Widget _buildDeleteButton(BuildContext context, AssignmentType type) {
    final canDelete = type.supervisorCount == 0;
    return IconButton(
      icon: const Icon(Icons.delete_outline, size: 20),
      color: canDelete ? TBColors.error : TBColors.grey400,
      tooltip: canDelete
          ? 'Eliminar tipo'
          : 'No se puede eliminar (tiene supervisores asignados)',
      onPressed: canDelete ? () => _showDeleteConfirmation(context, type) : null,
    );
  }

  void _showEditDialog(BuildContext context, AssignmentType type) {
    showDialog(
      context: context,
      builder: (dialogContext) => _AssignmentTypeFormDialog(
        title: 'Editar Tipo de Asignación',
        confirmLabel: 'Guardar',
        initialName: type.name,
        initialDescription: type.description,
        initialActive: type.active,
        initialFilterValue: type.filterValue,
        onConfirm: (name, description, active, filterValue) {
          context.read<AssignmentTypesBloc>().add(
                UpdateAssignmentType(
                  id: type.id,
                  name: name,
                  description: description,
                  active: active,
                  filterValue: filterValue,
                ),
              );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tipo de asignación actualizado exitosamente'),
              backgroundColor: TBColors.success,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AssignmentType type) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TBSpacing.radiusLg),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: TBColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: TBColors.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Confirmar eliminación'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar el tipo de asignación "${type.name}"?\n\nEsta acción no se puede deshacer.',
          style: TBTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancelar',
              style:
                  TBTypography.buttonMedium.copyWith(color: TBColors.grey600),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Eliminar'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context
                  .read<AssignmentTypesBloc>()
                  .add(DeleteAssignmentType(id: type.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tipo de asignación eliminado exitosamente'),
                  backgroundColor: TBColors.success,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TBColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DIÁLOGO DE FORMULARIO DE TIPO DE ASIGNACIÓN (CREAR / EDITAR) ────────

class _AssignmentTypeFormDialog extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final String? initialName;
  final String? initialDescription;
  final bool? initialActive;
  final String? initialFilterValue;
  final void Function(
    String name,
    String? description,
    bool active,
    String? filterValue,
  ) onConfirm;

  const _AssignmentTypeFormDialog({
    required this.title,
    required this.confirmLabel,
    required this.onConfirm,
    this.initialName,
    this.initialDescription,
    this.initialActive,
    this.initialFilterValue,
  });

  @override
  State<_AssignmentTypeFormDialog> createState() =>
      _AssignmentTypeFormDialogState();
}

class _AssignmentTypeFormDialogState extends State<_AssignmentTypeFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _filterValueController;
  late bool _active;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _descriptionController =
        TextEditingController(text: widget.initialDescription ?? '');
    _filterValueController =
        TextEditingController(text: widget.initialFilterValue ?? '');
    _active = widget.initialActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _filterValueController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es requerido';
    }
    if (value.trim().length > 100) {
      return 'El nombre no puede exceder 100 caracteres';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value != null && value.trim().length > 255) {
      return 'La descripción no puede exceder 255 caracteres';
    }
    return null;
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final description = _descriptionController.text.trim();
      final filterValue = _filterValueController.text.trim();
      widget.onConfirm(
        _nameController.text.trim(),
        description.isNotEmpty ? description : null,
        _active,
        filterValue.isNotEmpty ? filterValue : null,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TBSpacing.radiusLg),
      ),
      title: Text(widget.title, style: TBTypography.headlineMedium),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                autofocus: true,
                validator: _validateName,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej: Campaña Premium, Leads Nuevos...',
                  labelStyle: TBTypography.bodyMedium.copyWith(
                    color: TBColors.grey600,
                  ),
                  hintStyle: TBTypography.bodyMedium.copyWith(
                    color: TBColors.grey400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                    borderSide:
                        const BorderSide(color: TBColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: TBSpacing.md,
                    vertical: TBSpacing.md,
                  ),
                ),
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: TBSpacing.md),
              // Description field
              TextFormField(
                controller: _descriptionController,
                validator: _validateDescription,
                maxLength: 255,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Describe el tipo de asignación...',
                  labelStyle: TBTypography.bodyMedium.copyWith(
                    color: TBColors.grey600,
                  ),
                  hintStyle: TBTypography.bodyMedium.copyWith(
                    color: TBColors.grey400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                    borderSide:
                        const BorderSide(color: TBColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: TBSpacing.md,
                    vertical: TBSpacing.md,
                  ),
                ),
              ),
              const SizedBox(height: TBSpacing.md),
              // Filter value field
              TextFormField(
                controller: _filterValueController,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: 'Valor de filtro (opcional)',
                  hintText: 'Ej: nombre de campaña para filtrar leads',
                  labelStyle: TBTypography.bodyMedium.copyWith(
                    color: TBColors.grey600,
                  ),
                  hintStyle: TBTypography.bodyMedium.copyWith(
                    color: TBColors.grey400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                    borderSide:
                        const BorderSide(color: TBColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: TBSpacing.md,
                    vertical: TBSpacing.md,
                  ),
                ),
              ),
              const SizedBox(height: TBSpacing.md),
              // Active toggle
              Container(
                decoration: BoxDecoration(
                  color: TBColors.grey100,
                  borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                ),
                child: SwitchListTile(
                  title: Text('Estado activo', style: TBTypography.bodyMedium),
                  subtitle: Text(
                    _active
                        ? 'El tipo está disponible para asignación'
                        : 'El tipo no aparecerá en las opciones',
                    style: TBTypography.bodySmall.copyWith(
                      color: TBColors.grey600,
                    ),
                  ),
                  value: _active,
                  activeColor: TBColors.primary,
                  onChanged: (value) {
                    setState(() {
                      _active = value;
                    });
                  },
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: TBSpacing.md,
                    vertical: TBSpacing.xs,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancelar',
            style: TBTypography.buttonMedium.copyWith(color: TBColors.grey600),
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: TBColors.primary,
            foregroundColor: TBColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: TBSpacing.lg,
              vertical: TBSpacing.sm,
            ),
          ),
          child: Text(widget.confirmLabel, style: TBTypography.buttonMedium),
        ),
      ],
    );
  }
}

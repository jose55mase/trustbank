import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../design_system/colors/tb_colors.dart';
import '../../../../design_system/spacing/tb_spacing.dart';
import '../../../../design_system/typography/tb_typography.dart';
import '../../../../models/module_permission.dart';
import '../../../../models/role_model.dart';
import '../bloc/roles_bloc.dart';

/// Pantalla de gestión de roles para el panel administrativo.
///
/// Permite al administrador:
/// - Ver la lista de roles con nombre y conteo de usuarios
/// - Crear nuevos roles (validación 3-50 caracteres)
/// - Editar nombre de roles existentes
/// - Eliminar roles (solo si no tienen usuarios asignados)
/// - Asignar/desasignar módulos a cada rol mediante toggles
class RolesManagementScreen extends StatelessWidget {
  const RolesManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RolesBloc()..add(LoadRoles()),
      child: const _RolesManagementView(),
    );
  }
}

class _RolesManagementView extends StatelessWidget {
  const _RolesManagementView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TBColors.background,
      body: BlocConsumer<RolesBloc, RolesState>(
        listener: _blocListener,
        builder: (context, state) {
          if (state is RolesLoading) {
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
          if (state is RolesLoaded) {
            return Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: _RolesContent(
                    roles: state.roles,
                    allModules: state.allModules,
                  ),
                ),
              ],
            );
          }
          if (state is RolesError) {
            return Column(
              children: [
                _buildHeader(context),
                Expanded(child: _buildErrorState(context, state.message)),
              ],
            );
          }
          // RolesInitial
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

  void _blocListener(BuildContext context, RolesState state) {
    if (state is RolesError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: TBColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
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
                    'Gestión de Roles',
                    style: TBTypography.headlineMedium.copyWith(
                      color: TBColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Administra roles y permisos de módulos',
                    style: TBTypography.bodyMedium.copyWith(
                      color: TBColors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            _buildCreateRoleButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateRoleButton(BuildContext context) {
    return Material(
      color: Colors.white24,
      borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        onTap: () => _showCreateRoleDialog(context),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 20),
              SizedBox(width: 6),
              Text(
                'Crear Rol',
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
          Text('Error al cargar roles', style: TBTypography.titleLarge),
          const SizedBox(height: TBSpacing.sm),
          Text(
            message,
            style: TBTypography.bodyMedium.copyWith(color: TBColors.grey600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TBSpacing.lg),
          ElevatedButton.icon(
            onPressed: () => context.read<RolesBloc>().add(LoadRoles()),
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

  void _showCreateRoleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => _RoleNameDialog(
        title: 'Crear Nuevo Rol',
        confirmLabel: 'Crear',
        onConfirm: (name) {
          context.read<RolesBloc>().add(CreateRole(name: name));
        },
      ),
    );
  }
}

// ─── CONTENIDO PRINCIPAL: LISTA DE ROLES ─────────────────────────────────

class _RolesContent extends StatefulWidget {
  final List<RoleModel> roles;
  final List<ModulePermission> allModules;

  const _RolesContent({
    required this.roles,
    required this.allModules,
  });

  @override
  State<_RolesContent> createState() => _RolesContentState();
}

class _RolesContentState extends State<_RolesContent> {
  /// ID del rol actualmente expandido para ver módulos (null si ninguno).
  int? _expandedRoleId;

  @override
  Widget build(BuildContext context) {
    if (widget.roles.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(TBSpacing.screenPadding),
      itemCount: widget.roles.length,
      itemBuilder: (context, index) {
        final role = widget.roles[index];
        final isExpanded = _expandedRoleId == role.id;
        return _buildRoleCard(role, isExpanded);
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
              Icons.admin_panel_settings_outlined,
              size: 48,
              color: TBColors.primary,
            ),
          ),
          const SizedBox(height: TBSpacing.lg),
          Text('No hay roles configurados', style: TBTypography.titleLarge),
          const SizedBox(height: TBSpacing.sm),
          Text(
            'Crea un rol para comenzar a asignar permisos',
            style: TBTypography.bodyMedium.copyWith(color: TBColors.grey600),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(RoleModel role, bool isExpanded) {
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
      child: Column(
        children: [
          // Role header row
          InkWell(
            borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
            onTap: () {
              setState(() {
                _expandedRoleId = isExpanded ? null : role.id;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(TBSpacing.md),
              child: Row(
                children: [
                  // Role icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: TBColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: TBColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: TBSpacing.md),
                  // Role name and user count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(role.name, style: TBTypography.titleLarge),
                        const SizedBox(height: 2),
                        Text(
                          '${role.userCount} ${role.userCount == 1 ? 'usuario' : 'usuarios'}',
                          style: TBTypography.bodyMedium.copyWith(
                            color: TBColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Module count badge
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
                      '${role.modules.length} módulos',
                      style: TBTypography.labelMedium.copyWith(
                        color: TBColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: TBSpacing.sm),
                  // Actions
                  _buildEditButton(role),
                  _buildDeleteButton(role),
                  // Expand/collapse indicator
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: TBColors.grey500,
                  ),
                ],
              ),
            ),
          ),
          // Module assignment section (expanded)
          if (isExpanded)
            _ModuleAssignmentView(
              role: role,
              allModules: widget.allModules,
            ),
        ],
      ),
    );
  }

  Widget _buildEditButton(RoleModel role) {
    return IconButton(
      icon: const Icon(Icons.edit_outlined, size: 20),
      color: TBColors.primary,
      tooltip: 'Editar nombre',
      onPressed: () => _showEditRoleDialog(role),
    );
  }

  Widget _buildDeleteButton(RoleModel role) {
    final canDelete = role.userCount == 0;
    return IconButton(
      icon: const Icon(Icons.delete_outline, size: 20),
      color: canDelete ? TBColors.error : TBColors.grey400,
      tooltip: canDelete
          ? 'Eliminar rol'
          : 'No se puede eliminar (tiene usuarios asignados)',
      onPressed: canDelete ? () => _showDeleteConfirmation(role) : null,
    );
  }

  void _showEditRoleDialog(RoleModel role) {
    showDialog(
      context: context,
      builder: (dialogContext) => _RoleNameDialog(
        title: 'Editar Rol',
        confirmLabel: 'Guardar',
        initialValue: role.name,
        onConfirm: (name) {
          context.read<RolesBloc>().add(UpdateRole(id: role.id, name: name));
        },
      ),
    );
  }

  void _showDeleteConfirmation(RoleModel role) {
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
          '¿Estás seguro de que deseas eliminar el rol "${role.name}"?\n\nEsta acción no se puede deshacer.',
          style: TBTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Eliminar'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<RolesBloc>().add(DeleteRole(id: role.id));
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

// ─── VISTA DE ASIGNACIÓN DE MÓDULOS ──────────────────────────────────────

class _ModuleAssignmentView extends StatefulWidget {
  final RoleModel role;
  final List<ModulePermission> allModules;

  const _ModuleAssignmentView({
    required this.role,
    required this.allModules,
  });

  @override
  State<_ModuleAssignmentView> createState() => _ModuleAssignmentViewState();
}

class _ModuleAssignmentViewState extends State<_ModuleAssignmentView> {
  late Set<int> _assignedModuleIds;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _assignedModuleIds = widget.role.modules.map((m) => m.id).toSet();
  }

  @override
  void didUpdateWidget(covariant _ModuleAssignmentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role) {
      _assignedModuleIds = widget.role.modules.map((m) => m.id).toSet();
      _hasChanges = false;
    }
  }

  void _toggleModule(int moduleId, bool assigned) {
    setState(() {
      if (assigned) {
        _assignedModuleIds.add(moduleId);
      } else {
        _assignedModuleIds.remove(moduleId);
      }
      _hasChanges = true;
    });
  }

  void _saveModuleAssignment() {
    context.read<RolesBloc>().add(
          UpdateRoleModules(
            roleId: widget.role.id,
            moduleIds: _assignedModuleIds.toList(),
          ),
        );
    setState(() {
      _hasChanges = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: TBColors.grey100,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(TBSpacing.radiusMd),
          bottomRight: Radius.circular(TBSpacing.radiusMd),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: TBColors.grey300),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TBSpacing.md,
              TBSpacing.md,
              TBSpacing.md,
              TBSpacing.sm,
            ),
            child: Row(
              children: [
                Text(
                  'Módulos asignados',
                  style: TBTypography.titleMedium.copyWith(
                    color: TBColors.grey700,
                  ),
                ),
                const Spacer(),
                if (_hasChanges)
                  ElevatedButton.icon(
                    onPressed: _saveModuleAssignment,
                    icon: const Icon(Icons.save_rounded, size: 16),
                    label: const Text('Guardar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TBColors.primary,
                      foregroundColor: TBColors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: TBSpacing.md,
                        vertical: TBSpacing.sm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                      ),
                      textStyle: TBTypography.labelMedium,
                    ),
                  ),
              ],
            ),
          ),
          // Module toggles list
          ...widget.allModules.map((module) {
            final isAssigned = _assignedModuleIds.contains(module.id);
            return _buildModuleToggle(module, isAssigned);
          }),
          const SizedBox(height: TBSpacing.sm),
        ],
      ),
    );
  }

  Widget _buildModuleToggle(ModulePermission module, bool isAssigned) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TBSpacing.md,
        vertical: TBSpacing.xs,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: TBColors.surface,
          borderRadius: BorderRadius.circular(TBSpacing.radiusSm),
        ),
        child: SwitchListTile(
          title: Text(module.name, style: TBTypography.bodyMedium),
          subtitle: module.description.isNotEmpty
              ? Text(
                  module.description,
                  style: TBTypography.bodySmall.copyWith(
                    color: TBColors.grey600,
                  ),
                )
              : null,
          secondary: Icon(
            _getModuleIcon(module.code),
            color: isAssigned ? TBColors.primary : TBColors.grey400,
            size: 22,
          ),
          value: isAssigned,
          activeColor: TBColors.primary,
          onChanged: (value) => _toggleModule(module.id, value),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: TBSpacing.md,
            vertical: TBSpacing.xs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TBSpacing.radiusSm),
          ),
        ),
      ),
    );
  }

  /// Mapea el código de módulo a un ícono de Material.
  IconData _getModuleIcon(String code) {
    switch (code) {
      case 'LEADS':
        return Icons.leaderboard_outlined;
      case 'DOCUMENTS':
        return Icons.description_outlined;
      case 'DOCUMENT_APPROVAL':
        return Icons.verified_outlined;
      case 'USER_MANAGEMENT':
        return Icons.group_outlined;
      case 'ROLE_MANAGEMENT':
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.extension_outlined;
    }
  }
}

// ─── DIÁLOGO DE NOMBRE DE ROL (CREAR / EDITAR) ──────────────────────────

class _RoleNameDialog extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final String? initialValue;
  final void Function(String name) onConfirm;

  const _RoleNameDialog({
    required this.title,
    required this.confirmLabel,
    required this.onConfirm,
    this.initialValue,
  });

  @override
  State<_RoleNameDialog> createState() => _RoleNameDialogState();
}

class _RoleNameDialogState extends State<_RoleNameDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es requerido';
    }
    if (value.trim().length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }
    if (value.trim().length > 50) {
      return 'El nombre no puede exceder 50 caracteres';
    }
    return null;
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onConfirm(_controller.text.trim());
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
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          validator: _validateName,
          maxLength: 50,
          decoration: InputDecoration(
            labelText: 'Nombre del rol',
            hintText: 'Ej: Administrador, Operador...',
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
              borderSide: const BorderSide(color: TBColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: TBSpacing.md,
              vertical: TBSpacing.md,
            ),
          ),
          onFieldSubmitted: (_) => _submit(),
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

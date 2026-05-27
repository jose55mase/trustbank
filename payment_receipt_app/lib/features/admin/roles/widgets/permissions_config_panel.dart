import 'package:flutter/material.dart';

import '../../../../design_system/colors/tb_colors.dart';
import '../../../../design_system/spacing/tb_spacing.dart';
import '../../../../design_system/typography/tb_typography.dart';
import '../../../../services/permissions_api_service.dart';
import 'campaign_visibility_section.dart';

/// Definición de una acción con su código y etiqueta en español.
class _ActionDefinition {
  final String code;
  final String label;
  final IconData icon;

  const _ActionDefinition({
    required this.code,
    required this.label,
    required this.icon,
  });
}

/// Lista de acciones disponibles para el módulo LEADS.
const List<_ActionDefinition> _leadsActions = [
  _ActionDefinition(
    code: 'ASSIGN_ADVISOR',
    label: 'Asignar asesor',
    icon: Icons.person_add_outlined,
  ),
  _ActionDefinition(
    code: 'UNASSIGN_ADVISOR',
    label: 'Desasignar',
    icon: Icons.person_remove_outlined,
  ),
  _ActionDefinition(
    code: 'IMPORT_EXCEL',
    label: 'Importar Excel',
    icon: Icons.upload_file_outlined,
  ),
  _ActionDefinition(
    code: 'EXPORT_EXCEL',
    label: 'Exportar Excel',
    icon: Icons.download_outlined,
  ),
  _ActionDefinition(
    code: 'EDIT_LEADS',
    label: 'Editar leads',
    icon: Icons.edit_outlined,
  ),
  _ActionDefinition(
    code: 'DELETE_LEADS',
    label: 'Eliminar leads',
    icon: Icons.delete_outline,
  ),
];

/// Panel de configuración de permisos de acciones para un rol en el módulo LEADS.
///
/// Muestra checkboxes para cada acción disponible, vinculados al estado
/// de permisos del rol. Al cambiar un checkbox, se llama a la API para
/// actualizar el permiso y se refleja el estado guardado. En caso de error,
/// se muestra un toast y se revierte el cambio.
///
/// Requisitos: 2.1, 2.2
class PermissionsConfigPanel extends StatefulWidget {
  /// ID del rol cuyos permisos se configuran.
  final int roleId;

  const PermissionsConfigPanel({
    super.key,
    required this.roleId,
  });

  @override
  State<PermissionsConfigPanel> createState() => _PermissionsConfigPanelState();
}

class _PermissionsConfigPanelState extends State<PermissionsConfigPanel> {
  /// Mapa de actionCode -> enabled para el estado actual de permisos.
  Map<String, bool> _permissions = {};

  /// Indica si se están cargando los permisos.
  bool _isLoading = true;

  /// Indica si hubo un error al cargar los permisos.
  String? _loadError;

  /// Set de action codes que están siendo actualizados (para mostrar loading).
  final Set<String> _updatingActions = {};

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  @override
  void didUpdateWidget(covariant PermissionsConfigPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roleId != widget.roleId) {
      _loadPermissions();
    }
  }

  /// Carga los permisos del rol desde la API.
  Future<void> _loadPermissions() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final permissionsList = await PermissionsApiService.fetchRolePermissions(
        widget.roleId,
        'LEADS',
      );

      final permissionsMap = <String, bool>{};
      for (final item in permissionsList) {
        final actionCode = item['actionCode'] as String?;
        final enabled = item['enabled'] as bool?;
        if (actionCode != null && enabled != null) {
          permissionsMap[actionCode] = enabled;
        }
      }

      if (mounted) {
        setState(() {
          _permissions = permissionsMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  /// Actualiza un permiso de acción individual.
  /// En caso de error, revierte el cambio y muestra un toast.
  Future<void> _togglePermission(String actionCode, bool newValue) async {
    final previousValue = _permissions[actionCode] ?? true;

    // Optimistic update
    setState(() {
      _permissions[actionCode] = newValue;
      _updatingActions.add(actionCode);
    });

    try {
      await PermissionsApiService.updateActionPermission(
        widget.roleId,
        'LEADS',
        actionCode,
        newValue,
      );
    } catch (e) {
      // Revert on failure
      if (mounted) {
        setState(() {
          _permissions[actionCode] = previousValue;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al actualizar permiso: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: TBColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _updatingActions.remove(actionCode);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: TBSpacing.sm),
      decoration: BoxDecoration(
        color: TBColors.surface,
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        border: Border.all(color: TBColors.grey300, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TBSpacing.md,
              TBSpacing.md,
              TBSpacing.md,
              TBSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: TBColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(TBSpacing.radiusSm),
                  ),
                  child: const Icon(
                    Icons.security_outlined,
                    color: TBColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: TBSpacing.sm),
                Text(
                  'Permisos de acciones',
                  style: TBTypography.titleMedium.copyWith(
                    color: TBColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: TBColors.grey300),
          // Content
          _buildContent(),
          // Campaign visibility section
          CampaignVisibilitySection(roleId: widget.roleId),
          const SizedBox(height: TBSpacing.sm),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(TBSpacing.lg),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: TBColors.primary,
            ),
          ),
        ),
      );
    }

    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.all(TBSpacing.md),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: TBColors.error.withOpacity(0.7),
              size: 32,
            ),
            const SizedBox(height: TBSpacing.sm),
            Text(
              'Error al cargar permisos',
              style: TBTypography.bodyMedium.copyWith(color: TBColors.error),
            ),
            const SizedBox(height: TBSpacing.xs),
            Text(
              _loadError!,
              style: TBTypography.bodySmall.copyWith(color: TBColors.grey600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TBSpacing.sm),
            TextButton.icon(
              onPressed: _loadPermissions,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar'),
              style: TextButton.styleFrom(foregroundColor: TBColors.primary),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TBSpacing.sm,
        vertical: TBSpacing.xs,
      ),
      child: Column(
        children: _leadsActions.map((action) {
          final isEnabled = _permissions[action.code] ?? true;
          final isUpdating = _updatingActions.contains(action.code);
          return _buildPermissionCheckbox(action, isEnabled, isUpdating);
        }).toList(),
      ),
    );
  }

  Widget _buildPermissionCheckbox(
    _ActionDefinition action,
    bool isEnabled,
    bool isUpdating,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TBSpacing.xs),
      child: Container(
        decoration: BoxDecoration(
          color: TBColors.white,
          borderRadius: BorderRadius.circular(TBSpacing.radiusSm),
        ),
        child: CheckboxListTile(
          value: isEnabled,
          onChanged: isUpdating
              ? null
              : (value) {
                  if (value != null) {
                    _togglePermission(action.code, value);
                  }
                },
          title: Text(
            action.label,
            style: TBTypography.bodyMedium.copyWith(
              color: isUpdating ? TBColors.grey500 : TBColors.black,
            ),
          ),
          secondary: isUpdating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: TBColors.primary,
                  ),
                )
              : Icon(
                  action.icon,
                  color: isEnabled ? TBColors.primary : TBColors.grey400,
                  size: 22,
                ),
          activeColor: TBColors.primary,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: TBSpacing.md,
            vertical: 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TBSpacing.radiusSm),
          ),
          dense: true,
        ),
      ),
    );
  }
}

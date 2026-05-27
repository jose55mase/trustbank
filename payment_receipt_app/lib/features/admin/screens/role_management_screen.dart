import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../models/role_model.dart';
import '../../../models/supervisor_assignment.dart';
import '../../../models/user_role.dart';
import '../../../services/api_service.dart';
import '../../../services/supervisor_assignments_service.dart';
import '../../../widgets/module_guard.dart';
import '../roles/services/roles_service.dart';
import '../users/widgets/role_assignment_dialog.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  List<dynamic> users = [];
  bool isLoading = true;

  /// Map of userId → SupervisorAssignment for quick lookup.
  Map<int, SupervisorAssignment> _supervisorAssignments = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final response = await ApiService.getAllUsers();
      setState(() {
        users = response;
        isLoading = false;
      });
      _loadSupervisorAssignments();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando usuarios: $e')),
        );
      }
    }
  }

  Future<void> _loadSupervisorAssignments() async {
    try {
      final assignments = await SupervisorAssignmentsService.getAll();
      if (mounted) {
        setState(() {
          _supervisorAssignments = {
            for (final a in assignments) a.userId: a,
          };
        });
      }
    } catch (_) {}
  }

  /// Extracts the highest-priority role from the user's `rols` array.
  UserRole _getUserRole(dynamic user) {
    final rols = user['rols'];
    if (rols != null && rols is List && rols.isNotEmpty) {
      return UserRole.fromBackendRoles(rols);
    }
    return UserRole.user;
  }

  /// Loads all supervisor assignments and builds a lookup map by userId.
  @override
  Widget build(BuildContext context) {
    return ModuleGuard(
      requiredModule: 'ROLE_MANAGEMENT',
      fallback: Scaffold(
        appBar: AppBar(title: const Text('Acceso Denegado')),
        body: const Center(
          child: Text('No tienes permisos para gestionar roles'),
        ),
      ),
      child: Scaffold(
        backgroundColor: TBColors.background,
        appBar: AppBar(
          title: const Text('Gestión de Roles'),
          backgroundColor: TBColors.primary,
          foregroundColor: TBColors.white,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(TBSpacing.md),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _buildUserCard(user);
                },
              ),
      ),
    );
  }

  Widget _buildUserCard(dynamic user) {
    final currentRole = _getUserRole(user);
    final userId = user['id'] as int?;
    final isSupervisor = currentRole == UserRole.supervisor;
    final assignment =
        (isSupervisor && userId != null) ? _supervisorAssignments[userId] : null;

    return Card(
      margin: const EdgeInsets.only(bottom: TBSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(TBSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: TBColors.primary.withOpacity(0.1),
                  child: Text(
                    user['name']?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: TBColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: TBSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'] ?? 'Usuario',
                        style: TBTypography.titleMedium,
                      ),
                      Text(
                        user['email'] ?? '',
                        style: TBTypography.bodySmall.copyWith(
                          color: TBColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildRoleChip(currentRole),
              ],
            ),
            if (isSupervisor) ...[
              const SizedBox(height: TBSpacing.sm),
              _buildCampaignInfo(user, assignment),
            ],
            const SizedBox(height: TBSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ID: ${user['id']}',
                    style: TBTypography.bodySmall,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _showRoleDialog(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TBColors.primary,
                    foregroundColor: TBColors.white,
                  ),
                  child: const Text('Cambiar Rol'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignInfo(dynamic user, SupervisorAssignment? assignment) {
    return Container(
      padding: const EdgeInsets.all(TBSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign, size: 18, color: Colors.purple),
          const SizedBox(width: TBSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Campaña Asignada',
                  style: TBTypography.bodySmall.copyWith(
                    color: TBColors.grey600,
                    fontSize: 11,
                  ),
                ),
                Text(
                  assignment?.assignmentTypeName ?? 'Sin campaña',
                  style: TBTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: assignment != null ? Colors.purple : TBColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => _changeCampaign(user),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Cambiar'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.purple,
              textStyle: TBTypography.bodySmall,
              padding: const EdgeInsets.symmetric(
                horizontal: TBSpacing.sm,
                vertical: TBSpacing.xs,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeCampaign(dynamic user) async {
    final userId = user['id'] as int?;
    if (userId == null) return;

    final newCampaign = await RoleAssignmentDialog.show(context);
    if (newCampaign == null) return;

    try {
      await SupervisorAssignmentsService.update(userId, newCampaign.id);
      await _loadSupervisorAssignments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Campaña actualizada a: ${newCampaign.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error actualizando campaña: $e')),
        );
      }
    }
  }

  Widget _buildRoleChip(UserRole role) {
    Color color;
    switch (role) {
      case UserRole.superAdmin:
        color = Colors.red;
        break;
      case UserRole.admin:
        color = Colors.orange;
        break;
      case UserRole.supervisor:
        color = Colors.purple;
        break;
      case UserRole.moderator:
        color = Colors.blue;
        break;
      case UserRole.user:
        color = Colors.green;
        break;
    }

    return Chip(
      label: Text(
        _getRoleDisplayName(role),
        style: TextStyle(color: color, fontSize: 12),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color),
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.admin:
        return 'Administrador';
      case UserRole.supervisor:
        return 'Asesor';
      case UserRole.moderator:
        return 'Moderador';
      case UserRole.user:
        return 'Usuario';
    }
  }

  void _showRoleDialog(dynamic user) {
    showDialog(
      context: context,
      builder: (dialogContext) => _DynamicRoleDialog(
        userName: user['name'] ?? 'Usuario',
        currentRoleName: _getUserRoleName(user),
        onRoleSelected: (roleName) async {
          await _updateUserRole(user, roleName);
        },
      ),
    );
  }

  /// Gets the role name string from the user's rols array.
  String _getUserRoleName(dynamic user) {
    final rols = user['rols'];
    if (rols != null && rols is List && rols.isNotEmpty) {
      return rols[0]['name'] ?? 'ROLE_USER';
    }
    return 'ROLE_USER';
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Acceso completo al sistema';
      case UserRole.admin:
        return 'Gestión de usuarios y transacciones';
      case UserRole.supervisor:
        return 'Asesor: visualización y edición de leads asignados';
      case UserRole.moderator:
        return 'Solo visualización de reportes';
      case UserRole.user:
        return 'Usuario básico';
    }
  }

  Future<void> _updateUserRole(dynamic user, String roleName) async {
    try {
      await ApiService.updateUserRole(user['id'], roleName);

      if (mounted) {
        Navigator.pop(context);
      }

      // Si el nuevo rol es Asesor, abrir modal para asignar campaña
      if (roleName == 'ROLE_SUPERVISOR') {
        final campaign = await RoleAssignmentDialog.show(context);
        if (campaign != null) {
          await SupervisorAssignmentsService.update(user['id'], campaign.id);
        }
      }

      // Reload users to get fresh role data from backend
      await _loadUsers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rol actualizado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error actualizando rol: $e')),
        );
      }
    }
  }
}

/// Dialog that loads roles dynamically from the API.
class _DynamicRoleDialog extends StatefulWidget {
  final String userName;
  final String currentRoleName;
  final Future<void> Function(String roleName) onRoleSelected;

  const _DynamicRoleDialog({
    required this.userName,
    required this.currentRoleName,
    required this.onRoleSelected,
  });

  @override
  State<_DynamicRoleDialog> createState() => _DynamicRoleDialogState();
}

class _DynamicRoleDialogState extends State<_DynamicRoleDialog> {
  List<RoleModel>? _roles;
  bool _isLoading = true;
  String? _selectedRoleName;

  @override
  void initState() {
    super.initState();
    _selectedRoleName = widget.currentRoleName;
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    try {
      final roles = await RolesService.getRoles();
      if (mounted) {
        setState(() {
          _roles = roles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TBSpacing.radiusLg),
      ),
      title: Text('Cambiar rol de ${widget.userName}'),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : _roles == null || _roles!.isEmpty
              ? const Text('No hay roles disponibles')
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _roles!.map((role) {
                      return RadioListTile<String>(
                        title: Text(role.name),
                        subtitle: Text(
                          '${role.modules.length} módulos · ${role.userCount} usuarios',
                          style: TBTypography.bodySmall.copyWith(color: TBColors.grey600),
                        ),
                        value: role.name,
                        groupValue: _selectedRoleName,
                        activeColor: TBColors.primary,
                        onChanged: (value) {
                          setState(() {
                            _selectedRoleName = value;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _selectedRoleName != null && _selectedRoleName != widget.currentRoleName
              ? () => widget.onRoleSelected(_selectedRoleName!)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: TBColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
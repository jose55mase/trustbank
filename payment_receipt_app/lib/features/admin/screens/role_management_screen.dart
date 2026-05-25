import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../models/user_role.dart';
import '../../../services/api_service.dart';
import '../../../widgets/module_guard.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  List<dynamic> users = [];
  bool isLoading = true;

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
        return 'Supervisor';
      case UserRole.moderator:
        return 'Moderador';
      case UserRole.user:
        return 'Usuario';
    }
  }

  void _showRoleDialog(dynamic user) {
    final currentRole = _getUserRole(user);
    UserRole selectedRole = currentRole;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Cambiar rol de ${user['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: UserRole.values.map((role) {
              return RadioListTile<UserRole>(
                title: Text(_getRoleDisplayName(role)),
                subtitle: Text(_getRoleDescription(role)),
                value: role,
                groupValue: selectedRole,
                onChanged: (value) {
                  setDialogState(() {
                    selectedRole = value!;
                  });
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selectedRole != currentRole
                  ? () => _updateUserRole(user, selectedRole)
                  : null,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Acceso completo al sistema';
      case UserRole.admin:
        return 'Gestión de usuarios y transacciones';
      case UserRole.supervisor:
        return 'Visualización y edición de leads asignados';
      case UserRole.moderator:
        return 'Solo visualización de reportes';
      case UserRole.user:
        return 'Usuario básico';
    }
  }

  Future<void> _updateUserRole(dynamic user, UserRole newRole) async {
    try {
      await ApiService.updateUserRole(user['id'], newRole.value);

      if (mounted) {
        Navigator.pop(context);
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
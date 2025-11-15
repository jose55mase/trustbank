import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../models/user_role.dart';
import '../../../services/api_service.dart';
import '../../../widgets/role_guard.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  List<Map<String, dynamic>> users = [];
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

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      requiredPermission: Permission.manageRoles,
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

  Widget _buildUserCard(Map<String, dynamic> user) {
    final currentRole = UserRole.fromString(user['role'] ?? 'USER');
    
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
                    style: TextStyle(
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
      case UserRole.moderator:
        return 'Moderador';
      case UserRole.user:
        return 'Usuario';
    }
  }

  void _showRoleDialog(Map<String, dynamic> user) {
    final currentRole = UserRole.fromString(user['role'] ?? 'USER');
    UserRole selectedRole = currentRole;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                  setState(() {
                    selectedRole = value!;
                  });
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
      case UserRole.moderator:
        return 'Solo visualización de reportes';
      case UserRole.user:
        return 'Usuario básico';
    }
  }

  Future<void> _updateUserRole(Map<String, dynamic> user, UserRole newRole) async {
    try {
      await ApiService.updateUserRole(user['id'], newRole.value);
      
      setState(() {
        user['role'] = newRole.value;
      });
      
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rol actualizado correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error actualizando rol: $e')),
      );
    }
  }
}
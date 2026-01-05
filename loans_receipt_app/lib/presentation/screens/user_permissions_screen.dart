import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/api_service.dart';
import '../widgets/app_drawer.dart';

class UserPermissionsScreen extends StatefulWidget {
  const UserPermissionsScreen({super.key});

  @override
  State<UserPermissionsScreen> createState() => _UserPermissionsScreenState();
}

class _UserPermissionsScreenState extends State<UserPermissionsScreen> {
  List<dynamic> _authUsers = [];
  List<dynamic> _permissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Primero inicializar permisos
      try {
        await ApiService.initializePermissions();
      } catch (e) {
        print('Error inicializando permisos: $e');
      }
      
      // Luego cargar datos
      final users = await ApiService.getAuthUsers();
      final permissions = await ApiService.getAllPermissions();
      
      setState(() {
        _authUsers = users;
        _permissions = permissions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showUserPermissions(Map<String, dynamic> user) async {
    try {
      final userPermissions = await ApiService.getUserPermissions(user['id']);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => _UserPermissionsDialog(
            user: user,
            permissions: _permissions,
            userPermissions: userPermissions,
            onSave: (permissions) async {
              await ApiService.updateUserPermissions(user['id'], permissions);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Permisos actualizados correctamente'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showDeleteDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text('¿Estás seguro de que deseas eliminar al usuario "${user['username']}"?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteUser(user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    try {
      await ApiService.deleteAuthUser(user['id']);
      await _loadData(); // Recargar la lista
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario eliminado correctamente'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar usuario: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Permisos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _authUsers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No hay usuarios registrados', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _authUsers.length,
                  itemBuilder: (context, index) {
                    final user = _authUsers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: user['role'] == 'ADMIN' 
                              ? AppColors.primary 
                              : AppColors.secondary,
                          child: Icon(
                            user['role'] == 'ADMIN' 
                                ? Icons.admin_panel_settings 
                                : Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(user['username'] ?? 'Sin nombre'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['email'] ?? 'Sin email'),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: user['role'] == 'ADMIN' 
                                    ? AppColors.primary.withOpacity(0.1)
                                    : AppColors.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                user['role'] ?? 'USER',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: user['role'] == 'ADMIN' 
                                      ? AppColors.primary 
                                      : AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.settings),
                              onPressed: () => _showUserPermissions(user),
                              tooltip: 'Gestionar Permisos',
                            ),
                            if (user['role'] != 'ADMIN')
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _showDeleteDialog(user),
                                tooltip: 'Eliminar Usuario',
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _UserPermissionsDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  final List<dynamic> permissions;
  final List<dynamic> userPermissions;
  final Function(List<Map<String, dynamic>>) onSave;

  const _UserPermissionsDialog({
    required this.user,
    required this.permissions,
    required this.userPermissions,
    required this.onSave,
  });

  @override
  State<_UserPermissionsDialog> createState() => _UserPermissionsDialogState();
}

class _UserPermissionsDialogState extends State<_UserPermissionsDialog> {
  Map<int, bool> _permissionStates = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializePermissionStates();
  }

  void _initializePermissionStates() {
    // Inicializar todos los permisos como false
    for (var permission in widget.permissions) {
      _permissionStates[permission['id']] = false;
    }
    
    // Marcar como true los permisos que el usuario ya tiene
    for (var userPerm in widget.userPermissions) {
      if (userPerm['granted'] == true) {
        _permissionStates[userPerm['permission']['id']] = true;
      }
    }
  }

  Future<void> _savePermissions() async {
    setState(() => _isLoading = true);
    
    List<Map<String, dynamic>> permissions = [];
    _permissionStates.forEach((permissionId, granted) {
      permissions.add({
        'permissionId': permissionId,
        'granted': granted,
      });
    });
    
    try {
      await widget.onSave(permissions);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Permisos de Usuario',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.user['username'] ?? 'Usuario',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: widget.permissions.map<Widget>((permission) {
                    final permissionId = permission['id'];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: SwitchListTile(
                        title: Text(permission['name'] ?? 'Sin nombre'),
                        subtitle: Text(permission['description'] ?? 'Sin descripción'),
                        value: _permissionStates[permissionId] ?? false,
                        onChanged: (value) {
                          setState(() {
                            _permissionStates[permissionId] = value;
                          });
                        },
                        activeColor: AppColors.success,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _savePermissions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
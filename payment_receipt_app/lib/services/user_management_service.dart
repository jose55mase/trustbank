import 'api_service.dart';
import '../models/user_role.dart';
import '../features/admin/models/user_model.dart';

class UserManagementService {
  static Future<List<AdminUser>> getAllUsers() async {
    try {
      final response = await ApiService.getAllUsers();
      return response.map<AdminUser>((json) => AdminUser.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error obteniendo usuarios: $e');
    }
  }

  static Future<List<AdminUser>> getUsersByRole(UserRole role) async {
    try {
      final response = await ApiService.getUsersByStatus(role.value);
      return response.map<AdminUser>((json) => AdminUser.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error obteniendo usuarios por rol: $e');
    }
  }

  static Future<Map<String, dynamic>> updateUserRole(int userId, UserRole newRole) async {
    try {
      return await ApiService.updateUserRole(userId, newRole.value);
    } catch (e) {
      throw Exception('Error actualizando rol: $e');
    }
  }

  static Future<List<AdminUser>> getAdminUsers() async {
    try {
      final response = await ApiService.getAllUsers();
      final adminUsers = response.where((user) {
        final role = user['role']?.toString().toUpperCase() ?? 'USER';
        return role == 'ADMIN' || role == 'SUPER_ADMIN' || role == 'MODERATOR';
      }).toList();
      return adminUsers.map<AdminUser>((json) => AdminUser.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error obteniendo administradores: $e');
    }
  }

  static Future<Map<String, dynamic>> updateUserStatus(int userId, String status) async {
    try {
      return await ApiService.updateUserStatus(userId, status);
    } catch (e) {
      throw Exception('Error actualizando estado: $e');
    }
  }

  static Future<List<AdminUser>> filterUsers({
    String? status,
    String? searchQuery,
  }) async {
    try {
      final allUsers = await getAllUsers();
      var filteredUsers = allUsers;
      
      if (status != null && status.isNotEmpty) {
        filteredUsers = filteredUsers.where((user) => 
          user.accountStatus.toLowerCase() == status.toLowerCase()).toList();
      }
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        filteredUsers = filteredUsers.where((user) => 
          user.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(searchQuery.toLowerCase())).toList();
      }
      
      return filteredUsers;
    } catch (e) {
      throw Exception('Error filtrando usuarios: $e');
    }
  }

  static Future<bool> isUserAdmin(int userId) async {
    try {
      final user = await ApiService.getUserById(userId);
      final role = user['role']?.toString().toUpperCase() ?? 'USER';
      return role == 'ADMIN' || role == 'SUPER_ADMIN' || role == 'MODERATOR';
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> createAdminUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      final userData = {
        'name': name,
        'email': email,
        'password': password,
        'role': role.value,
        'accountStatus': 'ACTIVE',
        'moneyclean': 0.0,
        'balance': 0.0,
        'phone': '',
        'address': '',
        'documentType': 'CC',
        'documentNumber': '',
      };

      return await ApiService.registerUser(userData);
    } catch (e) {
      throw Exception('Error creando usuario admin: $e');
    }
  }
}
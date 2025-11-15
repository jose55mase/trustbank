import 'api_service.dart';
import '../models/user_role.dart';

class UserManagementService {
  static Future<List<dynamic>> getAllUsers() async {
    try {
      return await ApiService.getAllUsers();
    } catch (e) {
      throw Exception('Error obteniendo usuarios: $e');
    }
  }

  static Future<List<dynamic>> getUsersByRole(UserRole role) async {
    try {
      return await ApiService.getUsersByStatus(role.value);
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

  static Future<List<dynamic>> getAdminUsers() async {
    try {
      final allUsers = await getAllUsers();
      return allUsers.where((user) {
        final role = user['role']?.toString().toUpperCase() ?? 'USER';
        return role == 'ADMIN' || role == 'SUPER_ADMIN' || role == 'MODERATOR';
      }).toList();
    } catch (e) {
      throw Exception('Error obteniendo administradores: $e');
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
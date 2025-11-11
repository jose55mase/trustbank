import '../features/admin/models/user_model.dart';
import 'api_service.dart';

class UserManagementService {
  static Future<List<AdminUser>> getAllUsers() async {
    try {
      final response = await ApiService.getAllUsers();
      return response.map((data) => AdminUser.fromJson(data)).toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios: ${e.toString()}');
    }
  }

  static Future<AdminUser> getUserById(int userId) async {
    try {
      final response = await ApiService.getUserById(userId);
      return AdminUser.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener usuario: ${e.toString()}');
    }
  }

  static Future<bool> updateUserStatus(int userId, UserStatus status) async {
    try {
      await ApiService.updateUserStatus(userId, status.name.toUpperCase());
      return true;
    } catch (e) {
      throw Exception('Error al actualizar estado: ${e.toString()}');
    }
  }

  static Future<List<AdminUser>> getUsersByStatus(UserStatus status) async {
    try {
      final response = await ApiService.getUsersByStatus(status.name.toUpperCase());
      return response.map((data) => AdminUser.fromJson(data)).toList();
    } catch (e) {
      throw Exception('Error al filtrar usuarios: ${e.toString()}');
    }
  }

  static Future<List<AdminUser>> searchUsers(String query) async {
    try {
      final response = await ApiService.searchUsers(query);
      return response.map((data) => AdminUser.fromJson(data)).toList();
    } catch (e) {
      throw Exception('Error al buscar usuarios: ${e.toString()}');
    }
  }

  static Future<Map<String, int>> getUserStats() async {
    try {
      final response = await ApiService.getUserStats();
      return {
        'total': response['total'] ?? 0,
        'active': response['active'] ?? 0,
        'inactive': response['inactive'] ?? 0,
        'pending': response['pending'] ?? 0,
        'suspended': response['suspended'] ?? 0,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: ${e.toString()}');
    }
  }

  static Future<List<AdminUser>> filterUsers({
    UserStatus? status,
    String? searchQuery,
  }) async {
    try {
      List<AdminUser> users;

      if (searchQuery != null && searchQuery.isNotEmpty) {
        users = await searchUsers(searchQuery);
      } else if (status != null) {
        users = await getUsersByStatus(status);
      } else {
        users = await getAllUsers();
      }

      // Aplicar filtros adicionales si es necesario
      if (status != null && searchQuery != null && searchQuery.isNotEmpty) {
        users = users.where((user) => 
          user.accountStatus.toLowerCase() == status.name.toLowerCase()
        ).toList();
      }

      return users;
    } catch (e) {
      throw Exception('Error al filtrar usuarios: ${e.toString()}');
    }
  }

  static String getStatusDisplayName(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return 'Activo';
      case UserStatus.inactive:
        return 'Inactivo';
      case UserStatus.pending:
        return 'Pendiente';
      case UserStatus.suspended:
        return 'Suspendido';
    }
  }

  static UserStatus? parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return UserStatus.active;
      case 'inactive':
        return UserStatus.inactive;
      case 'pending':
        return UserStatus.pending;
      case 'suspended':
        return UserStatus.suspended;
      default:
        return null;
    }
  }
}
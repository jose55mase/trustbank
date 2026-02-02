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

  static Future<Map<String, dynamic>> getUsersPaginated({
    int page = 0,
    int size = 20,
    String sortBy = 'registrationDate',
    String sortDir = 'desc',
  }) async {
    try {
      final response = await ApiService.getUsersPaginated(
        page: page,
        size: size,
        sortBy: sortBy,
        sortDir: sortDir,
      );
      
      final users = (response['users'] as List)
          .map<AdminUser>((json) => AdminUser.fromJson(json))
          .toList();
      
      return {
        'users': users,
        'currentPage': response['currentPage'],
        'totalItems': response['totalItems'],
        'totalPages': response['totalPages'],
        'hasNext': response['hasNext'],
        'hasPrevious': response['hasPrevious'],
      };
    } catch (e) {
      throw Exception('Error obteniendo usuarios paginados: $e');
    }
  }

  static Future<List<AdminUser>> getUsersByRole(UserRole role) async {
    try {
      // Get all users and filter by role locally since backend doesn't have role-specific endpoint
      final allUsers = await getAllUsers();
      return allUsers.where((user) {
        // Check if user has the specified role in their rols array
        return _userHasRole(user, role);
      }).toList();
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
      final allUsers = await getAllUsers();
      return allUsers.where((user) {
        return _userHasRole(user, UserRole.admin) || 
               _userHasRole(user, UserRole.superAdmin) || 
               _userHasRole(user, UserRole.moderator);
      }).toList();
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
      final adminUser = AdminUser.fromJson(user);
      return _userHasRole(adminUser, UserRole.admin) || 
             _userHasRole(adminUser, UserRole.superAdmin) || 
             _userHasRole(adminUser, UserRole.moderator);
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
        'fistName': name, // Backend uses 'fistName' (typo in backend)
        'email': email,
        'password': password,
        'accountStatus': 'ACTIVE',
        'moneyclean': 0,
        'status': true,
        'phone': '',
        'address': '',
        'documentType': 'CC',
        'documentNumber': '',
        'username': email.split('@')[0],
      };

      final response = await ApiService.registerUser(userData);
      
      // After user creation, assign role
      if (response['id'] != null) {
        await ApiService.updateUserRole(response['id'], role.value);
      }
      
      return response;
    } catch (e) {
      throw Exception('Error creando usuario admin: $e');
    }
  }
  
  // Helper method to check if user has specific role
  static bool _userHasRole(AdminUser user, UserRole role) {
    return user.hasRole(role);
  }
}
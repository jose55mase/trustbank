import 'api_service.dart';
import 'auth_service.dart';

class UserService {
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null || currentUser['id'] == null) {
        return null;
      }

      final userId = currentUser['id'];
      final userProfile = await ApiService.getUserById(userId);
      
      return userProfile;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  static Future<List<dynamic>> getUserDocuments() async {
    try {
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null || currentUser['id'] == null) {
        return [];
      }

      final userId = currentUser['id'];
      return await ApiService.getUserDocuments(userId);
    } catch (e) {
      print('Error getting user documents: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> userData) async {
    try {
      return await ApiService.updateUser(userData);
    } catch (e) {
      throw Exception('Error updating user profile: $e');
    }
  }

  static String formatAccountStatus(String? status) {
    if (status == null) return 'Desconocido';
    
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return 'Activa';
      case 'INACTIVE':
        return 'Inactiva';
      case 'SUSPENDED':
        return 'Suspendida';
      case 'PENDING':
        return 'Pendiente';
      case 'VERIFIED':
        return 'Verificada';
      default:
        return status;
    }
  }

  static String formatUserRole(String? role) {
    if (role == null) return 'Usuario';
    
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'Administrador';
      case 'USER':
        return 'Usuario';
      case 'MODERATOR':
        return 'Moderador';
      default:
        return role;
    }
  }

  static String formatDate(String? dateString) {
    if (dateString == null) return 'No disponible';
    
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
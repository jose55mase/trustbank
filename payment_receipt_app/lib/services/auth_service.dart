import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_role.dart';
import 'api_service.dart';

class AuthService {
  static const String _userDataKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<UserRole> getCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    
    if (userDataString != null) {
      final userData = json.decode(userDataString);
      
      // Handle backend role structure - UserEntity has List<RolEntity> rols
      if (userData['rols'] != null && userData['rols'] is List) {
        return UserRole.fromBackendRoles(userData['rols']);
      }
      
      // Fallback to single role field if exists
      final roleString = userData['role'] ?? 'ROLE_USER';
      return UserRole.fromString(roleString);
    }
    
    return UserRole.user;
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    
    if (userDataString != null) {
      return json.decode(userDataString);
    }
    
    return null;
  }

  static Future<bool> hasPermission(Permission permission) async {
    final role = await getCurrentUserRole();
    return RolePermissions.hasPermission(role, permission);
  }

  static Future<List<Permission>> getCurrentUserPermissions() async {
    final role = await getCurrentUserRole();
    return RolePermissions.getPermissions(role);
  }

  static Future<void> updateUserRole(int userId, UserRole newRole) async {
    try {
      // Update role in backend
      await ApiService.updateUserRole(userId, newRole.value);
      
      // Update local storage
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userDataKey);
      
      if (userDataString != null) {
        final userData = json.decode(userDataString);
        if (userData['id'] == userId) {
          // Update the rols array to match backend structure
          userData['rols'] = [{'id': 1, 'name': newRole.value}];
          await prefs.setString(_userDataKey, json.encode(userData));
        }
      }
    } catch (e) {
      throw Exception('Error updating user role: $e');
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  static Future<int?> getCurrentUserId() async {
    final user = await getCurrentUser();
    return user?['id'];
  }

  static Future<void> refreshCurrentUser() async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser != null && currentUser['email'] != null) {
        final userData = await ApiService.getUserByEmail(currentUser['email']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userDataKey, json.encode(userData));
      }
    } catch (e) {
      // Ignore refresh errors
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // Usar ApiService para login real con backend
      final response = await ApiService.login(email, password);
      
      if (response['access_token'] != null) {
        // Guardar token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response['access_token']);
        
        // Obtener datos del usuario
        final userData = await ApiService.getUserByEmail(email);
        await prefs.setString(_userDataKey, json.encode(userData));
        await prefs.setBool(_isLoggedInKey, true);
        
        return {'success': true, 'user': userData};
      } else {
        return {'success': false, 'error': 'Credenciales inválidas'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
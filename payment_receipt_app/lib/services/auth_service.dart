import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_role.dart';

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
      final roleString = userData['role'] ?? 'USER';
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
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    
    if (userDataString != null) {
      final userData = json.decode(userDataString);
      if (userData['id'] == userId) {
        userData['role'] = newRole.value;
        await prefs.setString(_userDataKey, json.encode(userData));
      }
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

  static Future<Map<String, dynamic>> login(String email, String password) async {
    // Implementación básica - en producción usar ApiService
    return {'success': true, 'user': {'id': 1, 'email': email}};
  }
}
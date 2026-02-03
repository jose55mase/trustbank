import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  static const String _userKey = 'user_data';
  
  static Future<void> saveUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userData));
  }
  
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }
  
  static Future<String?> getUserRole() async {
    final user = await getUser();
    return user?['role'];
  }
  
  static Future<bool> hasPermission(String permission) async {
    final user = await getUser();
    final role = user?['role'];
    final permissions = user?['permissions'] as List<dynamic>? ?? [];
    
    
    // Admin siempre tiene todos los permisos
    if (role == 'ADMIN') {
      return true;
    }
    
    // Verificar si el usuario tiene el permiso específico
    final hasPermission = permissions.contains(permission);
    return hasPermission;
  }
  
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}
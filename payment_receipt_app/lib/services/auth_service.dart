import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await ApiService.login(email, password);

      if (response['access_token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, response['access_token']);
        
        // Obtener datos del usuario
        final userData = await ApiService.getUserByEmail(email);
        print('Getting userData --> ${userData}');
        
        // Validar estado de la cuenta
        final accountStatus = userData['accountStatus']?.toString().toUpperCase();
        if (accountStatus == 'SUSPENDED') {
          return {
            'success': false, 
            'error': 'Tu cuenta ha sido suspendida. Contacta al administrador para más información.',
            'suspended': true
          };
        }
        
        if (accountStatus == 'INACTIVE') {
          return {
            'success': false, 
            'error': 'Tu cuenta está inactiva. Contacta al administrador.',
            'inactive': true
          };
        }
        
        // Asegurar que tenemos el nombre del usuario
        if (userData['firstName'] == null && userData['name'] != null) {
          userData['firstName'] = userData['name'];
        }
        
        await prefs.setString(_userKey, json.encode(userData));
        
        return {'success': true, 'user': userData};
      }
      return {'success': false, 'error': 'Token no recibido'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey) != null;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);
    if (userString != null) {
      return json.decode(userString);
    }
    return null;
  }

  static Future<int?> getCurrentUserId() async {
    final user = await getCurrentUser();
    return user?['id'];
  }
}
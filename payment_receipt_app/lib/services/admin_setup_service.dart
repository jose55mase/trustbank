import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


class AdminSetupService {
  static Future<void> createDefaultAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final hasDefaultAdmin = prefs.getBool('has_default_admin') ?? false;
    
    if (!hasDefaultAdmin) {
      // Crear admin por defecto con estructura backend
      final adminUser = {
        'id': 999,
        'fistName': 'Administrador', // Backend uses 'fistName'
        'email': 'admin@trustbank.com',
        'username': 'admin',
        'password': 'admin123',
        'accountStatus': 'ACTIVE',
        'status': true,
        'moneyclean': 0,
        'createdAt': DateTime.now().toIso8601String(),
        'rols': [
          {
            'id': 2,
            'name': 'ROLE_ADMIN'
          }
        ],
      };
      
      await prefs.setString('default_admin', json.encode(adminUser));
      await prefs.setBool('has_default_admin', true);
    }
  }
  
  static Future<Map<String, dynamic>?> getDefaultAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final adminString = prefs.getString('default_admin');
    
    if (adminString != null) {
      return json.decode(adminString);
    }
    return null;
  }
  
  static Future<bool> isDefaultAdmin(String email, String password) async {
    final admin = await getDefaultAdmin();
    return admin != null && 
           admin['email'] == email && 
           admin['password'] == password;
  }
}
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _usersKey = 'cached_users';
  static const String _loansKey = 'cached_loans';
  static const String _userLoansPrefix = 'cached_user_loans_';
  static const String _timestampKey = 'cache_timestamp';
  static const Duration _cacheExpiration = Duration(hours: 1);

  // Guardar usuarios en caché
  static Future<void> saveUsers(List<dynamic> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users));
    await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Obtener usuarios del caché
  static Future<List<dynamic>?> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (!_isCacheValid(prefs)) return null;
    
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) return null;
    
    return jsonDecode(usersJson);
  }

  // Guardar préstamos en caché
  static Future<void> saveLoans(List<dynamic> loans) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loansKey, jsonEncode(loans));
  }

  // Obtener préstamos del caché
  static Future<List<dynamic>?> getLoans() async {
    final prefs = await SharedPreferences.getInstance();
    final loansJson = prefs.getString(_loansKey);
    if (loansJson == null) return null;
    return jsonDecode(loansJson);
  }

  // Verificar si el caché es válido
  static bool _isCacheValid(SharedPreferences prefs) {
    final timestamp = prefs.getInt(_timestampKey);
    if (timestamp == null) return false;
    
    final cacheDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    
    return now.difference(cacheDate) < _cacheExpiration;
  }

  // Limpiar caché
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usersKey);
    await prefs.remove(_loansKey);
    await prefs.remove(_timestampKey);
    
    // Limpiar cachés de préstamos por usuario
    final keys = prefs.getKeys();
    for (var key in keys) {
      if (key.startsWith(_userLoansPrefix)) {
        await prefs.remove(key);
      }
    }
  }
  
  // Guardar préstamos de un usuario
  static Future<void> saveUserLoans(String userId, List<dynamic> loans) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_userLoansPrefix}$userId', jsonEncode(loans));
  }
  
  // Obtener préstamos de un usuario
  static Future<List<dynamic>?> getUserLoans(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (!_isCacheValid(prefs)) return null;
    
    final loansJson = prefs.getString('${_userLoansPrefix}$userId');
    if (loansJson == null) return null;
    
    return jsonDecode(loansJson);
  }
  
  // Guardar notas de préstamos de un usuario
  static Future<void> saveUserLoanNotes(String userId, Map<String, String> notes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_userLoansPrefix}${userId}_notes', jsonEncode(notes));
  }
  
  // Obtener notas de préstamos de un usuario
  static Future<Map<String, String>?> getUserLoanNotes(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (!_isCacheValid(prefs)) return null;
    
    final notesJson = prefs.getString('${_userLoansPrefix}${userId}_notes');
    if (notesJson == null) return null;
    
    final decoded = jsonDecode(notesJson) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value.toString()));
  }
}

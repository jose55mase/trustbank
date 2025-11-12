import 'dart:convert';
import 'api_service.dart';

class RegisterService {
  static Future<Map<String, dynamic>> registerUser({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final userData = {
        'fistName': firstName,
        'lastName': lastName,
        'username': username,
        'email': email,
        'phone': phone,
        'password': password,
        'accountStatus': 'ACTIVE',
        'status': true,
      };

      final response = await ApiService.registerUser(userData);
      
      // Verificar si la respuesta indica éxito
      if (response['status'] == 200) {
        return {
          'success': true,
          'message': response['message'] ?? 'Usuario registrado exitosamente',
          'user': response['data'],
        };
      } else {
        return {
          'success': false,
          'error': response['message'] ?? 'Error al registrar usuario',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

}
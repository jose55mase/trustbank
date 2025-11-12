import 'api_service.dart';

class RegisterService {
  static Future<Map<String, dynamic>> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final userData = {
        'fistName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'password': password,
        'accountStatus': 'ACTIVE',
        'status': true,
      };

      final user = await ApiService.registerUser(userData);
      return {
        'success': true,
        'message': 'Usuario registrado exitosamente',
        'user': user,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString().contains('Failed to register user') 
            ? 'El email ya está registrado o hay un error en los datos'
            : 'Error de conexión: ${e.toString()}',
      };
    }
  }

}
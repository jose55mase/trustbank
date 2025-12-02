import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'https://guardianstrustbank.com:8081/api';
  static String credentials = base64Encode(utf8.encode('angularapp:12345'));
  
  static Future<Map<String, String>> get headers async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : 'Basic $credentials',
    };
  }

  // Auth endpoints
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final body = 'grant_type=password&username=${Uri.encodeComponent(email)}&password=${Uri.encodeComponent(password)}';

      final response = await http.post(
        Uri.parse('https://guardianstrustbank.com:8081/oauth/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic $credentials',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Credenciales inválidas');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  // User endpoints
  static Future<Map<String, dynamic>> registerUser(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/save'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(userData),
    );

    // Siempre retornar la respuesta del backend sin lanzar excepción
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> getUserByEmail(String email) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/getUserByEmail/$email'),
      headers: await headers,
    );
    // Response logged for debugging
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get user');
    }
  }



  static Future<Map<String, dynamic>> updateUser(Map<String, dynamic> userData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/user/update'),
      headers: await headers,
      body: json.encode(userData),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update user');
    }
  }





  // Document endpoints
  static Future<Map<String, dynamic>> uploadDocument(
    File file,
    int userId,
    String documentType,
  ) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/documents/upload'),
    );

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['userId'] = userId.toString();
    request.fields['documentType'] = documentType;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      return json.decode(responseBody);
    } else {
      throw Exception('Failed to upload document');
    }
  }

  static Future<List<dynamic>> getUserDocuments(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/documents/user/$userId?sort=createdAt,desc'),
      headers: await headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Failed to get documents');
    }
  }

  static Future<List<dynamic>> getPendingDocuments() async {
    final response = await http.get(
      Uri.parse('$baseUrl/documents/pending?sort=createdAt,desc'),
      headers: await headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Failed to get pending documents');
    }
  }

  static Future<Map<String, dynamic>> processDocument(
    int documentId,
    String status,
    String? adminNotes,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/documents/process/$documentId?status=$status${adminNotes != null ? '&adminNotes=$adminNotes' : ''}'),
      headers: await headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to process document');
    }
  }

  // Admin Request endpoints
  static Future<Map<String, dynamic>> createAdminRequest(Map<String, dynamic> requestData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin-requests/create'),
      headers: await headers,
      body: json.encode(requestData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'status': response.statusCode,
        'data': data,
        'message': 'Success'
      };
    } else {
      final errorData = json.decode(response.body);
      return {
        'status': response.statusCode,
        'message': errorData['message'] ?? 'Server error: ${response.statusCode}'
      };
    }
  }

  static Future<Map<String, dynamic>> getAllAdminRequests() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin-requests/all?sort=createdAt,desc'),
      headers: await headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'status': response.statusCode,
        'data': data['data'] ?? [],
        'message': 'Success'
      };
    } else {
      return {
        'status': response.statusCode,
        'message': 'Failed to get requests'
      };
    }
  }

  static Future<List<dynamic>> getPendingAdminRequests() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin-requests/pending?sort=createdAt,desc'),
      headers: await headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Failed to get pending requests');
    }
  }

  static Future<Map<String, dynamic>> processAdminRequest(
    int requestId,
    String status,
    String? adminNotes,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin-requests/process/$requestId?status=$status${adminNotes != null ? '&adminNotes=$adminNotes' : ''}'),
      headers: await headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to process request');
    }
  }

  // Transaction endpoints
  static Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> transactionData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transaction/save'),
      headers: await headers,
      body: json.encode(transactionData),
    );

    if (response.statusCode == 200) {
      return {'success': true};
    } else {
      throw Exception('Failed to create transaction');
    }
  }

  static Future<List<dynamic>> getUserTransactions(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/transaction/findByUser?idUser=$userId&sort=date,desc'),
      headers: await headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get transactions');
    }
  }

  // Notification endpoints
  static Future<Map<String, dynamic>> createNotification(Map<String, dynamic> notificationData) async {
    // Enriquecer con datos del usuario actual
    final currentUser = await AuthService.getCurrentUser();
    final enrichedData = {
      ...notificationData,
      'userName': currentUser?['name'] ?? 'Usuario',
      'userEmail': currentUser?['email'] ?? 'usuario@trustbank.com',
      'userPhone': currentUser?['phone'] ?? '+1 234 567 8900',
    };
    
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/create'),
      headers: await headers,
      body: json.encode(enrichedData),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create notification');
    }
  }

  static Future<List<dynamic>> getUserNotifications(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/user/$userId?sort=createdAt,desc'),
      headers: await headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] ?? data ?? [];
    } else {
      throw Exception('Failed to get notifications');
    }
  }

  static Future<List<dynamic>> getUnreadNotifications(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/user/$userId/unread'),
      headers: await headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Failed to get unread notifications');
    }
  }

  static Future<Map<String, dynamic>> markNotificationAsRead(int notificationId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/notifications/mark-read/$notificationId'),
      headers: await headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to mark notification as read');
    }
  }

  // Credit endpoints
  static Future<Map<String, dynamic>> simulateCredit(Map<String, dynamic> creditData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/credits/simulate'),
      headers: await headers,
      body: json.encode(creditData),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to simulate credit');
    }
  }

  static Future<Map<String, dynamic>> applyForCredit(Map<String, dynamic> creditData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/credits/apply'),
        headers: await headers,
        body: json.encode(creditData),
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'status': response.statusCode,
          'data': responseData,
          'message': 'Solicitud enviada exitosamente'
        };
      } else if (response.statusCode == 400) {
        return {
          'status': response.statusCode,
          'message': responseData['message'] ?? 'Datos de solicitud inválidos'
        };
      } else if (response.statusCode == 409) {
        return {
          'status': response.statusCode,
          'message': 'Ya tienes una solicitud de crédito pendiente'
        };
      } else {
        return {
          'status': response.statusCode,
          'message': responseData['message'] ?? 'Error al procesar la solicitud'
        };
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        throw Exception('Error de conexión. Verifica tu internet e inténtalo nuevamente.');
      } else {
        throw Exception('Error inesperado: ${e.toString()}');
      }
    }
  }

  static Future<Map<String, dynamic>> getUserCreditApplications(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/credits/user/$userId/applications?sort=applicationDate,desc'),
      headers: await headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get credit applications');
    }
  }

  static Future<Map<String, dynamic>> getCreditApplicationStatus(int applicationId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/credits/application/$applicationId/status'),
      headers: await headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get application status');
    }
  }

  static Future<List<dynamic>> getUserCredits(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/credits/user/$userId'),
      headers: await headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Failed to get user credits');
    }
  }

  static Future<List<dynamic>> getPendingCredits() async {
    final response = await http.get(
      Uri.parse('$baseUrl/credits/pending'),
      headers: await headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Failed to get pending credits');
    }
  }

  static Future<Map<String, dynamic>> approveCredit(int creditId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/credits/approve/$creditId'),
      headers: await headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to approve credit');
    }
  }

  // User management endpoints
  static Future<List<dynamic>> getAllUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/all?sort=createdAt,desc'),
      headers: await headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data is List ? data : data['data'] ?? [];
    } else {
      throw Exception('Failed to get users');
    }
  }

  static Future<Map<String, dynamic>> getUserById(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/$userId'),
      headers: await headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'status': response.statusCode,
        'data': data,
        'message': 'Success'
      };
    } else {
      return {
        'status': response.statusCode,
        'message': 'Failed to get user'
      };
    }
  }

  static Future<Map<String, dynamic>> updateUserStatus(int userId, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/user/updateStatus/$userId'),
      headers: await headers,
      body: json.encode({'accountStatus': status}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update user status');
    }
  }

  static Future<List<dynamic>> getUsersByStatus(String status) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/byStatus/$status?sort=createdAt,desc'),
      headers: await headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data is List ? data : data['data'] ?? [];
    } else {
      throw Exception('Failed to get users by status');
    }
  }

  static Future<List<dynamic>> searchUsers(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/search?q=${Uri.encodeComponent(query)}&sort=createdAt,desc'),
      headers: await headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data is List ? data : data['data'] ?? [];
    } else {
      throw Exception('Failed to search users');
    }
  }

  static Future<Map<String, dynamic>> getUserStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/stats'),
      headers: await headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get user stats');
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/logout'),
        headers: await headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to logout');
      }
    } catch (e) {
      // Si hay error de token inválido, considerarlo como logout exitoso
      if (e.toString().contains('invalid_token')) {
        return {'success': true, 'message': 'Sesión cerrada'};
      }
      throw e;
    }
  }

  // Role management endpoints
  static Future<Map<String, dynamic>> updateUserRole(int userId, String role) async {
    final response = await http.put(
      Uri.parse('$baseUrl/user/updateRole/$userId'),
      headers: await headers,
      body: json.encode({'role': role}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update user role');
    }
  }
  
  // Change password endpoint
  static Future<Map<String, dynamic>> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/user/changePassword'),
      headers: await headers,
      body: json.encode({
        'email': email,
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 400 || response.statusCode == 404) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Error al cambiar contraseña');
    } else {
      throw Exception('Error del servidor');
    }
  }
}
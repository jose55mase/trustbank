import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8081/api';
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
        Uri.parse('http://localhost:8081/oauth/token'),
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
  static Future<Map<String, dynamic>> getUserByEmail(String email) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/getUserByEmail/$email'),
      headers: await headers,
    );
    print('Response get user ----> ${response.body}');
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

  static Future<Map<String, dynamic>> incrementUserBalance(int userId, double amount) async {
    final response = await http.put(
      Uri.parse('$baseUrl/user/incrementBalance'),
      headers: await headers,
      body: json.encode({
        'userId': userId,
        'amount': amount,
      }),
    );

    print('Increment balance response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to increment balance: ${response.body}');
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

    print('Create request response status: ${response.statusCode}');
    print('Create request response body: ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Server error: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<List<dynamic>> getAllAdminRequests() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin-requests/all?sort=createdAt,desc'),
      headers: await headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Failed to get requests');
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
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/create'),
      headers: await headers,
      body: json.encode(notificationData),
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
      return data['data'] ?? [];
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
    final response = await http.post(
      Uri.parse('$baseUrl/credits/apply'),
      headers: await headers,
      body: json.encode(creditData),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to apply for credit');
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
}
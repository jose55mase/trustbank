import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8081/api';
  
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Auth endpoints
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/oauth/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic YW5ndWxhcmFwcDpteXNlY3JldA==',
        },
        body: {
          'grant_type': 'password',
          'username': email,
          'password': password,
        },
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
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get user');
    }
  }

  static Future<Map<String, dynamic>> updateUser(Map<String, dynamic> userData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/user/update'),
      headers: headers,
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
      Uri.parse('$baseUrl/documents/user/$userId'),
      headers: headers,
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
      Uri.parse('$baseUrl/documents/pending'),
      headers: headers,
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
      headers: headers,
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
      headers: headers,
      body: json.encode(requestData),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create request');
    }
  }

  static Future<List<dynamic>> getAllAdminRequests() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin-requests/all'),
      headers: headers,
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
      Uri.parse('$baseUrl/admin-requests/pending'),
      headers: headers,
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
      headers: headers,
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
      headers: headers,
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
      Uri.parse('$baseUrl/transaction/findByUser?idUser=$userId'),
      headers: headers,
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
      headers: headers,
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
      Uri.parse('$baseUrl/notifications/user/$userId'),
      headers: headers,
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
      headers: headers,
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
      headers: headers,
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
      headers: headers,
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
      headers: headers,
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
      headers: headers,
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
      headers: headers,
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
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to approve credit');
    }
  }
}
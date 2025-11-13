import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class DocumentApiService {
  static const String baseUrl = 'http://localhost:8080/api';

  static Future<Map<String, dynamic>> uploadUserDocuments({
    required int userId,
    Uint8List? documentFront,
    Uint8List? documentBack,
    Uint8List? clientPhoto,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/documents/users/$userId/images'),
      );

      if (documentFront != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'documentFrom',
            documentFront,
            filename: 'document_front.jpg',
          ),
        );
      }

      if (documentBack != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'documentBack',
            documentBack,
            filename: 'document_back.jpg',
          ),
        );
      }

      if (clientPhoto != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'foto',
            clientPhoto,
            filename: 'client_photo.jpg',
          ),
        );
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseData);
      } else {
        throw Exception('Error al subir documentos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>> updateDocumentStatus({
    required int userId,
    required String documentType,
    required String status,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/documents/users/$userId/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'documentType': documentType,
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al actualizar estado: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>> getUserDocuments(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/documents/users/$userId/images'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener documentos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAllUsersWithDocuments() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/documents/admin/users'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error al obtener usuarios: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
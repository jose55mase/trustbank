import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DocumentApiService {
  static const String baseUrl = 'https://guardianstrustbank.com/:8081/api';

  static Future<Map<String, dynamic>> uploadUserDocuments({
    required int userId,
    Uint8List? documentFront,
    Uint8List? documentBack,
    Uint8List? clientPhoto,
  }) async {
    try {
      // Validar que al menos un documento se proporcione
      if (documentFront == null && documentBack == null && clientPhoto == null) {
        throw Exception('Debe proporcionar al menos un documento');
      }
      
      Map<String, dynamic> results = {};
      List<String> errors = [];
      
      if (clientPhoto != null) {
        try {
          final result = await _uploadBytes(clientPhoto, 'client_photo.jpg', '/user/upload', userId);
          results['clientPhoto'] = result;
        } catch (e) {
          errors.add('Foto del cliente: $e');
        }
      }
      
      if (documentFront != null) {
        try {
          final result = await _uploadBytes(documentFront, 'document_front.jpg', '/user/upload/documentFrom', userId);
          results['documentFront'] = result;
        } catch (e) {
          errors.add('Documento frontal: $e');
        }
      }
      
      if (documentBack != null) {
        try {
          final result = await _uploadBytes(documentBack, 'document_back.jpg', '/user/upload/documentBack', userId);
          results['documentBack'] = result;
        } catch (e) {
          errors.add('Documento trasero: $e');
        }
      }
      
      if (errors.isNotEmpty && results.isEmpty) {
        throw Exception('Todos los documentos fallaron: ${errors.join(', ')}');
      }
      
      return {
        'success': true,
        'message': errors.isEmpty ? 'Documentos subidos exitosamente' : 'Algunos documentos subidos con errores',
        'results': results,
        'errors': errors
      };
    } catch (e) {
      throw Exception('Error al subir documentos: $e');
    }
  }
  
  static Future<Map<String, dynamic>> _uploadBytes(Uint8List bytes, String filename, String endpoint, int userId) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      request.fields['id'] = userId.toString();
      
      // Determinar el tipo MIME basado en la extensión del archivo
      String contentType = 'image/jpeg'; // Por defecto
      if (filename.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      } else if (filename.toLowerCase().endsWith('.jpg') || filename.toLowerCase().endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      } else if (filename.toLowerCase().endsWith('.gif')) {
        contentType = 'image/gif';
      } else if (filename.toLowerCase().endsWith('.webp')) {
        contentType = 'image/webp';
      }
      
      request.files.add(http.MultipartFile.fromBytes(
        'archivo', 
        bytes, 
        filename: filename,
        contentType: MediaType.parse(contentType),
      ));
      
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 201) {
        return json.decode(responseBody);
      } else if (response.statusCode == 500) {
        throw Exception('Error interno del servidor. Verifique el formato del archivo.');
      } else {
        final errorData = json.decode(responseBody);
        throw Exception('Error ${response.statusCode}: ${errorData['message'] ?? 'Error desconocido'}');
      }
    } catch (e) {
      if (e.toString().contains('FormatException')) {
        throw Exception('Formato de archivo no válido');
      }
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        return {
          'documentFromStatus': userData['documentFromStatus'] ?? 'PENDING',
          'documentBackStatus': userData['documentBackStatus'] ?? 'PENDING', 
          'fotoStatus': userData['fotoStatus'] ?? 'PENDING',
          'foto': userData['foto'],
          'documentFrom': userData['documentFrom'],
          'documentBack': userData['documentBack'],
        };
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
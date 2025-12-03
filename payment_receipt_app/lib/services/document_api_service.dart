import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class DocumentApiService {
  static const String baseUrl = 'https://guardianstrustbank.com:8081/api';

  static Future<Map<String, dynamic>> uploadUserDocuments({
    required int userId,
    Uint8List? documentFront,
    Uint8List? documentBack,
    Uint8List? clientPhoto,
  }) async {
    try {
      Map<String, dynamic> results = {};
      
      // Subir foto de perfil si existe
      if (clientPhoto != null) {
        final photoFile = await _createTempFile(clientPhoto, 'client_photo.jpg');
        try {
          final result = await ApiService.uploadProfileImage(photoFile, userId);
          results['clientPhoto'] = result;
        } finally {
          await photoFile.delete();
        }
      }
      
      // Subir documento frontal si existe
      if (documentFront != null) {
        final frontFile = await _createTempFile(documentFront, 'document_front.jpg');
        try {
          final result = await ApiService.uploadDocumentFront(frontFile, userId);
          results['documentFront'] = result;
        } finally {
          await frontFile.delete();
        }
      }
      
      // Subir documento trasero si existe
      if (documentBack != null) {
        final backFile = await _createTempFile(documentBack, 'document_back.jpg');
        try {
          final result = await ApiService.uploadDocumentBack(backFile, userId);
          results['documentBack'] = result;
        } finally {
          await backFile.delete();
        }
      }
      
      return {
        'success': true,
        'message': 'Documentos subidos exitosamente',
        'results': results
      };
    } catch (e) {
      throw Exception('Error al subir documentos: $e');
    }
  }
  
  static Future<File> _createTempFile(Uint8List bytes, String filename) async {
    // Crear archivo temporal sin path_provider
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempFilename = 'temp_${timestamp}_$filename';
    final file = File(tempFilename);
    await file.writeAsBytes(bytes);
    return file;
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
      final response = await ApiService.getUserById(userId);
      
      if (response['status'] == 200) {
        final userData = response['data'];
        return {
          'documentFromStatus': userData['documentFromStatus'] ?? 'PENDING',
          'documentBackStatus': userData['documentBackStatus'] ?? 'PENDING', 
          'fotoStatus': userData['fotoStatus'] ?? 'PENDING',
          'foto': userData['foto'],
          'documentFrom': userData['documentFrom'],
          'documentBack': userData['documentBack'],
        };
      } else {
        throw Exception('Error al obtener documentos: ${response['status']}');
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
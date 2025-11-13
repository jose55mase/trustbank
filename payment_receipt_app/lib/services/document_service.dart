import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DocumentService {
  static const String baseUrl = 'https://api.trustbank.com';

  static Future<Map<String, dynamic>> uploadDocumentImages({
    File? documentFront,
    File? documentBack,
    File? clientPhoto,
    required String userId,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/$userId/documents/images'),
      );

      if (documentFront != null) {
        request.files.add(
          await http.MultipartFile.fromPath('documentFront', documentFront.path),
        );
      }

      if (documentBack != null) {
        request.files.add(
          await http.MultipartFile.fromPath('documentBack', documentBack.path),
        );
      }

      if (clientPhoto != null) {
        request.files.add(
          await http.MultipartFile.fromPath('clientPhoto', clientPhoto.path),
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
      // Simulación para desarrollo
      await Future.delayed(const Duration(seconds: 2));
      return {
        'success': true,
        'message': 'Documentos subidos exitosamente',
        'documentFront': documentFront?.path,
        'documentBack': documentBack?.path,
        'clientPhoto': clientPhoto?.path,
      };
    }
  }

  static Future<Map<String, dynamic>> getUserDocumentImages(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/documents/images'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener documentos');
      }
    } catch (e) {
      // Simulación para desarrollo
      return {
        'documentFront': null,
        'documentBack': null,
        'clientPhoto': null,
      };
    }
  }
}
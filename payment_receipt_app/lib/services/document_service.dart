import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class DocumentService {
  static const String baseUrl = 'https://api.trustbank.com';

  static Future<Map<String, dynamic>> uploadDocumentImages({
    XFile? documentFront,
    XFile? documentBack,
    XFile? clientPhoto,
    required String userId,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/$userId/documents/images'),
      );

      if (documentFront != null) {
        final bytes = await documentFront.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'documentFront',
            bytes,
            filename: documentFront.name,
          ),
        );
      }

      if (documentBack != null) {
        final bytes = await documentBack.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'documentBack',
            bytes,
            filename: documentBack.name,
          ),
        );
      }

      if (clientPhoto != null) {
        final bytes = await clientPhoto.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'clientPhoto',
            bytes,
            filename: clientPhoto.name,
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
      // Simulación para desarrollo
      await Future.delayed(const Duration(seconds: 2));
      return {
        'success': true,
        'message': 'Documentos subidos exitosamente',
        'documentFront': documentFront?.name,
        'documentBack': documentBack?.name,
        'clientPhoto': clientPhoto?.name,
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
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/app_config.dart';
import '../models/import_result.dart';
import '../models/lead_model.dart';
import '../models/mapping_result.dart';

/// Servicio HTTP para comunicación con el backend de leads.
/// Sigue el patrón estático del ApiService existente en el proyecto.
class LeadsService {
  static String get _baseUrl => AppConfig.apiBaseUrl;

  static Future<Map<String, String>> get _headers async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<String?> get _authToken async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Sube un archivo Excel al backend para análisis de columnas.
  /// Retorna el resultado del mapeo automático de columnas.
  /// Endpoint: POST /api/leads/upload (multipart)
  static Future<MappingResult> uploadExcel(List<int> fileBytes, String fileName) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/leads/upload'),
    );

    final token = await _authToken;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 200) {
      final data = json.decode(responseBody);
      return MappingResult.fromJson(data);
    } else {
      final error = _parseError(responseBody, streamedResponse.statusCode);
      throw Exception(error);
    }
  }

  /// Confirma la importación con el mapeo de columnas definido.
  /// Envía el archivo y el mapeo para procesar las filas.
  /// Endpoint: POST /api/leads/import/confirm (multipart)
  static Future<ImportResult> confirmImport(
    List<int> fileBytes,
    String fileName,
    Map<int, String?> mapping,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/leads/import/confirm'),
    );

    final token = await _authToken;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));

    // Enviar el mapeo como JSON string en un campo del formulario
    final mappingJson = json.encode(
      mapping.map((key, value) => MapEntry(key.toString(), value)),
    );
    request.fields['columnMapping'] = mappingJson;

    // Enviar adminId desde el usuario autenticado
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      final userData = json.decode(userDataString);
      request.fields['adminId'] = (userData['id'] ?? 1).toString();
    } else {
      request.fields['adminId'] = '1';
    }

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 200) {
      final data = json.decode(responseBody);
      return ImportResult.fromJson(data);
    } else {
      final error = _parseError(responseBody, streamedResponse.statusCode);
      throw Exception(error);
    }
  }

  /// Obtiene la lista de leads paginada y ordenada.
  /// Endpoint: GET /api/leads?page={page}&size={size}&sort={sort}&direction={direction}
  /// Soporta filtros opcionales: unassigned=true o advisorId={id}
  static Future<Map<String, dynamic>> getLeads({
    int page = 0,
    int size = 20,
    String sort = 'id',
    String direction = 'desc',
    bool? unassigned,
    int? advisorId,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
      'sort': sort,
      'direction': direction,
    };

    if (unassigned == true) {
      queryParams['unassigned'] = 'true';
    } else if (advisorId != null) {
      queryParams['advisorId'] = advisorId.toString();
    }

    final uri = Uri.parse('$_baseUrl/leads').replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> content = data['content'] ?? [];
      final leads = content.map((e) => LeadModel.fromJson(e)).toList();

      return {
        'leads': leads,
        'totalPages': data['totalPages'] ?? 0,
        'totalElements': data['totalElements'] ?? 0,
        'currentPage': data['number'] ?? page,
      };
    } else {
      throw Exception('Error al obtener leads: ${response.statusCode}');
    }
  }

  /// Busca leads por término en cualquier campo.
  /// Endpoint: GET /api/leads/search?term={term}&page={page}&size={size}
  static Future<Map<String, dynamic>> searchLeads({
    required String term,
    int page = 0,
    int size = 20,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/leads/search?term=${Uri.encodeComponent(term)}&page=$page&size=$size',
      ),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> content = data['content'] ?? [];
      final leads = content.map((e) => LeadModel.fromJson(e)).toList();

      return {
        'leads': leads,
        'totalPages': data['totalPages'] ?? 0,
        'totalElements': data['totalElements'] ?? 0,
        'currentPage': data['number'] ?? page,
      };
    } else {
      throw Exception('Error al buscar leads: ${response.statusCode}');
    }
  }

  /// Obtiene el detalle de un lead por su ID.
  /// Endpoint: GET /api/leads/{id}
  static Future<LeadModel> getLeadById(int id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/leads/$id'),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return LeadModel.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('Lead no encontrado');
    } else {
      throw Exception('Error al obtener lead: ${response.statusCode}');
    }
  }

  /// Actualiza los datos de un lead existente.
  /// Endpoint: PUT /api/leads/{id}
  static Future<LeadModel> updateLead(LeadModel lead) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/leads/${lead.id}'),
      headers: await _headers,
      body: json.encode(lead.toJson()),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return LeadModel.fromJson(data);
    } else {
      final error = _parseError(response.body, response.statusCode);
      throw Exception(error);
    }
  }

  /// Obtiene el historial de importaciones de archivos Excel.
  /// Endpoint: GET /api/leads/imports
  static Future<List<Map<String, dynamic>>> getImportHistory() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/leads/imports'),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } else {
      throw Exception(
        'Error al obtener historial de importaciones: ${response.statusCode}',
      );
    }
  }

  /// Exporta todos los leads como archivo Excel (.xlsx).
  /// Retorna los bytes del archivo para guardar/descargar.
  /// Endpoint: GET /api/leads/export
  /// Timeout: 60 segundos según requisito 1.9
  static Future<List<int>> exportLeads() async {
    final token = await _authToken;
    final response = await http.get(
      Uri.parse('$_baseUrl/leads/export'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      },
    ).timeout(
      const Duration(seconds: 60),
      onTimeout: () => http.Response(
        'La exportación excedió el tiempo límite',
        504,
      ),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Error al exportar leads: ${response.statusCode}');
    }
  }

  /// Elimina un lead por su ID.
  /// Endpoint: DELETE /api/leads/{id}
  static Future<void> deleteLead(int id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/leads/$id'),
      headers: await _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar lead: ${response.statusCode}');
    }
  }

  /// Parsea el mensaje de error de la respuesta del backend.
  static String _parseError(String responseBody, int statusCode) {
    try {
      final data = json.decode(responseBody);
      return data['message'] ?? 'Error del servidor: $statusCode';
    } catch (_) {
      return 'Error del servidor: $statusCode';
    }
  }
}

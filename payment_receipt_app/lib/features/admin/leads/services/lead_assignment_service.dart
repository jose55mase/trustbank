import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/app_config.dart';
import '../models/advisor_summary.dart';
import '../models/assignment_result.dart';
import '../models/lead_model.dart';

/// Servicio HTTP para operaciones de asignación de leads a asesores.
/// Sigue el patrón estático del LeadsService existente en el proyecto.
class LeadAssignmentService {
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

  /// Asigna uno o más leads a un asesor específico.
  /// Endpoint: POST /api/admin/leads/assign
  /// Retorna el resultado con la cantidad asignada y datos del asesor.
  static Future<AssignmentResult> assignLeads({
    required List<int> leadIds,
    required int advisorId,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/admin/leads/assign'),
      headers: await _headers,
      body: json.encode({
        'leadIds': leadIds,
        'advisorId': advisorId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 207) {
      final data = json.decode(response.body);
      return AssignmentResult.fromJson(data);
    } else {
      final error = _parseError(response.body, response.statusCode);
      throw Exception(error);
    }
  }

  /// Desasigna leads (establece advisor_id en nulo).
  /// Endpoint: POST /api/admin/leads/unassign
  /// Retorna la cantidad de leads desasignados.
  static Future<int> unassignLeads(List<int> leadIds) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/admin/leads/unassign'),
      headers: await _headers,
      body: json.encode({
        'leadIds': leadIds,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['unassignedCount'] ?? data['count'] ?? leadIds.length;
    } else {
      final error = _parseError(response.body, response.statusCode);
      throw Exception(error);
    }
  }

  /// Reasigna leads de un asesor a otro.
  /// Endpoint: POST /api/admin/leads/reassign
  /// Retorna el resultado con la cantidad reasignada y datos del nuevo asesor.
  static Future<AssignmentResult> reassignLeads({
    required int fromAdvisorId,
    required int toAdvisorId,
    required List<int> leadIds,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/admin/leads/reassign'),
      headers: await _headers,
      body: json.encode({
        'fromAdvisorId': fromAdvisorId,
        'toAdvisorId': toAdvisorId,
        'leadIds': leadIds,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 207) {
      final data = json.decode(response.body);
      return AssignmentResult.fromJson(data);
    } else {
      final error = _parseError(response.body, response.statusCode);
      throw Exception(error);
    }
  }

  /// Obtiene el resumen de asesores con la cantidad de leads asignados.
  /// Endpoint: GET /api/admin/advisors/summary
  /// Retorna la lista de asesores incluyendo aquellos con 0 leads.
  static Future<List<AdvisorSummary>> getAdvisorSummary() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/admin/advisors/summary'),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> list = data is List ? data : data['data'] ?? [];
      return list.map((e) => AdvisorSummary.fromJson(e)).toList();
    } else {
      final error = _parseError(response.body, response.statusCode);
      throw Exception(error);
    }
  }

  /// Obtiene los leads asignados a un asesor específico (paginado).
  /// Endpoint: GET /api/admin/advisors/{advisorId}/leads
  /// Retorna un mapa con los leads y metadatos de paginación.
  static Future<Map<String, dynamic>> getAdvisorLeads(
    int advisorId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/admin/advisors/$advisorId/leads?page=$page&size=$size'),
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
        'hasNext': !(data['last'] ?? true),
        'hasPrevious': !(data['first'] ?? true),
      };
    } else {
      final error = _parseError(response.body, response.statusCode);
      throw Exception(error);
    }
  }

  /// Parsea el mensaje de error de la respuesta del backend.
  static String _parseError(String responseBody, int statusCode) {
    try {
      final data = json.decode(responseBody);
      return data['message'] ?? data['error'] ?? 'Error del servidor: $statusCode';
    } catch (_) {
      return 'Error del servidor: $statusCode';
    }
  }
}

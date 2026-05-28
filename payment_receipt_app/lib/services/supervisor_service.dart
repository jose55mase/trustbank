import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../core/session/session_manager.dart';
import '../models/lead_model.dart';
import '../models/supervisor_assignment.dart';
import 'api_service.dart';

/// Service for supervisor-specific operations.
/// Handles lead retrieval (filtered by assignment), search, detail, and partial update.
/// Also retrieves the current supervisor's assignment info.
class SupervisorService {
  static String get _baseUrl => AppConfig.apiBaseUrl;

  /// GET /api/supervisor/leads?page=X&size=Y&status=X
  /// Returns paginated leads filtered by the supervisor's assignment type.
  static Future<Map<String, dynamic>> getLeads({
    int page = 0,
    int size = 20,
    String? status,
  }) async {
    try {
      String url = '$_baseUrl/supervisor/leads?page=$page&size=$size';
      if (status != null && status.isNotEmpty) {
        url += '&status=${Uri.encodeComponent(status)}';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: await ApiService.headers,
      );

      if (response.statusCode == 401) {
        SessionManager.handleSessionExpired();
        throw Exception('Sesión expirada');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['content'] as List? ?? [];
        final leads = content
            .map<LeadModel>((json) => LeadModel.fromJson(json))
            .toList();

        return {
          'leads': leads,
          'currentPage': data['number'] ?? page,
          'totalItems': data['totalElements'] ?? 0,
          'totalPages': data['totalPages'] ?? 0,
          'hasNext': !(data['last'] ?? true),
          'hasPrevious': !(data['first'] ?? true),
        };
      } else {
        throw Exception('Error obteniendo leads: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error obteniendo leads del supervisor: $e');
    }
  }

  /// GET /api/supervisor/leads/search?term=X&page=Y&size=Z
  /// Searches within the supervisor's assigned leads by term.
  static Future<Map<String, dynamic>> searchLeads({
    required String term,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final encodedTerm = Uri.encodeComponent(term);
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/supervisor/leads/search?term=$encodedTerm&page=$page&size=$size'),
        headers: await ApiService.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['content'] as List? ?? [];
        final leads = content
            .map<LeadModel>((json) => LeadModel.fromJson(json))
            .toList();

        return {
          'leads': leads,
          'currentPage': data['number'] ?? page,
          'totalItems': data['totalElements'] ?? 0,
          'totalPages': data['totalPages'] ?? 0,
          'hasNext': !(data['last'] ?? true),
          'hasPrevious': !(data['first'] ?? true),
        };
      } else {
        throw Exception('Error buscando leads: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error buscando leads del supervisor: $e');
    }
  }

  /// GET /api/supervisor/leads/{id}
  /// Returns a single lead by ID (verifies it belongs to the supervisor's assignment).
  static Future<LeadModel> getLeadById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/supervisor/leads/$id'),
        headers: await ApiService.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return LeadModel.fromJson(data);
      } else if (response.statusCode == 403) {
        throw Exception('No tienes acceso a este lead');
      } else if (response.statusCode == 404) {
        throw Exception('Lead no encontrado');
      } else {
        throw Exception('Error obteniendo lead: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error obteniendo detalle del lead: $e');
    }
  }

  /// PUT /api/supervisor/leads/{id}
  /// Partial update of a lead. Only sends the provided fields.
  static Future<LeadModel> updateLead(
      int id, Map<String, dynamic> fields) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/supervisor/leads/$id'),
        headers: await ApiService.headers,
        body: json.encode(fields),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return LeadModel.fromJson(data);
      } else if (response.statusCode == 403) {
        throw Exception('No tienes acceso a este lead');
      } else if (response.statusCode == 404) {
        throw Exception('Lead no encontrado');
      } else {
        throw Exception('Error actualizando lead: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error actualizando lead: $e');
    }
  }

  /// GET /api/supervisor-assignments/me
  /// Returns the current supervisor's assignment (type info).
  static Future<SupervisorAssignment> getMyAssignment() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/supervisor-assignments/me'),
        headers: await ApiService.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SupervisorAssignment.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception(
            'No tienes un tipo de asignación configurado');
      } else {
        throw Exception(
            'Error obteniendo asignación: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error obteniendo asignación del supervisor: $e');
    }
  }
}

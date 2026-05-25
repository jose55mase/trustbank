import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/supervisor_assignment.dart';

/// Servicio para gestionar asignaciones de supervisores (admin).
/// Endpoints: /api/supervisor-assignments
class SupervisorAssignmentsService {
  static String get _baseUrl => AppConfig.apiBaseUrl;

  static Future<Map<String, String>> get _headers async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }

  /// GET /api/supervisor-assignments
  /// Obtiene todas las asignaciones de supervisores.
  static Future<List<SupervisorAssignment>> getAll() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/supervisor-assignments'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> list = data is List ? data : data['data'] ?? [];
        return list
            .map((json) => SupervisorAssignment.fromJson(json))
            .toList();
      } else {
        throw Exception('Error obteniendo asignaciones: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error obteniendo asignaciones de supervisores: $e');
    }
  }

  /// POST /api/supervisor-assignments
  /// Crea una nueva asignación de supervisor.
  static Future<SupervisorAssignment> create({
    required int userId,
    required int assignmentTypeId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/supervisor-assignments'),
        headers: await _headers,
        body: json.encode({
          'userId': userId,
          'assignmentTypeId': assignmentTypeId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SupervisorAssignment.fromJson(json.decode(response.body));
      } else if (response.statusCode == 409) {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'El usuario ya tiene una asignación');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Error creando asignación: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creando asignación de supervisor: $e');
    }
  }

  /// PUT /api/supervisor-assignments/{userId}
  /// Actualiza el tipo de asignación de un supervisor.
  static Future<SupervisorAssignment> update(
      int userId, int assignmentTypeId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/supervisor-assignments/$userId'),
        headers: await _headers,
        body: json.encode({
          'assignmentTypeId': assignmentTypeId,
        }),
      );

      if (response.statusCode == 200) {
        return SupervisorAssignment.fromJson(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Error actualizando asignación: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error actualizando asignación de supervisor: $e');
    }
  }

  /// DELETE /api/supervisor-assignments/{userId}
  /// Elimina la asignación de un supervisor.
  static Future<void> delete(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/supervisor-assignments/$userId'),
        headers: await _headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Error eliminando asignación: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error eliminando asignación de supervisor: $e');
    }
  }
}

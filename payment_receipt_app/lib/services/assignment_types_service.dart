import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/assignment_type.dart';
import 'api_service.dart';

/// Request DTO para crear/actualizar tipos de asignación.
class AssignmentTypeRequest {
  final String name;
  final String? description;
  final bool? active;
  final String? filterValue;

  const AssignmentTypeRequest({
    required this.name,
    this.description,
    this.active,
    this.filterValue,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
    };
    if (description != null) map['description'] = description;
    if (active != null) map['active'] = active;
    if (filterValue != null) map['filterValue'] = filterValue;
    return map;
  }
}

/// Servicio para gestionar tipos de asignación (CRUD).
/// Usado por el administrador para crear, listar, actualizar y eliminar
/// tipos de asignación de supervisores.
class AssignmentTypesService {
  static String get _baseUrl => AppConfig.apiBaseUrl;

  /// GET /api/assignment-types — Listar todos los tipos de asignación.
  static Future<List<AssignmentType>> getAll() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/assignment-types'),
        headers: await ApiService.headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map<AssignmentType>((json) => AssignmentType.fromJson(json))
            .toList();
      } else {
        throw Exception('Error obteniendo tipos de asignación');
      }
    } catch (e) {
      throw Exception('Error obteniendo tipos de asignación: $e');
    }
  }

  /// GET /api/assignment-types/active — Listar solo tipos activos.
  static Future<List<AssignmentType>> getActive() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/assignment-types/active'),
        headers: await ApiService.headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map<AssignmentType>((json) => AssignmentType.fromJson(json))
            .toList();
      } else {
        throw Exception('Error obteniendo tipos de asignación activos');
      }
    } catch (e) {
      throw Exception('Error obteniendo tipos de asignación activos: $e');
    }
  }

  /// POST /api/assignment-types — Crear nuevo tipo de asignación.
  static Future<AssignmentType> create(AssignmentTypeRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/assignment-types'),
        headers: await ApiService.headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return AssignmentType.fromJson(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Error creando tipo de asignación');
      }
    } catch (e) {
      throw Exception('Error creando tipo de asignación: $e');
    }
  }

  /// PUT /api/assignment-types/{id} — Actualizar tipo existente.
  static Future<AssignmentType> update(
      int id, AssignmentTypeRequest request) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/assignment-types/$id'),
        headers: await ApiService.headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return AssignmentType.fromJson(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Error actualizando tipo de asignación');
      }
    } catch (e) {
      throw Exception('Error actualizando tipo de asignación: $e');
    }
  }

  /// DELETE /api/assignment-types/{id} — Eliminar tipo de asignación.
  static Future<void> delete(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/assignment-types/$id'),
        headers: await ApiService.headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Error eliminando tipo de asignación');
      }
    } catch (e) {
      throw Exception('Error eliminando tipo de asignación: $e');
    }
  }
}

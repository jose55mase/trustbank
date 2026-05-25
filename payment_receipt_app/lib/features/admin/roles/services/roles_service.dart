import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/app_config.dart';
import '../../../../models/module_permission.dart';
import '../../../../models/role_model.dart';

/// Servicio HTTP para comunicación con el backend de roles.
/// Sigue el patrón estático del LeadsService existente en el proyecto.
class RolesService {
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

  /// Obtiene la lista de todos los roles con conteo de usuarios.
  /// Endpoint: GET /api/roles
  static Future<List<RoleModel>> getRoles() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/roles'),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return data
            .map((e) => RoleModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } else {
      final error = _parseError(response.body, response.statusCode);
      throw Exception(error);
    }
  }

  /// Obtiene un rol por su ID con sus módulos asignados.
  /// Endpoint: GET /api/roles/{id}
  static Future<RoleModel> getRoleById(int id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/roles/$id'),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return RoleModel.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('Rol no encontrado');
    } else {
      final error = _parseError(response.body, response.statusCode);
      throw Exception(error);
    }
  }

  /// Crea un nuevo rol con el nombre proporcionado.
  /// Endpoint: POST /api/roles
  static Future<RoleModel> createRole(String name) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/roles'),
      headers: await _headers,
      body: json.encode({'name': name}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      return RoleModel.fromJson(data);
    } else {
      final error = _parseError(response.body, response.statusCode);
      throw Exception(error);
    }
  }

  /// Actualiza el nombre de un rol existente.
  /// Endpoint: PUT /api/roles/{id}
  static Future<RoleModel> updateRole(int id, String name) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/roles/$id'),
      headers: await _headers,
      body: json.encode({'name': name}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return RoleModel.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('Rol no encontrado');
    } else {
      final error = _parseError(response.body, response.statusCode);
      throw Exception(error);
    }
  }

  /// Elimina un rol por su ID.
  /// Falla si el rol tiene usuarios asignados (409 Conflict).
  /// Endpoint: DELETE /api/roles/{id}
  static Future<void> deleteRole(int id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/roles/$id'),
      headers: await _headers,
    );

    if (response.statusCode == 204 || response.statusCode == 200) {
      return;
    } else if (response.statusCode == 404) {
      throw Exception('Rol no encontrado');
    } else if (response.statusCode == 409) {
      final error = _parseError(response.body, response.statusCode);
      throw Exception(error);
    } else {
      final error = _parseError(response.body, response.statusCode);
      throw Exception(error);
    }
  }

  /// Asigna módulos a un rol (operación batch).
  /// Reemplaza todos los módulos del rol con los IDs proporcionados.
  /// Endpoint: PUT /api/roles/{id}/modules
  static Future<RoleModel> updateRoleModules(
    int roleId,
    List<int> moduleIds,
  ) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/roles/$roleId/modules'),
      headers: await _headers,
      body: json.encode({'moduleIds': moduleIds}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return RoleModel.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('Rol no encontrado');
    } else {
      final error = _parseError(response.body, response.statusCode);
      throw Exception(error);
    }
  }

  /// Obtiene el catálogo completo de módulos disponibles.
  /// Endpoint: GET /api/modules
  static Future<List<ModulePermission>> getModules() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/modules'),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return data
            .map((e) => ModulePermission.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } else {
      final error = _parseError(response.body, response.statusCode);
      throw Exception(error);
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

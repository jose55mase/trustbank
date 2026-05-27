import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/user_permissions.dart';

/// Servicio HTTP para gestionar permisos granulares de módulos.
/// Provee métodos para obtener y actualizar permisos de acciones
/// y visibilidad de campañas por rol.
class PermissionsApiService {
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

  /// Obtiene los permisos del usuario autenticado para un módulo.
  /// Endpoint: GET /api/users/me/permissions?module={moduleCode}
  ///
  /// Retorna un [UserPermissions] con las acciones permitidas y
  /// los IDs de campañas visibles.
  static Future<UserPermissions> fetchUserPermissions(String moduleCode) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/me/permissions?module=$moduleCode'),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return UserPermissions.fromJson(data);
    } else {
      final error = _parseError(response.body, response.statusCode);
      throw Exception(error);
    }
  }

  /// Obtiene los permisos de acciones de un rol específico (admin).
  /// Endpoint: GET /api/roles/{roleId}/permissions?module={moduleCode}
  ///
  /// Retorna una lista de mapas con actionCode y enabled.
  static Future<List<Map<String, dynamic>>> fetchRolePermissions(
    int roleId,
    String moduleCode,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/roles/$roleId/permissions?module=$moduleCode'),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else if (response.statusCode == 404) {
      throw Exception('Rol no encontrado');
    } else {
      final error = _parseError(response.body, response.statusCode);
      throw Exception(error);
    }
  }

  /// Actualiza el estado de un permiso de acción para un rol (admin).
  /// Endpoint: PUT /api/roles/{roleId}/permissions
  ///
  /// Body: {"moduleCode": "LEADS", "actionCode": "...", "enabled": true/false}
  static Future<void> updateActionPermission(
    int roleId,
    String moduleCode,
    String actionCode,
    bool enabled,
  ) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/roles/$roleId/permissions'),
      headers: await _headers,
      body: json.encode({
        'moduleCode': moduleCode,
        'actionCode': actionCode,
        'enabled': enabled,
      }),
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 404) {
      throw Exception('Rol o permiso no encontrado');
    } else if (response.statusCode == 400) {
      final error = _parseError(response.body, response.statusCode);
      throw Exception(error);
    } else {
      final error = _parseError(response.body, response.statusCode);
      throw Exception(error);
    }
  }

  /// Obtiene la visibilidad de campañas de un rol (admin).
  /// Endpoint: GET /api/roles/{roleId}/campaign-visibility
  ///
  /// Retorna un mapa con roleId y la lista de campaignIds.
  static Future<List<int>> fetchRoleCampaignVisibility(int roleId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/roles/$roleId/campaign-visibility'),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> campaignIds = data['campaignIds'] ?? [];
      return campaignIds.map((id) => id as int).toList();
    } else if (response.statusCode == 404) {
      throw Exception('Rol no encontrado');
    } else {
      final error = _parseError(response.body, response.statusCode);
      throw Exception(error);
    }
  }

  /// Actualiza la visibilidad de campañas de un rol (admin).
  /// Endpoint: PUT /api/roles/{roleId}/campaign-visibility
  ///
  /// Body: {"campaignIds": [1, 3, 5]}
  static Future<void> updateCampaignVisibility(
    int roleId,
    List<int> campaignIds,
  ) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/roles/$roleId/campaign-visibility'),
      headers: await _headers,
      body: json.encode({
        'campaignIds': campaignIds,
      }),
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 404) {
      final error = _parseError(response.body, response.statusCode);
      throw Exception(error);
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

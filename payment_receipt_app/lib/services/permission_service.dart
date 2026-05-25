import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/module_permission.dart';

/// Servicio singleton que gestiona los permisos de módulos del usuario autenticado.
/// Reemplaza el sistema estático de permisos (RolePermissions) por uno dinámico
/// que obtiene los módulos permitidos desde el backend.
class PermissionService {
  static final PermissionService _instance = PermissionService._();
  factory PermissionService() => _instance;
  PermissionService._();

  List<ModulePermission> _allowedModules = [];

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

  /// Carga los módulos permitidos del usuario autenticado desde el backend.
  /// Llama a GET /api/users/me/modules y almacena el resultado.
  Future<void> loadPermissions() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/me/modules'),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      _allowedModules = data.map((m) => ModulePermission.fromJson(m)).toList();
    } else {
      _allowedModules = [];
      throw Exception('Error al cargar permisos: ${response.statusCode}');
    }
  }

  /// Verifica si el usuario tiene acceso a un módulo específico.
  /// [moduleCode] es el código del módulo (e.g., "LEADS", "DOCUMENTS").
  bool hasModuleAccess(String moduleCode) {
    return _allowedModules.any((m) => m.code == moduleCode);
  }

  /// Retorna la lista de módulos permitidos para el usuario actual.
  List<ModulePermission> get allowedModules => List.unmodifiable(_allowedModules);

  /// Limpia los permisos almacenados. Debe llamarse al cerrar sesión.
  void clear() {
    _allowedModules = [];
  }
}

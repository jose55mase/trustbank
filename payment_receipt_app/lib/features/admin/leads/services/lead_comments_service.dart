import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/app_config.dart';
import '../../../../core/session/session_manager.dart';
import '../models/lead_comment_model.dart';
import 'comment_api_exception.dart';

/// Servicio HTTP para comunicación con el backend de comentarios de leads.
/// Sigue el patrón estático del LeadsService existente.
class LeadCommentsService {
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

  /// Obtiene todos los comentarios de un lead (legacy + authored).
  /// Endpoint: GET /api/leads/{leadId}/comments
  /// Retorna una lista combinada de comentarios legacy y authored.
  static Future<List<LeadCommentModel>> getComments(int leadId) async {
    final http.Response response;
    try {
      response = await http.get(
        Uri.parse('$_baseUrl/leads/$leadId/comments'),
        headers: await _headers,
      );
    } on SocketException {
      throw const CommentApiException(
        type: CommentErrorType.network,
        message: 'Error de conexión. Verifica tu red e intenta de nuevo.',
      );
    } on http.ClientException {
      throw const CommentApiException(
        type: CommentErrorType.network,
        message: 'Error de conexión. Verifica tu red e intenta de nuevo.',
      );
    }

    if (response.statusCode == 401) {
      SessionManager.handleSessionExpired();
      throw const CommentApiException(
        type: CommentErrorType.unauthorized,
        message: 'Sesión expirada',
      );
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<LeadCommentModel> comments = [];

      // Parse legacy comment if present
      if (data['legacyComment'] != null) {
        final legacy = data['legacyComment'];
        if (legacy['text'] != null &&
            (legacy['text'] as String).isNotEmpty) {
          comments.add(LeadCommentModel(
            leadId: leadId,
            text: legacy['text'] as String,
            createdAt: DateTime(1970), // Legacy has no timestamp
            isLegacy: true,
          ));
        }
      }

      // Parse authored comments
      final List<dynamic> authored = data['comments'] ?? [];
      comments.addAll(
        authored.map((e) => LeadCommentModel.fromJson(e)).toList(),
      );

      return comments;
    } else {
      throw _mapStatusToException(response.body, response.statusCode);
    }
  }

  /// Crea un nuevo comentario en un lead.
  /// Endpoint: POST /api/leads/{leadId}/comments
  /// Retorna el comentario creado.
  static Future<LeadCommentModel> createComment(
      int leadId, String text) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$_baseUrl/leads/$leadId/comments'),
        headers: await _headers,
        body: json.encode({'text': text}),
      );
    } on SocketException {
      throw const CommentApiException(
        type: CommentErrorType.network,
        message: 'Error de conexión. Verifica tu red e intenta de nuevo.',
      );
    } on http.ClientException {
      throw const CommentApiException(
        type: CommentErrorType.network,
        message: 'Error de conexión. Verifica tu red e intenta de nuevo.',
      );
    }

    if (response.statusCode == 401) {
      SessionManager.handleSessionExpired();
      throw const CommentApiException(
        type: CommentErrorType.unauthorized,
        message: 'Sesión expirada',
      );
    }

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return LeadCommentModel.fromJson(data);
    } else {
      throw _mapStatusToException(response.body, response.statusCode);
    }
  }

  /// Actualiza un comentario existente (solo el autor puede editar).
  /// Endpoint: PUT /api/leads/{leadId}/comments/{commentId}
  /// Retorna el comentario actualizado.
  static Future<LeadCommentModel> updateComment(
      int leadId, int commentId, String text) async {
    final http.Response response;
    try {
      response = await http.put(
        Uri.parse('$_baseUrl/leads/$leadId/comments/$commentId'),
        headers: await _headers,
        body: json.encode({'text': text}),
      );
    } on SocketException {
      throw const CommentApiException(
        type: CommentErrorType.network,
        message: 'Error de conexión. Verifica tu red e intenta de nuevo.',
      );
    } on http.ClientException {
      throw const CommentApiException(
        type: CommentErrorType.network,
        message: 'Error de conexión. Verifica tu red e intenta de nuevo.',
      );
    }

    if (response.statusCode == 401) {
      SessionManager.handleSessionExpired();
      throw const CommentApiException(
        type: CommentErrorType.unauthorized,
        message: 'Sesión expirada',
      );
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return LeadCommentModel.fromJson(data);
    } else {
      throw _mapStatusToException(response.body, response.statusCode);
    }
  }

  /// Elimina un comentario (solo el autor puede eliminar).
  /// Endpoint: DELETE /api/leads/{leadId}/comments/{commentId}
  static Future<void> deleteComment(int leadId, int commentId) async {
    final http.Response response;
    try {
      response = await http.delete(
        Uri.parse('$_baseUrl/leads/$leadId/comments/$commentId'),
        headers: await _headers,
      );
    } on SocketException {
      throw const CommentApiException(
        type: CommentErrorType.network,
        message: 'Error de conexión. Verifica tu red e intenta de nuevo.',
      );
    } on http.ClientException {
      throw const CommentApiException(
        type: CommentErrorType.network,
        message: 'Error de conexión. Verifica tu red e intenta de nuevo.',
      );
    }

    if (response.statusCode == 401) {
      SessionManager.handleSessionExpired();
      throw const CommentApiException(
        type: CommentErrorType.unauthorized,
        message: 'Sesión expirada',
      );
    }

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw _mapStatusToException(response.body, response.statusCode);
    }
  }

  /// Mapea un código de estado HTTP a una [CommentApiException] tipada.
  static CommentApiException _mapStatusToException(
      String responseBody, int statusCode) {
    final message = _parseErrorMessage(responseBody, statusCode);

    switch (statusCode) {
      case 400:
        return CommentApiException(
          type: CommentErrorType.validation,
          message: message,
        );
      case 403:
        return CommentApiException(
          type: CommentErrorType.forbidden,
          message: message,
        );
      case 404:
        return CommentApiException(
          type: CommentErrorType.notFound,
          message: message,
        );
      default:
        return CommentApiException(
          type: CommentErrorType.unknown,
          message: message,
        );
    }
  }

  /// Parsea el mensaje de error de la respuesta del backend.
  static String _parseErrorMessage(String responseBody, int statusCode) {
    try {
      final data = json.decode(responseBody);
      return data['message'] ?? data['error'] ?? 'Error del servidor: $statusCode';
    } catch (_) {
      return 'Error del servidor: $statusCode';
    }
  }
}

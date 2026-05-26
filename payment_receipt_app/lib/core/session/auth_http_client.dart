import 'package:http/http.dart' as http;
import 'session_manager.dart';

/// HTTP client wrapper that intercepts 401 responses and triggers session expiry.
/// Use this instead of `http.get/post/put/delete` directly.
class AuthHttpClient {
  AuthHttpClient._();

  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final response = await http.get(url, headers: headers);
    _checkUnauthorized(response);
    return response;
  }

  static Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body}) async {
    final response = await http.post(url, headers: headers, body: body);
    _checkUnauthorized(response);
    return response;
  }

  static Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body}) async {
    final response = await http.put(url, headers: headers, body: body);
    _checkUnauthorized(response);
    return response;
  }

  static Future<http.Response> delete(Uri url, {Map<String, String>? headers}) async {
    final response = await http.delete(url, headers: headers);
    _checkUnauthorized(response);
    return response;
  }

  static void _checkUnauthorized(http.Response response) {
    if (response.statusCode == 401) {
      SessionManager.handleSessionExpired();
    }
  }
}

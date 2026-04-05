import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_service.dart';

/// Key used to store the OAuth token in secure storage.
const _kTokenKey = 'nitrado_oauth_token';

/// Implementation of [AuthService] backed by [FlutterSecureStorage].
///
/// Tokens are stored in the platform's secure keychain/keystore.
/// All API communication using the token must use HTTPS (Req 1.5).
class AuthServiceImpl implements AuthService {
  final FlutterSecureStorage _storage;

  AuthServiceImpl({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> saveToken(String token) async {
    await _storage.write(key: _kTokenKey, value: token);
  }

  @override
  Future<String?> getToken() async {
    return _storage.read(key: _kTokenKey);
  }

  @override
  Future<bool> validateToken(String token) async {
    // Placeholder: once NitradoApiClient is available, this will make a
    // test call to https://api.nitrado.net to verify the token.
    // For now, a non-empty token is considered valid.
    return token.isNotEmpty;
  }

  @override
  Future<void> deleteToken() async {
    await _storage.delete(key: _kTokenKey);
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

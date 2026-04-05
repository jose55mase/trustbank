/// Abstract interface for authentication and secure token management.
///
/// Handles OAuth token storage, retrieval, validation, and deletion.
/// All token transmission must occur over HTTPS only (Req 1.5).
abstract class AuthService {
  /// Stores the OAuth token securely on the device.
  Future<void> saveToken(String token);

  /// Retrieves the stored OAuth token, or null if none exists.
  Future<String?> getToken();

  /// Validates the token against the Nitrado API.
  ///
  /// Currently checks that the token is non-empty.
  /// Will be wired to a real API call once NitradoApiClient is built.
  Future<bool> validateToken(String token);

  /// Deletes the stored OAuth token (logout).
  Future<void> deleteToken();

  /// Returns true if a valid (non-empty) token is stored.
  Future<bool> isAuthenticated();
}

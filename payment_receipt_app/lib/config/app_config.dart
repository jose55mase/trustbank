/// Configuración de la aplicación con soporte para múltiples ambientes.
/// El ambiente se define con --dart-define=ENV=dev|prod al ejecutar.
class AppConfig {
  static const String _env = String.fromEnvironment('ENV', defaultValue: 'dev');

  // API Configuration
  static String get apiBaseUrl => _env == 'prod'
      ? 'https://guardianstrustbank.com:8081/api'
      : 'http://localhost:9090/api';

  static String get oauthTokenUrl => _env == 'prod'
      ? 'https://guardianstrustbank.com:8081/oauth/token'
      : 'http://localhost:9090/oauth/token';

  // OAuth2 Client Credentials
  static const String oauthClientId = 'angularapp';
  static const String oauthClientSecret = '12345';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Helper
  static bool get isProduction => _env == 'prod';
  static bool get isDevelopment => _env == 'dev';
  static String get currentEnvironment => _env;
}

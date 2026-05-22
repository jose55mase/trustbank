/// Configuración de la aplicación.
/// En producción, estos valores deberían cargarse desde variables de entorno
/// o un archivo de configuración seguro.
class AppConfig {
  // API Configuration
  static const String apiBaseUrl = 'https://guardianstrustbank.com:8081/api';
  static const String oauthTokenUrl = 'https://guardianstrustbank.com:8081/oauth/token';

  // OAuth2 Client Credentials
  // NOTA: En producción, estas credenciales no deben estar hardcodeadas.
  // Considerar usar flutter_dotenv o --dart-define para inyectarlas en build time.
  static const String oauthClientId = 'angularapp';
  static const String oauthClientSecret = '12345';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

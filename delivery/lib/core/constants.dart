/// Constantes globales de la aplicación Delivery App (Domicilios)
class AppConstants {
  AppConstants._();

  // Nombre de la app
  static const String appName = 'Domicilios';
  static const String appVersion = '1.0.0';

  // Longitud del código de confirmación
  static const int codigoConfirmacionLength = 6;

  // Intervalo de actualización de geolocalización (en segundos)
  static const int geoUpdateIntervalSeconds = 10;

  // Máximo de pedidos activos por usuario
  static const int maxPedidosActivosPorUsuario = 1;

  // Datos mock por defecto
  static const int mockUsuariosCount = 5;
  static const int mockRepartidoresCount = 3;
  static const int mockAdministradoresCount = 1;
  static const int mockHistorialCount = 10;
}

import 'package:nitrado_server_manager/shared/models/models.dart';

/// Abstract interface for all Nitrado API operations.
///
/// Implementations handle HTTP communication, authentication,
/// error handling, and response parsing.
abstract class NitradoApiClient {
  /// Obtiene la lista de servidores DayZ de la cuenta.
  Future<List<GameServer>> getServers();

  /// Obtiene el estado detallado de un servidor.
  Future<GameServer> getServerStatus(int serverId);

  /// Ejecuta una acción de control (start, stop, restart).
  Future<void> serverAction(int serverId, ServerAction action);

  /// Obtiene la lista de jugadores conectados.
  Future<List<Player>> getPlayers(int serverId);

  /// Expulsa a un jugador.
  Future<void> kickPlayer(int serverId, String playerId);

  /// Banea a un jugador.
  Future<void> banPlayer(int serverId, String playerId, {String? reason});

  /// Obtiene la lista de jugadores baneados.
  Future<List<BannedPlayer>> getBanList(int serverId);

  /// Desbanea a un jugador.
  Future<void> unbanPlayer(int serverId, String playerId);

  /// Lista archivos del servidor.
  Future<List<FileEntry>> listFiles(int serverId, String path);

  /// Descarga el contenido de un archivo.
  Future<String> downloadFile(int serverId, String filePath);

  /// Sube un archivo al servidor.
  Future<void> uploadFile(int serverId, String filePath, String content);

  /// Obtiene los logs del servidor.
  Future<String> getServerLogs(int serverId);
}

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:nitrado_server_manager/core/api/api_exceptions.dart';
import 'package:nitrado_server_manager/core/api/nitrado_api_client.dart';
import 'package:nitrado_server_manager/shared/models/models.dart';

/// Dio-based implementation of [NitradoApiClient].
///
/// Handles HTTP communication with the Nitrado API at
/// `https://api.nitrado.net`. Auth and retry interceptors are
/// configured externally and injected via the [Dio] instance.
class NitradoApiClientImpl implements NitradoApiClient {
  final Dio dio;

  NitradoApiClientImpl(this.dio);

  // ── Helpers ──────────────────────────────────────────────────────

  /// Wraps a Dio call with standard error handling.
  ///
  /// - 401/403 → [UnauthorizedException]
  /// - 4xx     → [ApiException] with the API's error message
  /// - 5xx     → [ApiException] with a generic server error message
  @visibleForTesting
  Future<Response<T>> request<T>(Future<Response<T>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;

      if (statusCode == 401 || statusCode == 403) {
        final msg = extractMessage(e.response) ?? 'Token inválido o expirado';
        throw UnauthorizedException(msg);
      }

      if (statusCode != null && statusCode >= 400 && statusCode < 500) {
        final msg =
            extractMessage(e.response) ?? 'Error en la solicitud ($statusCode)';
        throw ApiException(msg, statusCode: statusCode);
      }

      if (statusCode != null && statusCode >= 500) {
        throw ApiException(
          'Error del servidor. Inténtalo de nuevo más tarde.',
          statusCode: statusCode,
        );
      }

      // Network / timeout errors
      throw ApiException('Error de conexión: ${e.message}');
    }
  }

  /// Tries to extract a human-readable message from the API response body.
  @visibleForTesting
  String? extractMessage(Response<dynamic>? response) {
    final data = response?.data;
    if (data is Map<String, dynamic>) {
      // Nitrado API typically returns { "message": "..." }
      if (data.containsKey('message')) return data['message'] as String?;
    }
    return null;
  }

  // ── Server listing & status ──────────────────────────────────────

  @override
  Future<List<GameServer>> getServers() async {
    final response = await request(
      () => dio.get<Map<String, dynamic>>('/services'),
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    final services = data['services'] as List<dynamic>;

    return services
        .where((s) {
          final details = s as Map<String, dynamic>;
          final game = (details['details'] as Map<String, dynamic>?)?['game']
              as String?;
          return game?.toLowerCase() == 'dayz';
        })
        .map((s) => _parseGameServer(s as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<GameServer> getServerStatus(int serverId) async {
    final response = await request(
      () => dio.get<Map<String, dynamic>>('/services/$serverId/gameservers'),
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    final gs = data['gameserver'] as Map<String, dynamic>;
    return _parseGameServerDetails(serverId, gs);
  }

  // ── Server control ─────────────────────────────────────────────

  @override
  Future<void> serverAction(int serverId, ServerAction action) async {
    final endpoint = switch (action) {
      ServerAction.start => '/services/$serverId/gameservers/restart',
      ServerAction.stop => '/services/$serverId/gameservers/stop',
      ServerAction.restart => '/services/$serverId/gameservers/restart',
    };
    await request(() => dio.post<Map<String, dynamic>>(endpoint));
  }

  // ── Player management ──────────────────────────────────────────

  @override
  Future<List<Player>> getPlayers(int serverId) async {
    final response = await request(
      () => dio.get<Map<String, dynamic>>(
        '/services/$serverId/gameservers/games/players',
      ),
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    final players = data['players'] as List<dynamic>;
    return players.map((p) {
      final m = p as Map<String, dynamic>;
      return Player(
        id: m['id']?.toString() ?? '',
        name: m['name'] as String? ?? '',
        online: m['online'] as bool? ?? true,
      );
    }).toList();
  }

  @override
  Future<void> kickPlayer(int serverId, String playerId) async {
    await request(
      () => dio.post<Map<String, dynamic>>(
        '/services/$serverId/gameservers/games/players/kick',
        data: {'player_id': playerId},
      ),
    );
  }

  @override
  Future<void> banPlayer(int serverId, String playerId,
      {String? reason}) async {
    await request(
      () => dio.post<Map<String, dynamic>>(
        '/services/$serverId/gameservers/games/players/ban',
        data: {
          'player_id': playerId,
          if (reason != null) 'reason': reason,
        },
      ),
    );
  }

  @override
  Future<List<BannedPlayer>> getBanList(int serverId) async {
    final response = await request(
      () => dio.get<Map<String, dynamic>>(
        '/services/$serverId/gameservers/games/banlist',
      ),
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    final banList = data['banlist'] as List<dynamic>;
    return banList.map((b) {
      final m = b as Map<String, dynamic>;
      return BannedPlayer(
        id: m['id']?.toString() ?? '',
        name: m['name'] as String? ?? '',
        reason: m['reason'] as String?,
        bannedAt: m['banned_at'] != null
            ? DateTime.tryParse(m['banned_at'] as String)
            : null,
      );
    }).toList();
  }

  @override
  Future<void> unbanPlayer(int serverId, String playerId) async {
    await request(
      () => dio.delete<Map<String, dynamic>>(
        '/services/$serverId/gameservers/games/banlist',
        data: {'player_id': playerId},
      ),
    );
  }

  // ── File management ────────────────────────────────────────────

  @override
  Future<List<FileEntry>> listFiles(int serverId, String path) async {
    final response = await request(
      () => dio.get<Map<String, dynamic>>(
        '/services/$serverId/gameservers/file_server/list',
        queryParameters: {'dir': path},
      ),
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    final entries = data['entries'] as List<dynamic>;
    return entries.map((e) {
      final m = e as Map<String, dynamic>;
      return FileEntry(
        name: m['name'] as String? ?? '',
        path: m['path'] as String? ?? '',
        type: m['type'] as String? ?? 'file',
        size: m['size'] as int?,
      );
    }).toList();
  }

  @override
  Future<String> downloadFile(int serverId, String filePath) async {
    final response = await request(
      () => dio.get<Map<String, dynamic>>(
        '/services/$serverId/gameservers/file_server/download',
        queryParameters: {'file': filePath},
      ),
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    final token = data['token'] as Map<String, dynamic>;
    final url = token['url'] as String;

    // Nitrado returns a temporary download URL; fetch the actual content.
    final fileResponse = await Dio().get<String>(url);
    return fileResponse.data ?? '';
  }

  @override
  Future<void> uploadFile(
      int serverId, String filePath, String content) async {
    await request(
      () => dio.post<Map<String, dynamic>>(
        '/services/$serverId/gameservers/file_server/upload',
        queryParameters: {'path': filePath},
        data: content,
        options: Options(contentType: 'application/octet-stream'),
      ),
    );
  }

  // ── Logs ───────────────────────────────────────────────────────

  @override
  Future<String> getServerLogs(int serverId) async {
    // Download the server log file via the file server endpoint.
    return downloadFile(
      serverId,
      '/games/ni${serverId}_dayz/logs/server_log.ADM',
    );
  }

  // ── Private helpers ────────────────────────────────────────────

  GameServer _parseGameServer(Map<String, dynamic> service) {
    final details = service['details'] as Map<String, dynamic>? ?? {};
    return GameServer(
      id: service['id'] as int? ?? 0,
      name: details['name'] as String? ?? '',
      ip: details['address'] as String? ?? '',
      port: details['port'] as int? ?? 0,
      status: service['status'] as String? ?? 'unknown',
      currentPlayers: details['players_current'] as int? ?? 0,
      maxPlayers: details['players_max'] as int? ?? 0,
      map: details['map'] as String? ?? '',
      gameVersion: details['version'] as String? ?? '',
    );
  }

  GameServer _parseGameServerDetails(
      int serverId, Map<String, dynamic> gs) {
    return GameServer(
      id: serverId,
      name: gs['query']?['server_name'] as String? ?? '',
      ip: gs['ip'] as String? ?? '',
      port: gs['port'] as int? ?? 0,
      status: gs['status'] as String? ?? 'unknown',
      currentPlayers:
          gs['query']?['player_current'] as int? ?? 0,
      maxPlayers: gs['query']?['player_max'] as int? ?? 0,
      map: gs['query']?['map'] as String? ?? '',
      gameVersion: gs['query']?['version'] as String? ?? '',
    );
  }
}

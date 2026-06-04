import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:nitrado_server_manager/core/api/api_exceptions.dart';
import 'package:nitrado_server_manager/core/api/nitrado_api_client.dart';
import 'package:nitrado_server_manager/features/economy_config/models/economy_config_model.dart';
import 'package:nitrado_server_manager/features/game_logs/models/game_log_event.dart';
import 'package:nitrado_server_manager/features/player_stats/models/player_stats_model.dart';
import 'package:nitrado_server_manager/shared/models/models.dart';

/// Implementation of [NitradoApiClient] that routes all requests through
/// the Spring Boot backend instead of calling the Nitrado API directly.
///
/// The backend handles authentication, error translation, and logging.
/// The Flutter app no longer needs to store or send the Nitrado token.
class BackendApiClient implements NitradoApiClient {
  final Dio dio;

  BackendApiClient(this.dio);

  // ── Helpers ──────────────────────────────────────────────────────

  /// Wraps a Dio call with standard error handling for backend responses.
  ///
  /// The backend returns errors as `{"error": "CODE", "message": "..."}`.
  @visibleForTesting
  Future<Response<T>> request<T>(Future<Response<T>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;

      String? message;
      if (data is Map<String, dynamic>) {
        message = data['message'] as String?;
      }

      if (statusCode == 401) {
        throw UnauthorizedException(message ?? 'Token inválido o expirado');
      }

      if (statusCode == 404) {
        throw ApiException(message ?? 'Recurso no encontrado',
            statusCode: 404);
      }

      if (statusCode != null && statusCode >= 400 && statusCode < 500) {
        throw ApiException(message ?? 'Error en la solicitud ($statusCode)',
            statusCode: statusCode);
      }

      if (statusCode == 502) {
        throw ApiException(
          message ?? 'Servicio de Nitrado no disponible temporalmente',
          statusCode: 502,
        );
      }

      if (statusCode == 504) {
        throw ApiException(
          message ?? 'No se pudo contactar con el servicio de Nitrado',
          statusCode: 504,
        );
      }

      if (statusCode != null && statusCode >= 500) {
        throw ApiException(
          message ?? 'Error del servidor. Inténtalo de nuevo más tarde.',
          statusCode: statusCode,
        );
      }

      // Network / timeout errors
      throw ApiException('Error de conexión: ${e.message}');
    }
  }

  // ── Server listing & status ──────────────────────────────────────

  @override
  Future<List<GameServer>> getServers() async {
    final response = await request(
      () => dio.get<List<dynamic>>('/api/servers'),
    );
    final servers = response.data ?? [];
    return servers.map((s) {
      final m = s as Map<String, dynamic>;
      return GameServer(
        id: m['id'] as int? ?? 0,
        name: m['name'] as String? ?? '',
        ip: m['ip'] as String? ?? '',
        port: m['port'] as int? ?? 0,
        status: m['status'] as String? ?? 'unknown',
        currentPlayers: m['currentPlayers'] as int? ?? 0,
        maxPlayers: m['maxPlayers'] as int? ?? 0,
        map: m['map'] as String? ?? '',
        gameVersion: m['gameVersion'] as String? ?? '',
      );
    }).toList();
  }

  @override
  Future<GameServer> getServerStatus(int serverId) async {
    final response = await request(
      () => dio.get<Map<String, dynamic>>('/api/servers/$serverId/status'),
    );
    final m = response.data!;
    return GameServer(
      id: m['id'] as int? ?? serverId,
      name: m['name'] as String? ?? '',
      ip: m['ip'] as String? ?? '',
      port: m['port'] as int? ?? 0,
      status: m['status'] as String? ?? 'unknown',
      currentPlayers: m['currentPlayers'] as int? ?? 0,
      maxPlayers: m['maxPlayers'] as int? ?? 0,
      map: m['map'] as String? ?? '',
      gameVersion: m['gameVersion'] as String? ?? '',
    );
  }

  // ── Server control ─────────────────────────────────────────────

  @override
  Future<void> serverAction(int serverId, ServerAction action) async {
    final actionName = action.name; // "start", "stop", "restart"
    await request(
      () => dio.post<Map<String, dynamic>>(
        '/api/servers/$serverId/actions/$actionName',
      ),
    );
  }

  // ── Player management ──────────────────────────────────────────

  @override
  Future<List<Player>> getPlayers(int serverId) async {
    final response = await request(
      () => dio.get<List<dynamic>>('/api/servers/$serverId/players'),
    );
    final players = response.data ?? [];
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
        '/api/servers/$serverId/players/$playerId/kick',
      ),
    );
  }

  @override
  Future<void> banPlayer(int serverId, String playerId,
      {String? reason}) async {
    await request(
      () => dio.post<Map<String, dynamic>>(
        '/api/servers/$serverId/players/$playerId/ban',
        data: reason != null ? {'reason': reason} : null,
      ),
    );
  }

  @override
  Future<List<BannedPlayer>> getBanList(int serverId) async {
    final response = await request(
      () => dio.get<List<dynamic>>('/api/servers/$serverId/banlist'),
    );
    final banList = response.data ?? [];
    return banList.map((b) {
      final m = b as Map<String, dynamic>;
      return BannedPlayer(
        id: m['id']?.toString() ?? '',
        name: m['name'] as String? ?? '',
        reason: m['reason'] as String?,
        bannedAt: m['bannedAt'] != null
            ? DateTime.tryParse(m['bannedAt'] as String)
            : null,
      );
    }).toList();
  }

  @override
  Future<void> unbanPlayer(int serverId, String playerId) async {
    await request(
      () => dio.delete<Map<String, dynamic>>(
        '/api/servers/$serverId/banlist/$playerId',
      ),
    );
  }

  // ── File management ────────────────────────────────────────────

  @override
  Future<List<FileEntry>> listFiles(int serverId, String path) async {
    final response = await request(
      () => dio.get<List<dynamic>>(
        '/api/servers/$serverId/files',
        queryParameters: {'path': path},
      ),
    );
    final entries = response.data ?? [];
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
        '/api/servers/$serverId/files/download',
        queryParameters: {'path': filePath},
      ),
    );
    return response.data?['content'] as String? ?? '';
  }

  @override
  Future<void> uploadFile(
      int serverId, String filePath, String content) async {
    await request(
      () => dio.post<Map<String, dynamic>>(
        '/api/servers/$serverId/files/upload',
        queryParameters: {'path': filePath},
        data: content,
        options: Options(contentType: 'text/plain'),
      ),
    );
  }

  // ── Logs ───────────────────────────────────────────────────────

  @override
  Future<String> getServerLogs(int serverId) async {
    final response = await request(
      () => dio.get<Map<String, dynamic>>('/api/servers/$serverId/logs'),
    );
    return response.data?['content'] as String? ?? '';
  }

  // ── Game Events ────────────────────────────────────────────────

  Future<List<GameLogEvent>> getGameEvents(
    int serverId, {
    String? category,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final response = await request(
      () => dio.get<List<dynamic>>(
        '/api/servers/$serverId/game-events',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      ),
    );
    final events = response.data ?? [];
    return events
        .map((e) => GameLogEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Economy Configuration ────────────────────────────────────────

  Future<EconomyConfigModel> getEconomyConfig(String guildId) async {
    final response = await request(
      () => dio.get<Map<String, dynamic>>(
        '/api/economy/config',
        queryParameters: {'guildId': guildId},
      ),
    );
    return EconomyConfigModel.fromJson(response.data!);
  }

  Future<EconomyConfigModel> updateEconomyConfig(
      String guildId, EconomyConfigModel config) async {
    final response = await request(
      () => dio.put<Map<String, dynamic>>(
        '/api/economy/config',
        queryParameters: {'guildId': guildId},
        data: config.toJson(),
      ),
    );
    return EconomyConfigModel.fromJson(response.data!);
  }

  // ── Player Statistics ────────────────────────────────────────────

  Future<List<PlayerStatsModel>> getPlayerStats() async {
    final response = await request(
      () => dio.get<List<dynamic>>('/api/players/stats'),
    );
    final players = response.data ?? [];
    return players
        .map((p) => PlayerStatsModel.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<PlayerStatsModel> getPlayerStatsById(String discordId) async {
    final response = await request(
      () => dio.get<Map<String, dynamic>>('/api/players/$discordId/stats'),
    );
    return PlayerStatsModel.fromJson(response.data!);
  }

  // ── Transactions ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> getTransactions(
      {int page = 0, int size = 20}) async {
    final response = await request(
      () => dio.get<Map<String, dynamic>>(
        '/api/economy/transactions',
        queryParameters: {'page': page, 'size': size},
      ),
    );
    return response.data!;
  }
}

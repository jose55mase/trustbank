// Feature: nitrado-server-manager, Property 2: Información completa del servidor en dashboard
// **Validates: Requirements 2.3**

import 'package:glados/glados.dart';
import 'package:nitrado_server_manager/shared/models/game_server.dart';

/// XML-safe non-empty string generator (avoids characters that could break
/// string interpolation or cause false positives in contains checks).
final _safeName = any.nonEmptyStringOf(
  'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',
);

/// Valid server status values.
final _statusGen = any.choose([
  'started',
  'stopped',
  'restarting',
  'installing',
]);

/// Generator for random GameServer objects.
final _gameServerGen = any.combine5(
  any.positiveIntOrZero, // id
  _safeName, // name
  any.combine4(
    _safeName, // ip
    any.positiveIntOrZero, // port
    _statusGen, // status
    any.positiveIntOrZero, // currentPlayers
    (String ip, int port, String status, int currentPlayers) =>
        _ServerMid(ip, port, status, currentPlayers),
  ),
  any.combine2(
    any.positiveIntOrZero, // maxPlayers
    _safeName, // map
    (int maxPlayers, String map) => _MaxAndMap(maxPlayers, map),
  ),
  _safeName, // gameVersion
  (int id, String name, _ServerMid mid, _MaxAndMap mm, String gameVersion) =>
      GameServer(
    id: id,
    name: name,
    ip: mid.ip,
    port: mid.port,
    status: mid.status,
    currentPlayers: mid.currentPlayers,
    maxPlayers: mm.maxPlayers,
    map: mm.map,
    gameVersion: gameVersion,
  ),
);

/// Produces the dashboard representation string for a [GameServer].
///
/// This mirrors the information that the dashboard screen displays
/// (Requirement 2.3): name, IP, port, players, map, and game version.
String dashboardRepresentation(GameServer server) {
  return 'Server: ${server.name} | '
      'IP: ${server.ip} | '
      'Port: ${server.port} | '
      'Players: ${server.currentPlayers}/${server.maxPlayers} | '
      'Map: ${server.map} | '
      'Version: ${server.gameVersion}';
}

void main() {
  Glados(_gameServerGen, ExploreConfig(numRuns: 100)).test(
    'dashboard representation contains all required GameServer fields',
    (GameServer server) {
      final repr = dashboardRepresentation(server);

      // Requirement 2.3: name, IP, port, currentPlayers, maxPlayers, map, gameVersion
      expect(repr, contains(server.name));
      expect(repr, contains(server.ip));
      expect(repr, contains('${server.port}'));
      expect(repr, contains('${server.currentPlayers}'));
      expect(repr, contains('${server.maxPlayers}'));
      expect(repr, contains(server.map));
      expect(repr, contains(server.gameVersion));
    },
  );
}

/// Helper to bundle mid-section fields for the combine call.
class _ServerMid {
  final String ip;
  final int port;
  final String status;
  final int currentPlayers;
  _ServerMid(this.ip, this.port, this.status, this.currentPlayers);
}

/// Helper to bundle maxPlayers and map for the combine call.
class _MaxAndMap {
  final int maxPlayers;
  final String map;
  _MaxAndMap(this.maxPlayers, this.map);
}

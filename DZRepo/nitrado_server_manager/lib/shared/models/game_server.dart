/// Represents a DayZ game server from the Nitrado API.
class GameServer {
  final int id;
  final String name;
  final String ip;
  final int port;
  final String status; // "started", "stopped", "restarting", "installing"
  final int currentPlayers;
  final int maxPlayers;
  final String map;
  final String gameVersion;

  const GameServer({
    required this.id,
    required this.name,
    required this.ip,
    required this.port,
    required this.status,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.map,
    required this.gameVersion,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameServer &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          ip == other.ip &&
          port == other.port &&
          status == other.status &&
          currentPlayers == other.currentPlayers &&
          maxPlayers == other.maxPlayers &&
          map == other.map &&
          gameVersion == other.gameVersion;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        ip,
        port,
        status,
        currentPlayers,
        maxPlayers,
        map,
        gameVersion,
      );

  @override
  String toString() => 'GameServer(id: $id, name: $name, ip: $ip, '
      'port: $port, status: $status, '
      'currentPlayers: $currentPlayers, maxPlayers: $maxPlayers, '
      'map: $map, gameVersion: $gameVersion)';
}

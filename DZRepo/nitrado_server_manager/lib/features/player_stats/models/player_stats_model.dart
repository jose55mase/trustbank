/// Represents a linked player's statistics and economy data.
///
/// Maps to the `PlayerStatsDto` returned by the backend REST API
/// at `GET /api/players/stats` and `GET /api/players/{discordId}/stats`.
class PlayerStatsModel {
  final String discordId;
  final String dayzPlayerName;
  final int playerKills;
  final int deaths;
  final String kdRatio;
  final int zombieKills;
  final int zombieMeleeKills;
  final int balance;
  final DateTime? lastActivity;

  const PlayerStatsModel({
    required this.discordId,
    required this.dayzPlayerName,
    required this.playerKills,
    required this.deaths,
    required this.kdRatio,
    required this.zombieKills,
    required this.zombieMeleeKills,
    required this.balance,
    this.lastActivity,
  });

  factory PlayerStatsModel.fromJson(Map<String, dynamic> json) {
    return PlayerStatsModel(
      discordId: json['discordId'] as String? ?? '',
      dayzPlayerName: json['dayzPlayerName'] as String? ?? '',
      playerKills: json['playerKills'] as int? ?? 0,
      deaths: json['deaths'] as int? ?? 0,
      kdRatio: json['kdRatio'] as String? ?? 'N/A',
      zombieKills: json['zombieKills'] as int? ?? 0,
      zombieMeleeKills: json['zombieMeleeKills'] as int? ?? 0,
      balance: json['balance'] as int? ?? 0,
      lastActivity: json['lastActivity'] != null
          ? DateTime.tryParse(json['lastActivity'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerStatsModel &&
          runtimeType == other.runtimeType &&
          discordId == other.discordId &&
          dayzPlayerName == other.dayzPlayerName &&
          playerKills == other.playerKills &&
          deaths == other.deaths &&
          kdRatio == other.kdRatio &&
          zombieKills == other.zombieKills &&
          zombieMeleeKills == other.zombieMeleeKills &&
          balance == other.balance &&
          lastActivity == other.lastActivity;

  @override
  int get hashCode => Object.hash(
        discordId,
        dayzPlayerName,
        playerKills,
        deaths,
        kdRatio,
        zombieKills,
        zombieMeleeKills,
        balance,
        lastActivity,
      );

  @override
  String toString() => 'PlayerStatsModel('
      'discordId: $discordId, '
      'dayzPlayerName: $dayzPlayerName, '
      'playerKills: $playerKills, '
      'deaths: $deaths, '
      'kdRatio: $kdRatio, '
      'zombieKills: $zombieKills, '
      'zombieMeleeKills: $zombieMeleeKills, '
      'balance: $balance, '
      'lastActivity: $lastActivity)';
}

/// Categories for game log events parsed from the DayZ server_log.ADM file.
///
/// Each category maps to a snake_case string used by the backend API.
enum GameLogCategory {
  connection,
  disconnection,
  playerKill,
  zombieKill,
  chat,
  hit,
  unknown;

  /// Parses a category string from the backend API response.
  ///
  /// Accepts both the Dart enum name (e.g. "playerKill") and the
  /// backend snake_case format (e.g. "player_kill").
  /// Returns [GameLogCategory.unknown] for unrecognized values.
  static GameLogCategory fromString(String value) {
    return GameLogCategory.values.firstWhere(
      (e) => e.name == value || e.toApiString() == value,
      orElse: () => GameLogCategory.unknown,
    );
  }

  /// Converts this category to the snake_case string expected by the backend.
  String toApiString() => switch (this) {
        GameLogCategory.playerKill => 'player_kill',
        GameLogCategory.zombieKill => 'zombie_kill',
        _ => name,
      };
}

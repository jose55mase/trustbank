import 'package:nitrado_server_manager/features/game_logs/models/game_log_category.dart';

/// Model representing a single parsed event from the DayZ server_log.ADM file.
///
/// Each event has a timestamp, category, player name, human-readable message,
/// and a details map with category-specific data.
class GameLogEvent {
  final String timestamp;
  final GameLogCategory category;
  final String playerName;
  final String message;
  final Map<String, dynamic> details;

  GameLogEvent({
    required this.timestamp,
    required this.category,
    required this.playerName,
    required this.message,
    required this.details,
  });

  /// Deserializes a [GameLogEvent] from a JSON map.
  ///
  /// Handles missing or null fields gracefully with defaults.
  /// Unknown category strings are mapped to [GameLogCategory.unknown]
  /// without throwing exceptions.
  factory GameLogEvent.fromJson(Map<String, dynamic> json) {
    return GameLogEvent(
      timestamp: json['timestamp'] as String? ?? '',
      category: GameLogCategory.fromString(json['category'] as String? ?? ''),
      playerName: json['playerName'] as String? ?? '',
      message: json['message'] as String? ?? '',
      details: (json['details'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// Serializes this event to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'category': category.toApiString(),
      'playerName': playerName,
      'message': message,
      'details': details,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameLogEvent &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          category == other.category &&
          playerName == other.playerName &&
          message == other.message &&
          _mapEquals(details, other.details);

  @override
  int get hashCode =>
      timestamp.hashCode ^
      category.hashCode ^
      playerName.hashCode ^
      message.hashCode ^
      details.hashCode;

  static bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}

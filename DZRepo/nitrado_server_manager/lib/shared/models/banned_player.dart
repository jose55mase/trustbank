/// Represents a banned player on the server.
class BannedPlayer {
  final String id;
  final String name;
  final String? reason;
  final DateTime? bannedAt;

  const BannedPlayer({
    required this.id,
    required this.name,
    this.reason,
    this.bannedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BannedPlayer &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          reason == other.reason &&
          bannedAt == other.bannedAt;

  @override
  int get hashCode => Object.hash(id, name, reason, bannedAt);

  @override
  String toString() =>
      'BannedPlayer(id: $id, name: $name, reason: $reason, '
      'bannedAt: $bannedAt)';
}

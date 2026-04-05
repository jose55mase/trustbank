/// Represents a player connected to the server.
class Player {
  final String id;
  final String name;
  final bool online;

  const Player({
    required this.id,
    required this.name,
    required this.online,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          online == other.online;

  @override
  int get hashCode => Object.hash(id, name, online);

  @override
  String toString() => 'Player(id: $id, name: $name, online: $online)';
}

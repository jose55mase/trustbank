/// Represents a child entry within a spawn event in events.xml.
class EventChild {
  final String type;
  final int min;
  final int max;
  final int lootmin;
  final int lootmax;

  const EventChild({
    required this.type,
    required this.min,
    required this.max,
    required this.lootmin,
    required this.lootmax,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventChild &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          min == other.min &&
          max == other.max &&
          lootmin == other.lootmin &&
          lootmax == other.lootmax;

  @override
  int get hashCode => Object.hash(type, min, max, lootmin, lootmax);

  @override
  String toString() =>
      'EventChild(type: $type, min: $min, max: $max, '
      'lootmin: $lootmin, lootmax: $lootmax)';
}

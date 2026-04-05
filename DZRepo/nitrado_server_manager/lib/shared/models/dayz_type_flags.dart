/// Flags associated with a DayZ item type in types.xml.
class DayzTypeFlags {
  final int countInCargo;
  final int countInHoarder;
  final int countInMap;
  final int countInPlayer;
  final int crafted;
  final int deloot;

  const DayzTypeFlags({
    required this.countInCargo,
    required this.countInHoarder,
    required this.countInMap,
    required this.countInPlayer,
    required this.crafted,
    required this.deloot,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayzTypeFlags &&
          runtimeType == other.runtimeType &&
          countInCargo == other.countInCargo &&
          countInHoarder == other.countInHoarder &&
          countInMap == other.countInMap &&
          countInPlayer == other.countInPlayer &&
          crafted == other.crafted &&
          deloot == other.deloot;

  @override
  int get hashCode => Object.hash(
        countInCargo,
        countInHoarder,
        countInMap,
        countInPlayer,
        crafted,
        deloot,
      );

  @override
  String toString() =>
      'DayzTypeFlags(countInCargo: $countInCargo, countInHoarder: $countInHoarder, '
      'countInMap: $countInMap, countInPlayer: $countInPlayer, '
      'crafted: $crafted, deloot: $deloot)';
}

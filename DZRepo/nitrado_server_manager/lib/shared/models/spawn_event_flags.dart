/// Flags associated with a spawn event in events.xml.
class SpawnEventFlags {
  final int deletable;
  final int initRandom;
  final int removeDamaged;

  const SpawnEventFlags({
    required this.deletable,
    required this.initRandom,
    required this.removeDamaged,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpawnEventFlags &&
          runtimeType == other.runtimeType &&
          deletable == other.deletable &&
          initRandom == other.initRandom &&
          removeDamaged == other.removeDamaged;

  @override
  int get hashCode => Object.hash(deletable, initRandom, removeDamaged);

  @override
  String toString() =>
      'SpawnEventFlags(deletable: $deletable, initRandom: $initRandom, '
      'removeDamaged: $removeDamaged)';
}

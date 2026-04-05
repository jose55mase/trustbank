import 'package:flutter/foundation.dart';

import 'event_child.dart';
import 'spawn_event_flags.dart';

/// Represents a spawn event entry from events.xml.
class SpawnEvent {
  final String name;
  final int nominal;
  final int min;
  final int max;
  final int lifetime;
  final int restock;
  final int saferadius;
  final int distanceradius;
  final int cleanupradius;
  final SpawnEventFlags flags;
  final String position;
  final String limit;
  final int active;
  final List<EventChild> children;

  const SpawnEvent({
    required this.name,
    required this.nominal,
    required this.min,
    required this.max,
    required this.lifetime,
    required this.restock,
    required this.saferadius,
    required this.distanceradius,
    required this.cleanupradius,
    required this.flags,
    required this.position,
    required this.limit,
    required this.active,
    this.children = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpawnEvent &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          nominal == other.nominal &&
          min == other.min &&
          max == other.max &&
          lifetime == other.lifetime &&
          restock == other.restock &&
          saferadius == other.saferadius &&
          distanceradius == other.distanceradius &&
          cleanupradius == other.cleanupradius &&
          flags == other.flags &&
          position == other.position &&
          limit == other.limit &&
          active == other.active &&
          listEquals(children, other.children);

  @override
  int get hashCode => Object.hash(
        name,
        nominal,
        min,
        max,
        lifetime,
        restock,
        saferadius,
        distanceradius,
        cleanupradius,
        flags,
        position,
        limit,
        active,
        Object.hashAll(children),
      );

  SpawnEvent copyWith({
    String? name,
    int? nominal,
    int? min,
    int? max,
    int? lifetime,
    int? restock,
    int? saferadius,
    int? distanceradius,
    int? cleanupradius,
    SpawnEventFlags? flags,
    String? position,
    String? limit,
    int? active,
    List<EventChild>? children,
  }) {
    return SpawnEvent(
      name: name ?? this.name,
      nominal: nominal ?? this.nominal,
      min: min ?? this.min,
      max: max ?? this.max,
      lifetime: lifetime ?? this.lifetime,
      restock: restock ?? this.restock,
      saferadius: saferadius ?? this.saferadius,
      distanceradius: distanceradius ?? this.distanceradius,
      cleanupradius: cleanupradius ?? this.cleanupradius,
      flags: flags ?? this.flags,
      position: position ?? this.position,
      limit: limit ?? this.limit,
      active: active ?? this.active,
      children: children ?? this.children,
    );
  }

  @override
  String toString() => 'SpawnEvent(name: $name, nominal: $nominal, '
      'min: $min, max: $max, lifetime: $lifetime, restock: $restock, '
      'saferadius: $saferadius, distanceradius: $distanceradius, '
      'cleanupradius: $cleanupradius, flags: $flags, '
      'position: $position, limit: $limit, active: $active, '
      'children: $children)';
}

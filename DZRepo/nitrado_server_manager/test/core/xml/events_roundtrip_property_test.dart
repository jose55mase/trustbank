// Feature: nitrado-server-manager, Property 12: Round trip de events.xml
// **Validates: Requirements 8.5**

import 'package:glados/glados.dart';
import 'package:nitrado_server_manager/core/xml/xml_parser_service_impl.dart';
import 'package:nitrado_server_manager/shared/models/models.dart';

/// XML-safe non-empty string generator (avoids <, >, &, ", ')
final _xmlSafeName = any.nonEmptyStringOf(
  'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_',
);

/// Generator for flag values (0 or 1).
final _binaryGen = any.choose([0, 1]);

/// Generator for SpawnEventFlags.
final _spawnEventFlagsGen = any.combine3(
  _binaryGen,
  _binaryGen,
  _binaryGen,
  (int deletable, int initRandom, int removeDamaged) => SpawnEventFlags(
    deletable: deletable,
    initRandom: initRandom,
    removeDamaged: removeDamaged,
  ),
);

/// Generator for EventChild.
final _eventChildGen = any.combine5(
  _xmlSafeName,
  any.positiveIntOrZero,
  any.positiveIntOrZero,
  any.positiveIntOrZero,
  any.positiveIntOrZero,
  (String type, int min, int max, int lootmin, int lootmax) => EventChild(
    type: type,
    min: min,
    max: max,
    lootmin: lootmin,
    lootmax: lootmax,
  ),
);

/// Generator for a list of EventChild (0-3 items).
final _childrenListGen = any.listWithLengthInRange(0, 3, _eventChildGen);

/// Generator for position field.
final _positionGen = any.choose(['fixed', 'player']);

/// Generator for limit field.
final _limitGen = any.choose(['child', 'custom', 'mixed']);

/// Generator for a single SpawnEvent.
final _spawnEventGen = any.combine5(
  _xmlSafeName,
  any.combine4(
    any.positiveIntOrZero,
    any.positiveIntOrZero,
    any.positiveIntOrZero,
    any.positiveIntOrZero,
    (int nominal, int min, int max, int lifetime) =>
        [nominal, min, max, lifetime],
  ),
  any.combine5(
    any.positiveIntOrZero,
    any.positiveIntOrZero,
    any.positiveIntOrZero,
    any.positiveIntOrZero,
    _spawnEventFlagsGen,
    (int restock, int saferadius, int distanceradius, int cleanupradius,
            SpawnEventFlags flags) =>
        _IntFieldsAndFlags(
            restock, saferadius, distanceradius, cleanupradius, flags),
  ),
  any.combine3(
    _positionGen,
    _limitGen,
    _binaryGen,
    (String position, String limit, int active) =>
        _EventMeta(position, limit, active),
  ),
  _childrenListGen,
  (
    String name,
    List<int> nums,
    _IntFieldsAndFlags rest,
    _EventMeta meta,
    List<EventChild> children,
  ) =>
      SpawnEvent(
    name: name,
    nominal: nums[0],
    min: nums[1],
    max: nums[2],
    lifetime: nums[3],
    restock: rest.restock,
    saferadius: rest.saferadius,
    distanceradius: rest.distanceradius,
    cleanupradius: rest.cleanupradius,
    flags: rest.flags,
    position: meta.position,
    limit: meta.limit,
    active: meta.active,
    children: children,
  ),
);

/// Generator for a list of SpawnEvent (0-5 items).
final _spawnEventListGen = any.listWithLengthInRange(0, 6, _spawnEventGen);

void main() {
  final service = XmlParserServiceImpl();

  Glados(_spawnEventListGen, ExploreConfig(numRuns: 100)).test(
    'serializeEvents then parseEvents produces equivalent list',
    (List<SpawnEvent> original) {
      final xml = service.serializeEvents(original);
      final parsed = service.parseEvents(xml);
      expect(parsed, equals(original));
    },
  );
}

/// Helper class to bundle int fields + flags for combine.
class _IntFieldsAndFlags {
  final int restock;
  final int saferadius;
  final int distanceradius;
  final int cleanupradius;
  final SpawnEventFlags flags;
  _IntFieldsAndFlags(
    this.restock,
    this.saferadius,
    this.distanceradius,
    this.cleanupradius,
    this.flags,
  );
}

/// Helper class to bundle event metadata for combine.
class _EventMeta {
  final String position;
  final String limit;
  final int active;
  _EventMeta(this.position, this.limit, this.active);
}

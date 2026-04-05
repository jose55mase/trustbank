// Feature: nitrado-server-manager, Property 13: Mapeo estado activo/inactivo de eventos
// **Validates: Requirements 8.4**

import 'package:glados/glados.dart';
import 'package:nitrado_server_manager/features/events_manager/events_helpers.dart';
import 'package:nitrado_server_manager/shared/models/models.dart';

/// XML-safe non-empty string generator.
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

/// Generates a SpawnEvent with a specific active value (0 or 1).
_spawnEventWithActive(int activeValue) => any.combine5(
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
      any.combine2(
        _positionGen,
        _limitGen,
        (String position, String limit) => _EventMeta(position, limit),
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
        active: activeValue,
        children: children,
      ),
    );

void main() {
  Glados(_spawnEventWithActive(0), ExploreConfig(numRuns: 100)).test(
    'isEventActive returns false when active == 0 (desactivado)',
    (event) {
      final e = event as SpawnEvent;
      expect(e.active, equals(0));
      expect(isEventActive(e), isFalse);
    },
  );

  Glados(_spawnEventWithActive(1), ExploreConfig(numRuns: 100)).test(
    'isEventActive returns true when active == 1 (activado)',
    (event) {
      final e = event as SpawnEvent;
      expect(e.active, equals(1));
      expect(isEventActive(e), isTrue);
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
  _EventMeta(this.position, this.limit);
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nitrado_server_manager/shared/models/models.dart';

void main() {
  group('GameServer', () {
    test('value equality holds for identical fields', () {
      const a = GameServer(
        id: 1,
        name: 'Test',
        ip: '1.2.3.4',
        port: 2302,
        status: 'started',
        currentPlayers: 5,
        maxPlayers: 60,
        map: 'chernarusplus',
        gameVersion: '1.24',
      );
      const b = GameServer(
        id: 1,
        name: 'Test',
        ip: '1.2.3.4',
        port: 2302,
        status: 'started',
        currentPlayers: 5,
        maxPlayers: 60,
        map: 'chernarusplus',
        gameVersion: '1.24',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality when a field differs', () {
      const a = GameServer(
        id: 1, name: 'A', ip: '0.0.0.0', port: 1,
        status: 'started', currentPlayers: 0, maxPlayers: 1,
        map: 'm', gameVersion: 'v',
      );
      const b = GameServer(
        id: 2, name: 'A', ip: '0.0.0.0', port: 1,
        status: 'started', currentPlayers: 0, maxPlayers: 1,
        map: 'm', gameVersion: 'v',
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('Player', () {
    test('value equality', () {
      const a = Player(id: '1', name: 'Alice', online: true);
      const b = Player(id: '1', name: 'Alice', online: true);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality when online differs', () {
      const a = Player(id: '1', name: 'Alice', online: true);
      const b = Player(id: '1', name: 'Alice', online: false);
      expect(a, isNot(equals(b)));
    });
  });

  group('BannedPlayer', () {
    test('value equality with nullable fields', () {
      final dt = DateTime(2024, 1, 1);
      final a = BannedPlayer(id: '1', name: 'Bob', reason: 'cheat', bannedAt: dt);
      final b = BannedPlayer(id: '1', name: 'Bob', reason: 'cheat', bannedAt: dt);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('equality with null optionals', () {
      const a = BannedPlayer(id: '1', name: 'Bob');
      const b = BannedPlayer(id: '1', name: 'Bob');
      expect(a, equals(b));
    });
  });

  group('ServerAction', () {
    test('enum values exist', () {
      expect(ServerAction.values, containsAll([
        ServerAction.start,
        ServerAction.stop,
        ServerAction.restart,
      ]));
    });
  });

  group('DayzTypeFlags', () {
    test('value equality', () {
      const a = DayzTypeFlags(
        countInCargo: 0, countInHoarder: 0, countInMap: 1,
        countInPlayer: 0, crafted: 0, deloot: 0,
      );
      const b = DayzTypeFlags(
        countInCargo: 0, countInHoarder: 0, countInMap: 1,
        countInPlayer: 0, crafted: 0, deloot: 0,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('DayzType', () {
    test('value equality including lists', () {
      const flags = DayzTypeFlags(
        countInCargo: 0, countInHoarder: 0, countInMap: 1,
        countInPlayer: 0, crafted: 0, deloot: 0,
      );
      const a = DayzType(
        name: 'AK101', nominal: 20, lifetime: 14400, restock: 3600,
        min: 12, quantmin: 30, quantmax: 80, cost: 100,
        flags: flags, category: 'weapons',
        usages: ['Military'], values: ['Tier4'], tags: [],
      );
      const b = DayzType(
        name: 'AK101', nominal: 20, lifetime: 14400, restock: 3600,
        min: 12, quantmin: 30, quantmax: 80, cost: 100,
        flags: flags, category: 'weapons',
        usages: ['Military'], values: ['Tier4'], tags: [],
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality when list content differs', () {
      const flags = DayzTypeFlags(
        countInCargo: 0, countInHoarder: 0, countInMap: 1,
        countInPlayer: 0, crafted: 0, deloot: 0,
      );
      const a = DayzType(
        name: 'AK101', nominal: 20, lifetime: 14400, restock: 3600,
        min: 12, quantmin: 30, quantmax: 80, cost: 100,
        flags: flags, usages: ['Military'],
      );
      const b = DayzType(
        name: 'AK101', nominal: 20, lifetime: 14400, restock: 3600,
        min: 12, quantmin: 30, quantmax: 80, cost: 100,
        flags: flags, usages: ['Police'],
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('GlobalVariable', () {
    test('value equality', () {
      const a = GlobalVariable(name: 'ZombieMaxCount', type: 0, value: '1000');
      const b = GlobalVariable(name: 'ZombieMaxCount', type: 0, value: '1000');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('SpawnEventFlags', () {
    test('value equality', () {
      const a = SpawnEventFlags(deletable: 0, initRandom: 0, removeDamaged: 1);
      const b = SpawnEventFlags(deletable: 0, initRandom: 0, removeDamaged: 1);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('EventChild', () {
    test('value equality', () {
      const a = EventChild(type: 'Bear', min: 1, max: 2, lootmin: 0, lootmax: 0);
      const b = EventChild(type: 'Bear', min: 1, max: 2, lootmin: 0, lootmax: 0);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('SpawnEvent', () {
    test('value equality including children list', () {
      const flags = SpawnEventFlags(deletable: 0, initRandom: 0, removeDamaged: 1);
      const child = EventChild(type: 'Animal_UrsusArctos', min: 1, max: 1, lootmin: 0, lootmax: 0);
      const a = SpawnEvent(
        name: 'AnimalBear', nominal: 10, min: 2, max: 2,
        lifetime: 180, restock: 0, saferadius: 200,
        distanceradius: 0, cleanupradius: 0, flags: flags,
        position: 'fixed', limit: 'custom', active: 1,
        children: [child],
      );
      const b = SpawnEvent(
        name: 'AnimalBear', nominal: 10, min: 2, max: 2,
        lifetime: 180, restock: 0, saferadius: 200,
        distanceradius: 0, cleanupradius: 0, flags: flags,
        position: 'fixed', limit: 'custom', active: 1,
        children: [child],
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality when children differ', () {
      const flags = SpawnEventFlags(deletable: 0, initRandom: 0, removeDamaged: 1);
      const a = SpawnEvent(
        name: 'AnimalBear', nominal: 10, min: 2, max: 2,
        lifetime: 180, restock: 0, saferadius: 200,
        distanceradius: 0, cleanupradius: 0, flags: flags,
        position: 'fixed', limit: 'custom', active: 1,
        children: [EventChild(type: 'A', min: 1, max: 1, lootmin: 0, lootmax: 0)],
      );
      const b = SpawnEvent(
        name: 'AnimalBear', nominal: 10, min: 2, max: 2,
        lifetime: 180, restock: 0, saferadius: 200,
        distanceradius: 0, cleanupradius: 0, flags: flags,
        position: 'fixed', limit: 'custom', active: 1,
        children: [EventChild(type: 'B', min: 1, max: 1, lootmin: 0, lootmax: 0)],
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('FileEntry', () {
    test('value equality', () {
      const a = FileEntry(name: 'types.xml', path: '/db/types.xml', type: 'file', size: 1024);
      const b = FileEntry(name: 'types.xml', path: '/db/types.xml', type: 'file', size: 1024);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('equality with null size', () {
      const a = FileEntry(name: 'db', path: '/db', type: 'dir');
      const b = FileEntry(name: 'db', path: '/db', type: 'dir');
      expect(a, equals(b));
    });
  });
}

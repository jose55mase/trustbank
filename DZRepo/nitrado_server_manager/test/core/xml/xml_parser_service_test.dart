import 'package:flutter_test/flutter_test.dart';
import 'package:nitrado_server_manager/core/xml/xml_parser_service.dart';
import 'package:nitrado_server_manager/core/xml/xml_parser_service_impl.dart';
import 'package:nitrado_server_manager/shared/models/models.dart';

void main() {
  late XmlParserService service;

  setUp(() {
    service = XmlParserServiceImpl();
  });

  // ---------------------------------------------------------------------------
  // parseTypes / serializeTypes
  // ---------------------------------------------------------------------------
  group('parseTypes', () {
    test('parses a single type element correctly', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<types>
  <type name="AK101">
    <nominal>20</nominal>
    <lifetime>14400</lifetime>
    <restock>3600</restock>
    <min>12</min>
    <quantmin>30</quantmin>
    <quantmax>80</quantmax>
    <cost>100</cost>
    <flags count_in_cargo="0" count_in_hoarder="0" count_in_map="1" count_in_player="0" crafted="0" deloot="0"/>
    <category name="weapons"/>
    <usage name="Military"/>
    <value name="Tier4"/>
  </type>
</types>''';

      final result = service.parseTypes(xml);
      expect(result, hasLength(1));
      final t = result.first;
      expect(t.name, 'AK101');
      expect(t.nominal, 20);
      expect(t.lifetime, 14400);
      expect(t.restock, 3600);
      expect(t.min, 12);
      expect(t.quantmin, 30);
      expect(t.quantmax, 80);
      expect(t.cost, 100);
      expect(t.flags.countInCargo, 0);
      expect(t.flags.countInMap, 1);
      expect(t.category, 'weapons');
      expect(t.usages, ['Military']);
      expect(t.values, ['Tier4']);
      expect(t.tags, isEmpty);
    });

    test('parses type with no category, multiple usages and values', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<types>
  <type name="Apple">
    <nominal>5</nominal>
    <lifetime>100</lifetime>
    <restock>50</restock>
    <min>1</min>
    <quantmin>0</quantmin>
    <quantmax>0</quantmax>
    <cost>10</cost>
    <flags count_in_cargo="1" count_in_hoarder="0" count_in_map="0" count_in_player="1" crafted="0" deloot="0"/>
    <usage name="Town"/>
    <usage name="Village"/>
    <value name="Tier1"/>
    <value name="Tier2"/>
  </type>
</types>''';

      final result = service.parseTypes(xml);
      expect(result, hasLength(1));
      expect(result.first.category, isNull);
      expect(result.first.usages, ['Town', 'Village']);
      expect(result.first.values, ['Tier1', 'Tier2']);
    });

    test('parses empty types list', () {
      const xml = '<?xml version="1.0"?><types></types>';
      expect(service.parseTypes(xml), isEmpty);
    });
  });

  group('serializeTypes round-trip', () {
    test('serialize then parse produces equivalent objects', () {
      final original = [
        DayzType(
          name: 'TestItem',
          nominal: 10,
          lifetime: 7200,
          restock: 1800,
          min: 5,
          quantmin: 0,
          quantmax: 0,
          cost: 50,
          flags: const DayzTypeFlags(
            countInCargo: 1,
            countInHoarder: 0,
            countInMap: 1,
            countInPlayer: 0,
            crafted: 0,
            deloot: 0,
          ),
          category: 'tools',
          usages: ['Military', 'Police'],
          values: ['Tier2'],
          tags: ['shelves'],
        ),
      ];

      final xml = service.serializeTypes(original);
      final parsed = service.parseTypes(xml);
      expect(parsed, original);
    });
  });

  // ---------------------------------------------------------------------------
  // parseGlobals / serializeGlobals
  // ---------------------------------------------------------------------------
  group('parseGlobals', () {
    test('parses global variables correctly', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<variables>
  <var name="ZombieMaxCount" type="0" value="1000"/>
  <var name="LootDamageMax" type="1" value="0.82"/>
</variables>''';

      final result = service.parseGlobals(xml);
      expect(result, hasLength(2));
      expect(result[0].name, 'ZombieMaxCount');
      expect(result[0].type, 0);
      expect(result[0].value, '1000');
      expect(result[1].name, 'LootDamageMax');
      expect(result[1].type, 1);
      expect(result[1].value, '0.82');
    });

    test('parses empty globals list', () {
      const xml = '<?xml version="1.0"?><variables></variables>';
      expect(service.parseGlobals(xml), isEmpty);
    });
  });

  group('serializeGlobals round-trip', () {
    test('serialize then parse produces equivalent objects', () {
      final original = [
        const GlobalVariable(name: 'TestVar', type: 0, value: '42'),
        const GlobalVariable(name: 'DecimalVar', type: 1, value: '3.14'),
      ];

      final xml = service.serializeGlobals(original);
      final parsed = service.parseGlobals(xml);
      expect(parsed, original);
    });
  });

  // ---------------------------------------------------------------------------
  // parseEvents / serializeEvents
  // ---------------------------------------------------------------------------
  group('parseEvents', () {
    test('parses a single event with children', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<events>
  <event name="AnimalBear">
    <nominal>10</nominal>
    <min>2</min>
    <max>2</max>
    <lifetime>180</lifetime>
    <restock>0</restock>
    <saferadius>200</saferadius>
    <distanceradius>0</distanceradius>
    <cleanupradius>0</cleanupradius>
    <flags deletable="0" init_random="0" remove_damaged="1"/>
    <position>fixed</position>
    <limit>custom</limit>
    <active>1</active>
    <children>
      <child lootmax="0" lootmin="0" max="1" min="1" type="Animal_UrsusArctos"/>
    </children>
  </event>
</events>''';

      final result = service.parseEvents(xml);
      expect(result, hasLength(1));
      final e = result.first;
      expect(e.name, 'AnimalBear');
      expect(e.nominal, 10);
      expect(e.min, 2);
      expect(e.max, 2);
      expect(e.lifetime, 180);
      expect(e.restock, 0);
      expect(e.saferadius, 200);
      expect(e.flags.deletable, 0);
      expect(e.flags.initRandom, 0);
      expect(e.flags.removeDamaged, 1);
      expect(e.position, 'fixed');
      expect(e.limit, 'custom');
      expect(e.active, 1);
      expect(e.children, hasLength(1));
      expect(e.children.first.type, 'Animal_UrsusArctos');
      expect(e.children.first.min, 1);
      expect(e.children.first.max, 1);
      expect(e.children.first.lootmin, 0);
      expect(e.children.first.lootmax, 0);
    });

    test('parses event without children', () {
      const xml = '''<?xml version="1.0"?>
<events>
  <event name="Simple">
    <nominal>5</nominal>
    <min>1</min>
    <max>3</max>
    <lifetime>60</lifetime>
    <restock>10</restock>
    <saferadius>100</saferadius>
    <distanceradius>50</distanceradius>
    <cleanupradius>25</cleanupradius>
    <flags deletable="1" init_random="1" remove_damaged="0"/>
    <position>player</position>
    <limit>child</limit>
    <active>0</active>
  </event>
</events>''';

      final result = service.parseEvents(xml);
      expect(result, hasLength(1));
      expect(result.first.children, isEmpty);
      expect(result.first.active, 0);
    });

    test('parses empty events list', () {
      const xml = '<?xml version="1.0"?><events></events>';
      expect(service.parseEvents(xml), isEmpty);
    });
  });

  group('serializeEvents round-trip', () {
    test('serialize then parse produces equivalent objects', () {
      final original = [
        SpawnEvent(
          name: 'TestEvent',
          nominal: 8,
          min: 2,
          max: 4,
          lifetime: 300,
          restock: 60,
          saferadius: 150,
          distanceradius: 50,
          cleanupradius: 30,
          flags: const SpawnEventFlags(
            deletable: 1,
            initRandom: 0,
            removeDamaged: 1,
          ),
          position: 'fixed',
          limit: 'mixed',
          active: 1,
          children: const [
            EventChild(
              type: 'ChildType',
              min: 1,
              max: 2,
              lootmin: 0,
              lootmax: 5,
            ),
          ],
        ),
      ];

      final xml = service.serializeEvents(original);
      final parsed = service.parseEvents(xml);
      expect(parsed, original);
    });
  });

  // ---------------------------------------------------------------------------
  // isValidXml / isValidJson
  // ---------------------------------------------------------------------------
  group('isValidXml', () {
    test('returns true for well-formed XML', () {
      expect(service.isValidXml('<root><child/></root>'), isTrue);
    });

    test('returns true for XML with declaration', () {
      expect(
        service.isValidXml('<?xml version="1.0"?><root/>'),
        isTrue,
      );
    });

    test('returns false for malformed XML', () {
      expect(service.isValidXml('<root><unclosed>'), isFalse);
    });

    test('returns false for empty string', () {
      expect(service.isValidXml(''), isFalse);
    });

    test('returns false for plain text', () {
      expect(service.isValidXml('hello world'), isFalse);
    });

    test('returns false for JSON', () {
      expect(service.isValidXml('{"key": "value"}'), isFalse);
    });
  });

  group('isValidJson', () {
    test('returns true for valid JSON object', () {
      expect(service.isValidJson('{"key": "value"}'), isTrue);
    });

    test('returns true for valid JSON array', () {
      expect(service.isValidJson('[1, 2, 3]'), isTrue);
    });

    test('returns true for JSON primitives', () {
      expect(service.isValidJson('"hello"'), isTrue);
      expect(service.isValidJson('42'), isTrue);
      expect(service.isValidJson('true'), isTrue);
      expect(service.isValidJson('null'), isTrue);
    });

    test('returns false for invalid JSON', () {
      expect(service.isValidJson('{invalid}'), isFalse);
    });

    test('returns false for empty string', () {
      expect(service.isValidJson(''), isFalse);
    });

    test('returns false for XML', () {
      expect(service.isValidJson('<root/>'), isFalse);
    });
  });
}

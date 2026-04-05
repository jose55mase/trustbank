// Feature: nitrado-server-manager, Property 7: Round trip de types.xml
// **Validates: Requirements 6.4**

import 'package:glados/glados.dart';
import 'package:nitrado_server_manager/core/xml/xml_parser_service_impl.dart';
import 'package:nitrado_server_manager/shared/models/models.dart';

/// XML-safe non-empty string generator (avoids <, >, &, ", ')
final _xmlSafeName = any.nonEmptyStringOf(
  'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_',
);

/// Generator for DayzTypeFlags with values 0 or 1.
final _flagGen = any.choose([0, 1]);

final _dayzTypeFlagsGen = any.combine6(
  _flagGen,
  _flagGen,
  _flagGen,
  _flagGen,
  _flagGen,
  _flagGen,
  (int a, int b, int c, int d, int e, int f) => DayzTypeFlags(
    countInCargo: a,
    countInHoarder: b,
    countInMap: c,
    countInPlayer: d,
    crafted: e,
    deloot: f,
  ),
);

/// Valid categories (nullable).
final _categoryGen = any.choose<String?>([
  null,
  'weapons',
  'tools',
  'containers',
  'clothes',
  'food',
  'explosives',
  'books',
]);

/// Generator for a list of XML-safe non-empty strings (0-3 items).
final _stringListGen = any.listWithLengthInRange(0, 4, _xmlSafeName);

/// Generator for a single DayzType.
final _dayzTypeGen = any.combine5(
  _xmlSafeName,
  any.combine4(
    any.positiveIntOrZero,
    any.positiveIntOrZero,
    any.positiveIntOrZero,
    any.positiveIntOrZero,
    (int nominal, int lifetime, int restock, int min) =>
        [nominal, lifetime, restock, min],
  ),
  any.combine4(
    any.positiveIntOrZero,
    any.positiveIntOrZero,
    any.positiveIntOrZero,
    _dayzTypeFlagsGen,
    (int quantmin, int quantmax, int cost, DayzTypeFlags flags) =>
        _IntFieldsAndFlags(quantmin, quantmax, cost, flags),
  ),
  _categoryGen,
  any.combine3(
    _stringListGen,
    _stringListGen,
    _stringListGen,
    (List<String> usages, List<String> values, List<String> tags) =>
        _StringLists(usages, values, tags),
  ),
  (
    String name,
    List<int> nums,
    _IntFieldsAndFlags rest,
    String? category,
    _StringLists lists,
  ) =>
      DayzType(
    name: name,
    nominal: nums[0],
    lifetime: nums[1],
    restock: nums[2],
    min: nums[3],
    quantmin: rest.quantmin,
    quantmax: rest.quantmax,
    cost: rest.cost,
    flags: rest.flags,
    category: category,
    usages: lists.usages,
    values: lists.values,
    tags: lists.tags,
  ),
);

/// Generator for a list of DayzType (0-5 items).
final _dayzTypeListGen = any.listWithLengthInRange(0, 6, _dayzTypeGen);

void main() {
  final service = XmlParserServiceImpl();

  Glados(_dayzTypeListGen, ExploreConfig(numRuns: 100)).test(
    'serializeTypes then parseTypes produces equivalent list',
    (List<DayzType> original) {
      final xml = service.serializeTypes(original);
      final parsed = service.parseTypes(xml);
      expect(parsed, equals(original));
    },
  );
}

/// Helper class to bundle int fields + flags for combine.
class _IntFieldsAndFlags {
  final int quantmin;
  final int quantmax;
  final int cost;
  final DayzTypeFlags flags;
  _IntFieldsAndFlags(this.quantmin, this.quantmax, this.cost, this.flags);
}

/// Helper class to bundle string lists for combine.
class _StringLists {
  final List<String> usages;
  final List<String> values;
  final List<String> tags;
  _StringLists(this.usages, this.values, this.tags);
}

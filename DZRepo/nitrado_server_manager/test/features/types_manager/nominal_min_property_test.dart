// Feature: nitrado-server-manager, Property 9: Validación nominal >= min en types
// **Validates: Requirements 6.5**

import 'package:glados/glados.dart';
import 'package:nitrado_server_manager/features/types_manager/types_helpers.dart';
import 'package:nitrado_server_manager/shared/models/models.dart';

/// XML-safe non-empty string generator.
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

/// Optional category generator.
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

/// Generator for a DayzType with random nominal and min values.
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
  any.combine3(
    any.positiveIntOrZero,
    any.positiveIntOrZero,
    any.positiveIntOrZero,
    (int quantmin, int quantmax, int cost) => [quantmin, quantmax, cost],
  ),
  _dayzTypeFlagsGen,
  _categoryGen,
  (
    String name,
    List<int> nums,
    List<int> quants,
    DayzTypeFlags flags,
    String? category,
  ) =>
      DayzType(
    name: name,
    nominal: nums[0],
    lifetime: nums[1],
    restock: nums[2],
    min: nums[3],
    quantmin: quants[0],
    quantmax: quants[1],
    cost: quants[2],
    flags: flags,
    category: category,
  ),
);

void main() {
  Glados(
    _dayzTypeGen,
    ExploreConfig(numRuns: 100),
  ).test(
    'validateNominalMin returns false when nominal < min, true when nominal >= min',
    (DayzType type) {
      final result = validateNominalMin(type);

      if (type.nominal < type.min) {
        expect(result, isFalse,
            reason:
                'nominal (${type.nominal}) < min (${type.min}) should be invalid');
      } else {
        expect(result, isTrue,
            reason:
                'nominal (${type.nominal}) >= min (${type.min}) should be valid');
      }
    },
  );
}

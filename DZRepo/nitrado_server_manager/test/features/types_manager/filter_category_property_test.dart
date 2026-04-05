// Feature: nitrado-server-manager, Property 8: Filtrado de items por categoría
// **Validates: Requirements 6.1, 6.6**

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

/// Valid categories including null.
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

/// Generator for a single DayzType with random category.
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

/// Generator for a list of DayzType (0-10 items).
final _dayzTypeListGen = any.listWithLengthInRange(0, 10, _dayzTypeGen);

/// Generator for a valid category string (non-null).
final _validCategoryGen = any.choose(validCategories);

void main() {
  Glados(
    any.combine2(
      _dayzTypeListGen,
      _validCategoryGen,
      (List<DayzType> types, String category) => _FilterInput(types, category),
    ),
    ExploreConfig(numRuns: 100),
  ).test(
    'filterByCategory returns exactly the items matching the given category',
    (_FilterInput input) {
      final result = filterByCategory(input.types, input.category);

      // All returned items must have the matching category
      for (final item in result) {
        expect(
          item.category?.toLowerCase(),
          equals(input.category.toLowerCase()),
        );
      }

      // All items with the matching category must be present in the result
      final expected = input.types
          .where(
              (t) => t.category?.toLowerCase() == input.category.toLowerCase())
          .toList();
      expect(result, equals(expected));
    },
  );
}

/// Helper to bundle test inputs.
class _FilterInput {
  final List<DayzType> types;
  final String category;
  _FilterInput(this.types, this.category);
}

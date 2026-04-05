import 'package:flutter_test/flutter_test.dart';
import 'package:nitrado_server_manager/shared/models/dayz_type.dart';
import 'package:nitrado_server_manager/shared/models/dayz_type_flags.dart';
import 'package:nitrado_server_manager/features/types_manager/types_helpers.dart';

const _defaultFlags = DayzTypeFlags(
  countInCargo: 0,
  countInHoarder: 0,
  countInMap: 1,
  countInPlayer: 0,
  crafted: 0,
  deloot: 0,
);

DayzType _makeType({
  String name = 'TestItem',
  int nominal = 10,
  int min = 5,
  String? category,
  List<String> usages = const [],
}) {
  return DayzType(
    name: name,
    nominal: nominal,
    lifetime: 14400,
    restock: 3600,
    min: min,
    quantmin: 0,
    quantmax: 100,
    cost: 100,
    flags: _defaultFlags,
    category: category,
    usages: usages,
  );
}

void main() {
  group('filterByCategory', () {
    test('returns only items matching the given category', () {
      final types = [
        _makeType(name: 'AK101', category: 'weapons'),
        _makeType(name: 'Hammer', category: 'tools'),
        _makeType(name: 'M4A1', category: 'weapons'),
        _makeType(name: 'Apple', category: 'food'),
      ];

      final result = filterByCategory(types, 'weapons');

      expect(result.length, 2);
      expect(result.every((t) => t.category == 'weapons'), isTrue);
    });

    test('returns empty list when no items match', () {
      final types = [
        _makeType(name: 'AK101', category: 'weapons'),
      ];

      final result = filterByCategory(types, 'food');

      expect(result, isEmpty);
    });

    test('is case-insensitive', () {
      final types = [
        _makeType(name: 'AK101', category: 'weapons'),
      ];

      final result = filterByCategory(types, 'Weapons');

      expect(result.length, 1);
    });

    test('handles items with null category', () {
      final types = [
        _makeType(name: 'AK101', category: null),
        _makeType(name: 'M4A1', category: 'weapons'),
      ];

      final result = filterByCategory(types, 'weapons');

      expect(result.length, 1);
      expect(result.first.name, 'M4A1');
    });

    test('returns empty list for empty input', () {
      final result = filterByCategory([], 'weapons');
      expect(result, isEmpty);
    });
  });

  group('validateNominalMin', () {
    test('returns true when nominal >= min', () {
      final type = _makeType(nominal: 10, min: 5);
      expect(validateNominalMin(type), isTrue);
    });

    test('returns true when nominal == min', () {
      final type = _makeType(nominal: 5, min: 5);
      expect(validateNominalMin(type), isTrue);
    });

    test('returns false when nominal < min', () {
      final type = _makeType(nominal: 3, min: 5);
      expect(validateNominalMin(type), isFalse);
    });

    test('returns true when both are zero', () {
      final type = _makeType(nominal: 0, min: 0);
      expect(validateNominalMin(type), isTrue);
    });
  });

  group('DayzType.copyWith', () {
    test('copies with updated nominal', () {
      final original = _makeType(nominal: 10);
      final copy = original.copyWith(nominal: 20);
      expect(copy.nominal, 20);
      expect(copy.name, original.name);
      expect(copy.min, original.min);
    });

    test('copies with null category', () {
      final original = _makeType(category: 'weapons');
      final copy = original.copyWith(category: null);
      expect(copy.category, isNull);
    });

    test('preserves category when not specified', () {
      final original = _makeType(category: 'weapons');
      final copy = original.copyWith(nominal: 5);
      expect(copy.category, 'weapons');
    });
  });
}

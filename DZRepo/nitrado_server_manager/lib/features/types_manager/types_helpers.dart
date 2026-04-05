import '../../shared/models/dayz_type.dart';

/// Valid categories for DayZ item types.
const validCategories = [
  'weapons',
  'tools',
  'containers',
  'clothes',
  'food',
  'explosives',
  'books',
];

/// Filters a list of [DayzType] by [category].
///
/// Returns only items whose category matches the given [category]
/// (case-insensitive comparison).
///
/// Used by Property 8: Filtrado de items por categoría.
List<DayzType> filterByCategory(List<DayzType> types, String category) {
  final lower = category.toLowerCase();
  return types
      .where((t) => t.category?.toLowerCase() == lower)
      .toList();
}

/// Validates that [type.nominal] >= [type.min].
///
/// Returns `true` if the constraint holds, `false` if nominal < min.
///
/// Used by Property 9: Validación nominal >= min en types.
bool validateNominalMin(DayzType type) {
  return type.nominal >= type.min;
}

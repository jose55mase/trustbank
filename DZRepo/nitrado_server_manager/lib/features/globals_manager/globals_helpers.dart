/// Pure helper function for validating numeric values in globals.xml.
///
/// Used by Property 11: Validación numérica de variables globales.

/// Returns `true` if [value] is a valid integer or decimal number.
///
/// Accepts optional leading minus sign, integers (e.g. "42", "-7"),
/// and decimals (e.g. "3.14", "-0.5", "0.0").
/// Rejects empty strings, whitespace-only, and non-numeric text.
bool isValidNumericValue(String value) {
  if (value.isEmpty) return false;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return false;
  // Use a regex that matches integers and decimals with optional leading minus.
  final numericRegex = RegExp(r'^-?\d+(\.\d+)?$');
  return numericRegex.hasMatch(trimmed);
}

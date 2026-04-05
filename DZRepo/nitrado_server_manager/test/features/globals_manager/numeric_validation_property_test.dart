// Feature: nitrado-server-manager, Property 11: Validación numérica de variables globales
// **Validates: Requirements 7.3**

import 'package:glados/glados.dart';
import 'package:nitrado_server_manager/features/globals_manager/globals_helpers.dart';

/// Generator for valid numeric strings: integers and decimals, positive and negative.
/// Uses combine2 to produce both integer and decimal forms deterministically.
final _validNumericGen = any.combine2(
  any.positiveIntOrZero,
  any.intInRange(0, 10000),
  (int whole, int frac) {
    // Even whole → positive decimal, odd whole → negative integer
    if (whole.isEven) {
      return '$whole.${frac.toString()}';
    } else {
      return '-$whole';
    }
  },
);

/// Characters that make a string non-numeric when present.
const _nonNumericChars =
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#%^&*()_+=[]{}|;:,<>?/~`';

/// Generator for non-numeric strings (containing at least one letter or special char).
final _nonNumericGen = any.nonEmptyStringOf(_nonNumericChars);

void main() {
  Glados(
    _validNumericGen,
    ExploreConfig(numRuns: 100),
  ).test(
    'isValidNumericValue accepts valid numeric strings (integers and decimals)',
    (String numericStr) {
      expect(
        isValidNumericValue(numericStr),
        isTrue,
        reason: '"$numericStr" should be accepted as a valid numeric value',
      );
    },
  );

  Glados(
    _nonNumericGen,
    ExploreConfig(numRuns: 100),
  ).test(
    'isValidNumericValue rejects non-numeric strings',
    (String nonNumeric) {
      expect(
        isValidNumericValue(nonNumeric),
        isFalse,
        reason: '"$nonNumeric" should be rejected as a non-numeric value',
      );
    },
  );
}

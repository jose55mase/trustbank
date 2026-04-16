// Feature: delivery-app, Property 15: Contraste de tema cumple accesibilidad
// **Validates: Requirements 11.2**
//
// For any text/background color pair defined in the theme,
// the contrast ratio must be >= 4.5:1 (WCAG AA).

import 'package:delivery_app/core/theme/app_theme.dart';
import 'package:glados/glados.dart';

extension ThemeColorPairGenerator on Any {
  /// Generates an index into [AppTheme.textBackgroundPairs].
  Generator<int> get colorPairIndex =>
      intInRange(0, AppTheme.textBackgroundPairs.length - 1);
}

void main() {
  Glados(any.colorPairIndex, ExploreConfig(numRuns: 100)).test(
    'Property 15: All theme text/background pairs have contrast ratio >= 4.5:1',
    (index) {
      final pair = AppTheme.textBackgroundPairs[index];
      final foreground = pair.$1;
      final background = pair.$2;
      final label = pair.$3;

      final ratio = AppTheme.contrastRatio(foreground, background);

      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason:
            '$label: contrast ratio ${ratio.toStringAsFixed(2)} is below 4.5:1',
      );
    },
  );
}

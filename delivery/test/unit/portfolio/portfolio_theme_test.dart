import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_app/portfolio/theme/portfolio_theme.dart';

void main() {
  group('PortfolioTheme - Color Constants', () {
    test('primaryBlue has correct HSL values (H:210, S:40%, L:75%)', () {
      final hsl = HSLColor.fromColor(PortfolioTheme.primaryBlue);
      expect(hsl.hue, closeTo(210, 1));
      expect(hsl.saturation, closeTo(0.40, 0.01));
      expect(hsl.lightness, closeTo(0.75, 0.01));
    });

    test('secondaryOrange has correct HSL values (H:25, S:45%, L:75%)', () {
      final hsl = HSLColor.fromColor(PortfolioTheme.secondaryOrange);
      expect(hsl.hue, closeTo(25, 1));
      expect(hsl.saturation, closeTo(0.45, 0.01));
      expect(hsl.lightness, closeTo(0.75, 0.01));
    });

    test('accentBlack has correct HSL values (H:0, S:2%, L:20%)', () {
      final hsl = HSLColor.fromColor(PortfolioTheme.accentBlack);
      expect(hsl.hue, closeTo(0, 1));
      expect(hsl.saturation, closeTo(0.02, 0.01));
      expect(hsl.lightness, closeTo(0.20, 0.01));
    });

    test('primaryBlue is within requirement range (H:205-215, S:35-45%, L:70-80%)', () {
      final hsl = HSLColor.fromColor(PortfolioTheme.primaryBlue);
      expect(hsl.hue, inInclusiveRange(205, 215));
      expect(hsl.saturation, inInclusiveRange(0.35, 0.45));
      expect(hsl.lightness, inInclusiveRange(0.70, 0.80));
    });

    test('secondaryOrange is within requirement range (H:20-30, S:40-50%, L:70-80%)', () {
      final hsl = HSLColor.fromColor(PortfolioTheme.secondaryOrange);
      expect(hsl.hue, inInclusiveRange(20, 30));
      expect(hsl.saturation, inInclusiveRange(0.40, 0.50));
      expect(hsl.lightness, inInclusiveRange(0.70, 0.80));
    });

    test('accentBlack is within requirement range (H:0-360, S:0-5%, L:15-25%)', () {
      final hsl = HSLColor.fromColor(PortfolioTheme.accentBlack);
      expect(hsl.hue, inInclusiveRange(0, 360));
      expect(hsl.saturation, inInclusiveRange(0.0, 0.05));
      expect(hsl.lightness, inInclusiveRange(0.15, 0.25));
    });
  });

  group('PortfolioTheme - WCAG Contrast', () {
    test('all textBackgroundPairs meet WCAG AA 4.5:1 for standard text', () {
      for (final (fg, bg, label) in PortfolioTheme.textBackgroundPairs) {
        final ratio = PortfolioTheme.contrastRatio(fg, bg);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '$label has contrast ratio $ratio (need >= 4.5:1)',
        );
      }
    });

    test('relativeLuminance returns 0 for black and 1 for white', () {
      expect(
        PortfolioTheme.relativeLuminance(Colors.black),
        closeTo(0.0, 0.001),
      );
      expect(
        PortfolioTheme.relativeLuminance(Colors.white),
        closeTo(1.0, 0.001),
      );
    });

    test('contrastRatio of black on white is 21:1', () {
      final ratio = PortfolioTheme.contrastRatio(Colors.black, Colors.white);
      expect(ratio, closeTo(21.0, 0.1));
    });

    test('contrastRatio is symmetric', () {
      final ratio1 = PortfolioTheme.contrastRatio(
        PortfolioTheme.primaryBlue,
        PortfolioTheme.accentBlack,
      );
      final ratio2 = PortfolioTheme.contrastRatio(
        PortfolioTheme.accentBlack,
        PortfolioTheme.primaryBlue,
      );
      expect(ratio1, closeTo(ratio2, 0.001));
    });
  });

  group('PortfolioTheme - ensureContrast', () {
    test('returns foreground when contrast is sufficient', () {
      // accentBlack on white background should easily pass
      final result = PortfolioTheme.ensureContrast(
        foreground: PortfolioTheme.accentBlack,
        background: Colors.white,
      );
      expect(result, equals(PortfolioTheme.accentBlack));
    });

    test('falls back to accentBlack when contrast is insufficient for standard text', () {
      // A light color on a light background won't meet 4.5:1
      final lightColor = HSLColor.fromAHSL(1.0, 210, 0.30, 0.85).toColor();
      final lightBg = HSLColor.fromAHSL(1.0, 210, 0.20, 0.95).toColor();

      final result = PortfolioTheme.ensureContrast(
        foreground: lightColor,
        background: lightBg,
      );
      expect(result, equals(PortfolioTheme.accentBlack));
    });

    test('uses lower threshold (3:1) for large text', () {
      // Find a color that passes 3:1 but not 4.5:1 against background
      final mediumColor = HSLColor.fromAHSL(1.0, 210, 0.40, 0.55).toColor();
      final bg = PortfolioTheme.background;

      final ratioWithBg = PortfolioTheme.contrastRatio(mediumColor, bg);

      if (ratioWithBg >= 3.0 && ratioWithBg < 4.5) {
        // Should pass for large text
        final resultLarge = PortfolioTheme.ensureContrast(
          foreground: mediumColor,
          background: bg,
          isLargeText: true,
        );
        expect(resultLarge, equals(mediumColor));

        // Should fail for standard text
        final resultStandard = PortfolioTheme.ensureContrast(
          foreground: mediumColor,
          background: bg,
          isLargeText: false,
        );
        expect(resultStandard, equals(PortfolioTheme.accentBlack));
      }
    });
  });

  group('PortfolioTheme - ThemeData', () {
    test('lightTheme uses Material 3', () {
      final theme = PortfolioTheme.lightTheme;
      expect(theme.useMaterial3, isTrue);
    });

    test('lightTheme has light brightness', () {
      final theme = PortfolioTheme.lightTheme;
      expect(theme.brightness, equals(Brightness.light));
    });

    test('lightTheme colorScheme uses primary blue', () {
      final theme = PortfolioTheme.lightTheme;
      expect(theme.colorScheme.primary, equals(PortfolioTheme.primaryBlue));
    });

    test('lightTheme colorScheme uses secondary orange', () {
      final theme = PortfolioTheme.lightTheme;
      expect(theme.colorScheme.secondary, equals(PortfolioTheme.secondaryOrange));
    });

    test('lightTheme colorScheme uses accent black for onPrimary', () {
      final theme = PortfolioTheme.lightTheme;
      expect(theme.colorScheme.onPrimary, equals(PortfolioTheme.accentBlack));
    });

    test('lightTheme text styles use colors derived from palette', () {
      final theme = PortfolioTheme.lightTheme;
      expect(theme.textTheme.headlineLarge?.color, equals(PortfolioTheme.textPrimary));
      expect(theme.textTheme.bodyMedium?.color, equals(PortfolioTheme.textSecondary));
      expect(theme.textTheme.bodySmall?.color, equals(PortfolioTheme.textHint));
    });

    test('lightTheme elevated button uses primary blue background', () {
      final theme = PortfolioTheme.lightTheme;
      final style = theme.elevatedButtonTheme.style;
      final bgColor = style?.backgroundColor?.resolve({});
      expect(bgColor, equals(PortfolioTheme.primaryBlue));
    });

    test('lightTheme FAB uses secondary orange', () {
      final theme = PortfolioTheme.lightTheme;
      expect(
        theme.floatingActionButtonTheme.backgroundColor,
        equals(PortfolioTheme.secondaryOrange),
      );
    });
  });
}

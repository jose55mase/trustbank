import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Pastel-toned theme for the Portfolio module.
///
/// Color roles:
/// - Primary: soft blue pastel (H:210, S:40%, L:75%)
/// - Secondary: soft orange pastel (H:25, S:45%, L:75%)
/// - Accent: softened black (H:0, S:2%, L:20%)
///
/// All text/background combinations meet WCAG 2.1 Level AA contrast:
/// - ≥ 4.5:1 for standard text (< 18pt)
/// - ≥ 3:1 for large text (≥ 18pt)
///
/// Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6
class PortfolioTheme {
  PortfolioTheme._();

  // ── HSL-based color constants ────────────────────────────────────

  /// Primary blue: HSL(210, 40%, 75%)
  static final Color primaryBlue = HSLColor.fromAHSL(1.0, 210, 0.40, 0.75).toColor();

  /// Secondary orange: HSL(25, 45%, 75%)
  static final Color secondaryOrange = HSLColor.fromAHSL(1.0, 25, 0.45, 0.75).toColor();

  /// Accent black: HSL(0, 2%, 20%)
  static final Color accentBlack = HSLColor.fromAHSL(1.0, 0, 0.02, 0.20).toColor();

  // ── Derived surface colors ───────────────────────────────────────

  /// Light background derived from primary blue at high lightness
  static final Color background = HSLColor.fromAHSL(1.0, 210, 0.30, 0.97).toColor();

  /// Surface color — slightly tinted white
  static final Color surface = HSLColor.fromAHSL(1.0, 210, 0.20, 0.95).toColor();

  /// Surface variant — subtle blue tint for cards
  static final Color surfaceVariant = HSLColor.fromAHSL(1.0, 210, 0.25, 0.92).toColor();

  /// Card background
  static final Color cardColor = HSLColor.fromAHSL(1.0, 210, 0.15, 0.98).toColor();

  // ── Text colors ──────────────────────────────────────────────────

  /// Primary text — uses accent black for maximum readability
  static final Color textPrimary = accentBlack;

  /// Secondary text — slightly lighter than accent
  static final Color textSecondary = HSLColor.fromAHSL(1.0, 0, 0.02, 0.35).toColor();

  /// Hint text — lighter still, meets 4.5:1 on light backgrounds
  static final Color textHint = HSLColor.fromAHSL(1.0, 0, 0.02, 0.40).toColor();

  // ── State colors ─────────────────────────────────────────────────

  /// Error color — muted red
  static final Color error = HSLColor.fromAHSL(1.0, 0, 0.50, 0.45).toColor();

  /// Success color — muted green
  static final Color success = HSLColor.fromAHSL(1.0, 120, 0.35, 0.40).toColor();

  /// Warning color — muted amber
  static final Color warning = HSLColor.fromAHSL(1.0, 35, 0.60, 0.50).toColor();

  // ── Dividers / Borders ───────────────────────────────────────────

  /// Divider color
  static final Color divider = HSLColor.fromAHSL(1.0, 210, 0.15, 0.85).toColor();

  // ── WCAG Contrast Constants ──────────────────────────────────────

  /// Minimum contrast ratio for standard text (< 18pt) per WCAG AA
  static const double minContrastStandard = 4.5;

  /// Minimum contrast ratio for large text (≥ 18pt) per WCAG AA
  static const double minContrastLarge = 3.0;

  /// All text/background color pairs used in the theme.
  /// Each entry is (foreground, background, label).
  /// Used by property tests to verify contrast compliance.
  static List<(Color, Color, String)> get textBackgroundPairs => [
        (textPrimary, background, 'textPrimary on background'),
        (textPrimary, surface, 'textPrimary on surface'),
        (textPrimary, surfaceVariant, 'textPrimary on surfaceVariant'),
        (textPrimary, cardColor, 'textPrimary on cardColor'),
        (textSecondary, background, 'textSecondary on background'),
        (textSecondary, surface, 'textSecondary on surface'),
        (textSecondary, surfaceVariant, 'textSecondary on surfaceVariant'),
        (textHint, background, 'textHint on background'),
        (textHint, surface, 'textHint on surface'),
        (accentBlack, primaryBlue, 'accentBlack on primaryBlue'),
        (accentBlack, secondaryOrange, 'accentBlack on secondaryOrange'),
      ];

  // ── Contrast Checking Utility ────────────────────────────────────

  /// Returns [foreground] if it meets the required WCAG AA contrast ratio
  /// against [background], otherwise returns [accentBlack] as a fallback.
  ///
  /// [isLargeText] should be true for text ≥ 18pt (or bold ≥ 14pt).
  ///
  /// Requirements: 7.5, 7.6
  static Color ensureContrast({
    required Color foreground,
    required Color background,
    bool isLargeText = false,
  }) {
    final minRatio = isLargeText ? minContrastLarge : minContrastStandard;
    final ratio = contrastRatio(foreground, background);
    if (ratio >= minRatio) {
      return foreground;
    }
    return accentBlack;
  }

  // ── WCAG Luminance & Contrast ────────────────────────────────────

  /// Computes the WCAG relative luminance of a [Color].
  static double relativeLuminance(Color color) {
    double linearize(int channel) {
      final s = channel / 255.0;
      return s <= 0.03928
          ? s / 12.92
          : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * linearize(color.red) +
        0.7152 * linearize(color.green) +
        0.0722 * linearize(color.blue);
  }

  /// Computes the WCAG contrast ratio between two colors.
  /// Returns a value >= 1.0 (higher is better).
  static double contrastRatio(Color foreground, Color background) {
    final lumFg = relativeLuminance(foreground);
    final lumBg = relativeLuminance(background);
    final lighter = lumFg > lumBg ? lumFg : lumBg;
    final darker = lumFg > lumBg ? lumBg : lumFg;
    return (lighter + 0.05) / (darker + 0.05);
  }

  // ── Theme Data ───────────────────────────────────────────────────

  /// Material 3 light theme for the portfolio module.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.light(
        primary: primaryBlue,
        onPrimary: accentBlack,
        secondary: secondaryOrange,
        onSecondary: accentBlack,
        surface: surface,
        onSurface: textPrimary,
        error: error,
        onError: Colors.white,
        surfaceContainerHighest: surfaceVariant,
      ),

      // ── AppBar ─────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── Text ───────────────────────────────────────────────────
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
        bodySmall: TextStyle(color: textHint, fontSize: 12),
        labelLarge: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── Elevated Button ────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: accentBlack,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Outlined Button ────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentBlack,
          side: BorderSide(color: primaryBlue),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // ── Text Button ────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentBlack,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Card ───────────────────────────────────────────────────
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // ── Input Decoration ───────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        hintStyle: TextStyle(color: textHint),
        labelStyle: TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // ── Bottom Navigation ──────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 4,
      ),

      // ── Tab Bar ────────────────────────────────────────────────
      tabBarTheme: TabBarTheme(
        labelColor: accentBlack,
        unselectedLabelColor: textSecondary,
        indicatorColor: primaryBlue,
      ),

      // ── Floating Action Button ─────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondaryOrange,
        foregroundColor: accentBlack,
      ),

      // ── Divider ────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 1,
      ),

      // ── Snackbar ───────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: accentBlack,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Icon ───────────────────────────────────────────────────
      iconTheme: IconThemeData(
        color: accentBlack,
        size: 24,
      ),
    );
  }
}

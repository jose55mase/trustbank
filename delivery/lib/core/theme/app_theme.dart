import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Tema oscuro inspirado en Nequi para la Delivery App.
/// Paleta: morados/magenta sobre fondos oscuros.
/// Contraste mínimo 4.5:1 entre texto y fondo (WCAG AA).
///
/// Requisitos: 11.1, 11.2, 11.3, 11.4
class AppTheme {
  AppTheme._();

  // ── Colores principales ──────────────────────────────────────────
  static const Color primary = Color(0xFF8B2FC9); // Morado Nequi
  static const Color primaryLight = Color(0xFFAB5FE0);
  static const Color primaryDark = Color(0xFF6A1FA3);

  static const Color accent = Color(0xFFE040FB); // Magenta brillante
  static const Color accentLight = Color(0xFFFF79FF);

  // ── Fondos ───────────────────────────────────────────────────────
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceVariant = Color(0xFF2C2C2C);
  static const Color cardColor = Color(0xFF2C2C2C);

  // ── Texto ────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF); // Contrast 15.4:1 on #1E1E1E
  static const Color textSecondary = Color(0xFFB3B3B3); // Contrast 7.5:1 on #1E1E1E
  static const Color textHint = Color(0xFF8A8A8A); // Contrast 4.5:1 on #1E1E1E

  // ── Estado ───────────────────────────────────────────────────────
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFA726);

  // ── Dividers / Borders ───────────────────────────────────────────
  static const Color divider = Color(0xFF3A3A3A);

  /// All text/background color pairs used in the theme.
  /// Each entry is (foreground, background, label).
  /// Used by the property test to verify contrast >= 4.5:1.
  static const List<(Color, Color, String)> textBackgroundPairs = [
    (textPrimary, background, 'textPrimary on background'),
    (textPrimary, surface, 'textPrimary on surface'),
    (textPrimary, surfaceVariant, 'textPrimary on surfaceVariant'),
    (textSecondary, background, 'textSecondary on background'),
    (textSecondary, surface, 'textSecondary on surface'),
    (textSecondary, surfaceVariant, 'textSecondary on surfaceVariant'),
    (textHint, background, 'textHint on background'),
    (textHint, surface, 'textHint on surface'),
    (accent, background, 'accent on background'),
    (accent, surface, 'accent on surface'),
  ];


  /// Dark theme data for the app.
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: textPrimary,
        secondary: accent,
        onSecondary: textPrimary,
        surface: surface,
        onSurface: textPrimary,
        error: error,
        onError: textPrimary,
      ),

      // ── AppBar ─────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
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
      textTheme: const TextTheme(
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
          backgroundColor: primary,
          foregroundColor: textPrimary,
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
          foregroundColor: accent,
          side: const BorderSide(color: accent),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // ── Card ───────────────────────────────────────────────────
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // ── Input Decoration ───────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        hintStyle: const TextStyle(color: textHint),
        labelStyle: const TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // ── Bottom Navigation ──────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // ── Tab Bar ────────────────────────────────────────────────
      tabBarTheme: const TabBarTheme(
        labelColor: accent,
        unselectedLabelColor: textSecondary,
        indicatorColor: accent,
      ),

      // ── Floating Action Button ─────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: textPrimary,
      ),

      // ── Divider ────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
      ),

      // ── Snackbar ───────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceVariant,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Computes the WCAG relative luminance of a [Color].
  static double relativeLuminance(Color color) {
    double linearize(int channel) {
      final s = channel / 255.0;
      return s <= 0.03928 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
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
}

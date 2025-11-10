import 'package:flutter/material.dart';

class TBColors {
  // Primary Colors - Inspirado en Nequi pero con identidad propia
  static const Color primary = Color(0xFF6C63FF); // Violeta vibrante
  static const Color primaryLight = Color(0xFF9C96FF);
  static const Color primaryDark = Color(0xFF4A42CC);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF00D4AA); // Verde menta
  static const Color secondaryLight = Color(0xFF4DFFCD);
  static const Color secondaryDark = Color(0xFF00A085);
  
  // Accent Colors
  static const Color accent = Color(0xFFFF6B6B); // Coral
  static const Color accentLight = Color(0xFFFF9999);
  static const Color accentDark = Color(0xFFCC5555);
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF1A1A1A);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Background Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
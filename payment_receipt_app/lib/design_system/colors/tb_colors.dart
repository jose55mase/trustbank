import 'package:flutter/material.dart';

class TBColors {
  // Primary Colors - Estilo Nequi con toque auténtico
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9C96FF);
  static const Color primaryDark = Color(0xFF4A42CC);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF00D4AA);
  static const Color secondaryLight = Color(0xFF4DFFCD);
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF1A1A1A);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  
  // Background Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
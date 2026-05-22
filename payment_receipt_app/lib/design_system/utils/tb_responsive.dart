import 'package:flutter/material.dart';

/// Utilidad para manejar tamaños responsivos según el ancho de pantalla.
class TBResponsive {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Determina si es mobile
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  /// Determina si es tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  /// Determina si es desktop/web
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  /// Retorna un valor según el tamaño de pantalla
  static T value<T>(BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) return desktop ?? tablet ?? mobile;
    if (width >= mobileBreakpoint) return tablet ?? mobile;
    return mobile;
  }

  /// Tamaño de icono responsivo
  static double iconSize(BuildContext context) {
    return value(context, mobile: 24.0, tablet: 32.0, desktop: 36.0);
  }

  /// Tamaño del contenedor de icono responsivo
  static double iconContainerSize(BuildContext context) {
    return value(context, mobile: 48.0, tablet: 64.0, desktop: 72.0);
  }

  /// Columnas del grid de acciones
  static int actionGridColumns(BuildContext context) {
    return value(context, mobile: 4, tablet: 5, desktop: 6);
  }

  /// Aspect ratio del grid de acciones
  static double actionGridAspectRatio(BuildContext context) {
    return value(context, mobile: 0.8, tablet: 0.9, desktop: 1.0);
  }

  /// Tamaño de icono para transacciones
  static double transactionIconSize(BuildContext context) {
    return value(context, mobile: 16.0, tablet: 22.0, desktop: 24.0);
  }

  /// Contenedor de icono para transacciones
  static double transactionIconContainerSize(BuildContext context) {
    return value(context, mobile: 32.0, tablet: 44.0, desktop: 48.0);
  }

  /// Padding de pantalla responsivo
  static double screenPadding(BuildContext context) {
    return value(context, mobile: 16.0, tablet: 24.0, desktop: 32.0);
  }

  /// Ancho máximo del contenido (para centrar en pantallas grandes)
  static double maxContentWidth(BuildContext context) {
    return value(context, mobile: double.infinity, tablet: 768.0, desktop: 1024.0);
  }
}

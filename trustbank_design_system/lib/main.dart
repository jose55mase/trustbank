import 'package:flutter/material.dart';
import 'design_system/colors/tb_colors.dart';
import 'design_system/typography/tb_typography.dart';
import 'screens/design_system_showcase.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrustBank Design System',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: TBColors.primary,
          brightness: Brightness.light,
        ),
        textTheme: TextTheme(
          displayLarge: TBTypography.displayLarge,
          displayMedium: TBTypography.displayMedium,
          displaySmall: TBTypography.displaySmall,
          headlineLarge: TBTypography.headlineLarge,
          headlineMedium: TBTypography.headlineMedium,
          headlineSmall: TBTypography.headlineSmall,
          titleLarge: TBTypography.titleLarge,
          titleMedium: TBTypography.titleMedium,
          titleSmall: TBTypography.titleSmall,
          bodyLarge: TBTypography.bodyLarge,
          bodyMedium: TBTypography.bodyMedium,
          bodySmall: TBTypography.bodySmall,
          labelLarge: TBTypography.labelLarge,
          labelMedium: TBTypography.labelMedium,
          labelSmall: TBTypography.labelSmall,
        ),
        scaffoldBackgroundColor: TBColors.background,
        appBarTheme: AppBarTheme(
          backgroundColor: TBColors.primary,
          foregroundColor: TBColors.white,
          elevation: 0,
        ),
      ),
      home: const DesignSystemShowcase(),
      debugShowCheckedModeBanner: false,
    );
  }
}
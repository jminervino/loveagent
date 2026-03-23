import 'package:flutter/material.dart';

abstract class AppColors {
  // Primary
  static const Color primary = Color(0xFFC6BFFF);
  static const Color primaryContainer = Color(0xFF4F3CC9);
  static const Color onPrimary = Color(0xFF2900A0);
  static const Color onPrimaryContainer = Color(0xFFCBC4FF);

  // Secondary
  static const Color secondary = Color(0xFFFFB95F);
  static const Color secondaryContainer = Color(0xFFEE9800);
  static const Color onSecondary = Color(0xFF472A00);

  // Tertiary
  static const Color tertiary = Color(0xFFF9BD22);
  static const Color tertiaryContainer = Color(0xFF6E5100);
  static const Color onTertiaryContainer = Color(0xFFFEC227);

  // Surfaces
  static const Color background = Color(0xFF111125);
  static const Color surface = Color(0xFF111125);
  static const Color surfaceContainerLowest = Color(0xFF0C0C1F);
  static const Color surfaceContainerLow = Color(0xFF1A1A2E);
  static const Color surfaceContainer = Color(0xFF1E1E32);
  static const Color surfaceContainerHigh = Color(0xFF28283D);
  static const Color surfaceContainerHighest = Color(0xFF333348);
  static const Color surfaceBright = Color(0xFF37374D);

  // On surfaces
  static const Color onBackground = Color(0xFFE2E0FC);
  static const Color onSurface = Color(0xFFE2E0FC);
  static const Color onSurfaceVariant = Color(0xFFC8C4D7);

  // Outline
  static const Color outline = Color(0xFF928FA0);
  static const Color outlineVariant = Color(0xFF474554);

  // Error
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);

  // Inverse
  static const Color inverseSurface = Color(0xFFE2E0FC);
  static const Color inverseOnSurface = Color(0xFF2F2E43);
  static const Color inversePrimary = Color(0xFF5847D2);

  // Semantic aliases (backward compat)
  static const Color accent = Color(0xFFF9BD22);
  static const Color success = Color(0xFF00B894);
  static const Color textPrimary = Color(0xFFE2E0FC);
  static const Color textSecondary = Color(0xFF928FA0);
  static const Color divider = Color(0xFF474554);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryContainer, onPrimary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient warmGlow = LinearGradient(
    colors: [Color(0x14F9BD22), Color(0x00111125)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );
}

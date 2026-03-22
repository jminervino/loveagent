import 'package:flutter/material.dart';

abstract class AppColors {
  static const Color primary = Color(0xFF6C5CE7);
  static const Color secondary = Color(0xFFA29BFE);
  static const Color accent = Color(0xFFE17055);
  static const Color background = Color(0xFFF8F7FF);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFD63031);
  static const Color success = Color(0xFF00B894);
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color divider = Color(0xFFDFE6E9);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core
  static const Color background = Color(0xFF0D0D0F);
  static const Color surface = Color(0xFF1A1A1F);
  static const Color surfaceLight = Color(0xFF242429);
  static const Color card = Color(0xFF1E1E24);
  static const Color border = Color(0xFF2A2A32);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9EA7);
  static const Color textHint = Color(0xFF5C5C66);

  // Accent — purple gradient
  static const Color accent = Color(0xFF7C3AED);
  static const Color accentLight = Color(0xFF9F67FF);
  static const Color accentDark = Color(0xFF5B21B6);
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentDark, accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF6D28D9), Color(0xFF7C3AED), Color(0xFF8B5CF6)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Misc
  static const Color divider = Color(0xFF222228);
  static const Color inputFill = Color(0xFF16161B);
  static const Color inputBorder = Color(0xFF2E2E36);
  static const Color shadow = Color(0x33000000);
}

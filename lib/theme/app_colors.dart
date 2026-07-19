import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF12121A);
  static const Color surfaceLight = Color(0xFF1C1C26);
  static const Color card = Color(0xFF16161F);
  static const Color border = Color(0xFF23233A);
  static const Color borderLight = Color(0xFF1A1A2E);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E9E);
  static const Color textHint = Color(0xFF4A4A5A);

  static const Color accent = Color(0xFF7C5CFC);
  static const Color accentLight = Color(0xFF9B7DFF);
  static const Color accentDark = Color(0xFF5A3FD6);
  static const Color accentGlow = Color(0x407C5CFC);

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF6C4DE6), Color(0xFF7C5CFC), Color(0xFF9B7DFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF5A3FD6), Color(0xFF7C5CFC), Color(0xFF9B7DFF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF16161F), Color(0xFF1A1A28)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color success = Color(0xFF2DD4A8);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF38BDF8);

  static const Color divider = Color(0xFF1E1E30);
  static const Color inputFill = Color(0xFF111119);
  static const Color inputBorder = Color(0xFF252538);
}

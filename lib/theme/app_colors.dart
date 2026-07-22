import 'package:flutter/material.dart';

class AppColors {
  final Color background;
  final Color surface;
  final Color surfaceLight;
  final Color card;
  final Color border;
  final Color borderLight;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color accent;
  final Color accentLight;
  final Color accentDark;
  final Color gold;
  final Color goldLight;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color divider;
  final Color inputFill;
  final Color inputBorder;
  final Color skeletonBase;
  final Color skeletonShimmer;
  final Color paper;
  final Color paperDark;
  final Color muted;
  final Color inkSoft;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.card,
    required this.border,
    required this.borderLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    required this.gold,
    required this.goldLight,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.divider,
    required this.inputFill,
    required this.inputBorder,
    required this.skeletonBase,
    required this.skeletonShimmer,
    required this.paper,
    required this.paperDark,
    required this.muted,
    required this.inkSoft,
  });

  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  static const light = AppColors(
    background: Color(0xFFFAF8F5),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFF7F5F2),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE5E3DF),
    borderLight: Color(0xFFEDEAE6),
    textPrimary: Color(0xFF1B1B1F),
    textSecondary: Color(0xFF6B7280),
    textHint: Color(0xFF9CA3AF),
    accent: Color(0xFF2358FF),
    accentLight: Color(0xFF4A6FFF),
    accentDark: Color(0xFF1A4AE0),
    gold: Color(0xFFC9A76A),
    goldLight: Color(0xFFD4BA85),
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    error: Color(0xFFDC2626),
    info: Color(0xFF0284C7),
    divider: Color(0xFFEDEAE6),
    inputFill: Color(0xFFF7F5F2),
    inputBorder: Color(0xFFE5E3DF),
    skeletonBase: Color(0xFFEDEAE6),
    skeletonShimmer: Color(0xFFFAF8F5),
    paper: Color(0xFFF7F5F2),
    paperDark: Color(0xFFEDEAE5),
    muted: Color(0xFFE8E5E0),
    inkSoft: Color(0xFF374151),
  );

  static const dark = AppColors(
    background: Color(0xFF0F1115),
    surface: Color(0xFF1A1D24),
    surfaceLight: Color(0xFF242830),
    card: Color(0xFF1A1D24),
    border: Color(0xFF2D3139),
    borderLight: Color(0xFF242830),
    textPrimary: Color(0xFFF0F0F5),
    textSecondary: Color(0xFF9CA3B0),
    textHint: Color(0xFF5E6470),
    accent: Color(0xFF5B8AFF),
    accentLight: Color(0xFF7BA3FF),
    accentDark: Color(0xFF4A6FFF),
    gold: Color(0xFFD4BA85),
    goldLight: Color(0xFFE0CCA0),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFF87171),
    info: Color(0xFF38BDF8),
    divider: Color(0xFF2D3139),
    inputFill: Color(0xFF242830),
    inputBorder: Color(0xFF2D3139),
    skeletonBase: Color(0xFF242830),
    skeletonShimmer: Color(0xFF2D3139),
    paper: Color(0xFF1A1D24),
    paperDark: Color(0xFF14161A),
    muted: Color(0xFF2D3139),
    inkSoft: Color(0xFFB0B8C8),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

/// Анимированное пустое состояние: иконка «выпрыгивает» с упругой
/// анимацией, затем мягко пульсирует; текст появляется следом.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final double iconSize;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconSize = 56,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: iconSize * 1.9,
            height: iconSize * 1.9,
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: iconSize, color: c.accent.withValues(alpha: 0.55)),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.07, 1.07),
                duration: 1600.ms,
                curve: Curves.easeInOut,
              )
              .then()
              .animate()
              .scale(
                begin: const Offset(0.5, 0.5),
                duration: 600.ms,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ).animate(delay: 250.ms).fadeIn(duration: 400.ms),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.textHint),
            ).animate(delay: 350.ms).fadeIn(duration: 400.ms),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum BadgeStatus { pending, inProgress, completed, rejected }

class StatusBadge extends StatelessWidget {
  final BadgeStatus status;
  final String label;
  final bool small;

  const StatusBadge({
    super.key,
    required this.status,
    required this.label,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = switch (status) {
      BadgeStatus.pending => c.warning,
      BadgeStatus.inProgress => c.info,
      BadgeStatus.completed => c.success,
      BadgeStatus.rejected => c.error,
    };

    // Цвет плавно перетекает при смене статуса; текст появляется с «попом».
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Text(
          label,
          key: ValueKey(label),
          style: TextStyle(
            fontSize: small ? 11 : 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

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
    final color = switch (status) {
      BadgeStatus.pending => AppColors.warning,
      BadgeStatus.inProgress => AppColors.info,
      BadgeStatus.completed => AppColors.success,
      BadgeStatus.rejected => AppColors.error,
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: small ? 11 : 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

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
    final (color, bgColor) = switch (status) {
      BadgeStatus.pending => (const Color(0xFFFBBF24), const Color(0x20FBBF24)),
      BadgeStatus.inProgress => (const Color(0xFF38BDF8), const Color(0x2038BDF8)),
      BadgeStatus.completed => (const Color(0xFF2DD4A8), const Color(0x202DD4A8)),
      BadgeStatus.rejected => (const Color(0xFFEF4444), const Color(0x20EF4444)),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
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

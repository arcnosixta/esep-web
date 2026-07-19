import 'package:flutter/material.dart';

enum BadgeStatus { pending, inProgress, completed, rejected }

class StatusBadge extends StatelessWidget {
  final BadgeStatus status;
  final String label;

  const StatusBadge({
    super.key,
    required this.status,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final (color, bgColor) = switch (status) {
      BadgeStatus.pending => (const Color(0xFFF59E0B), const Color(0x20F59E0B)),
      BadgeStatus.inProgress => (const Color(0xFF3B82F6), const Color(0x203B82F6)),
      BadgeStatus.completed => (const Color(0xFF22C55E), const Color(0x2022C55E)),
      BadgeStatus.rejected => (const Color(0xFFEF4444), const Color(0x20EF4444)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

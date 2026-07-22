import 'package:flutter/material.dart';
import '../widgets/status_badge.dart';

String statusLabel(String status) => switch (status) {
      'new' => 'Новая',
      'in_progress' => 'В работе',
      'completed' => 'Завершена',
      'rejected' => 'Отклонена',
      'paid' => 'Оплачена',
      _ => status,
    };

String propertyTypeLabel(String type) => switch (type) {
      'apartment' => 'Квартира',
      'house' => 'Дом',
      'land' => 'Участок',
      'commercial' => 'Коммерческая',
      _ => type,
    };

IconData propertyTypeIcon(String type) => switch (type) {
      'apartment' => Icons.apartment_rounded,
      'house' => Icons.home_rounded,
      'land' => Icons.landscape_rounded,
      'commercial' => Icons.business_rounded,
      _ => Icons.location_on_rounded,
    };

Color propertyTypeColor(String type) => switch (type) {
      'apartment' => const Color(0xFF2563EB),
      'house' => const Color(0xFF0284C7),
      'land' => const Color(0xFF16A34A),
      'commercial' => const Color(0xFFD97706),
      _ => const Color(0xFF6B7280),
    };

Widget infoRow(String label, String value, {bool highlight = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, color: AppColorsUtils.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            color: highlight
                ? AppColorsUtils.accent
                : AppColorsUtils.textPrimary,
          ),
        ),
      ],
    ),
  );
}

Widget divider() => Container(height: 1, color: AppColorsUtils.divider);

BadgeStatus badgeStatusFromKey(String status) => switch (status) {
      'new' => BadgeStatus.pending,
      'in_progress' => BadgeStatus.inProgress,
      'completed' => BadgeStatus.completed,
      'rejected' => BadgeStatus.rejected,
      _ => BadgeStatus.pending,
    };

class AppColorsUtils {
  AppColorsUtils._();
  static const Color accent = Color(0xFF2563EB);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color divider = Color(0xFFF0F0F3);
}

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
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
      'apartment' => AppColors.accent,
      'house' => AppColors.info,
      'land' => AppColors.success,
      'commercial' => AppColors.warning,
      _ => AppColors.textSecondary,
    };

Widget infoRow(String label, String value, {bool highlight = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            color: highlight ? AppColors.accent : AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}

Widget divider() => Container(height: 1, color: AppColors.divider);

BadgeStatus badgeStatusFromKey(String status) => switch (status) {
      'new' => BadgeStatus.pending,
      'in_progress' => BadgeStatus.inProgress,
      'completed' => BadgeStatus.completed,
      'rejected' => BadgeStatus.rejected,
      _ => BadgeStatus.pending,
    };

String greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Доброе утро';
  if (hour < 18) return 'Добрый день';
  return 'Добрый вечер';
}

String caseNumber(String id) {
  final short = id.length >= 4 ? id.substring(0, 4).toUpperCase() : id.toUpperCase();
  return 'Case №$short';
}

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/status_badge.dart';
import '../l10n/app_strings.dart';

String statusLabel(BuildContext context, String status) {
  final s = AppStrings.of(context);
  return switch (status) {
    'new' => s.statusNew,
    'pending_payment' => s.statusPendingPayment,
    'in_progress' => s.statusInProgress,
    'completed' => s.statusCompleted,
    'rejected' => s.statusRejected,
    'paid' => s.statusPaid,
    _ => status,
  };
}

String propertyTypeLabel(BuildContext context, String type) {
  final s = AppStrings.of(context);
  return switch (type) {
    'apartment' => s.propertyApartment,
    'house' => s.propertyHouse,
    'land' => s.propertyLand,
    'commercial' => s.propertyCommercial,
    _ => type,
  };
}

IconData propertyTypeIcon(String type) => switch (type) {
      'apartment' => Icons.apartment_rounded,
      'house' => Icons.home_rounded,
      'land' => Icons.landscape_rounded,
      'commercial' => Icons.business_rounded,
      _ => Icons.location_on_rounded,
    };

Color propertyTypeColor(BuildContext context, String type) {
  final c = AppColors.of(context);
  return switch (type) {
    'apartment' => c.accent,
    'house' => c.info,
    'land' => c.success,
    'commercial' => c.warning,
    _ => c.textSecondary,
  };
}

Widget infoRow(BuildContext context, String label, String value,
    {bool highlight = false}) {
  final c = AppColors.of(context);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: c.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            color: highlight ? c.accent : c.textPrimary,
          ),
        ),
      ],
    ),
  );
}

Widget divider(BuildContext context) {
  final c = AppColors.of(context);
  return Container(height: 1, color: c.divider);
}

BadgeStatus badgeStatusFromKey(String status) => switch (status) {
      'new' => BadgeStatus.pending,
      'pending_payment' => BadgeStatus.pending,
      'in_progress' => BadgeStatus.inProgress,
      'completed' => BadgeStatus.completed,
      'rejected' => BadgeStatus.rejected,
      _ => BadgeStatus.pending,
    };

String greeting(BuildContext context) {
  final s = AppStrings.of(context);
  final hour = DateTime.now().hour;
  if (hour < 12) return s.homeGreetingMorning;
  if (hour < 18) return s.homeGreetingAfternoon;
  return s.homeGreetingEvening;
}

String caseNumber(String id) {
  final short = id.length >= 4 ? id.substring(0, 4).toUpperCase() : id.toUpperCase();
  return 'Case №$short';
}

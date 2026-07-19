import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/primary_button.dart';
import '../navigation/app_navigator.dart';
import 'report_screen.dart';

class ApplicationCardScreen extends StatelessWidget {
  const ApplicationCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заявка №2847'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Статус заявки',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Создана 12 января 2026',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const StatusBadge(
                    status: BadgeStatus.inProgress,
                    label: 'В работе',
                  ),
                ],
              ),
            ),

            // Details
            const SizedBox(height: 4),
            const Text(
              'Детали объекта',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _infoRow('Тип', 'Квартира'),
                  _divider(),
                  _infoRow('Адрес', 'г. Алматы, ул. Абая 52'),
                  _divider(),
                  _infoRow('Площадь', '85 м²'),
                  _divider(),
                  _infoRow(
                    'Стоимость',
                    '42 500 000 ₸',
                    highlight: true,
                  ),
                ],
              ),
            ),

            // History
            const SizedBox(height: 20),
            const Text(
              'История статусов',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _statusStep(
                    title: 'Заявка создана',
                    time: '12 января, 10:30',
                    done: true,
                    isFirst: true,
                  ),
                  _statusStep(
                    title: 'Документы получены',
                    time: '12 января, 11:15',
                    done: true,
                  ),
                  _statusStep(
                    title: 'В работе у оценщика',
                    time: '13 января, 09:00',
                    done: true,
                  ),
                  _statusStep(
                    title: 'Ожидает оплаты',
                    done: false,
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Посмотреть отчёт',
              icon: Icons.description_rounded,
              onPressed: () =>
                  AppNavigator.push(context, const ReportScreen()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary)),
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

  Widget _divider() => Container(height: 0.5, color: AppColors.divider);

  Widget _statusStep({
    required String title,
    String? time,
    bool done = false,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: done ? AppColors.accentGradient : null,
                color: done ? null : AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: done
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.textHint,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
            ),
            if (!isLast)
              Container(
                width: 1.5,
                height: 32,
                color: done
                    ? AppColors.accent.withValues(alpha: 0.3)
                    : AppColors.divider,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color:
                        done ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                if (time != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textHint),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

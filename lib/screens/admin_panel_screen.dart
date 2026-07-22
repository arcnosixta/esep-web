import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/information_tile.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  static const _stats = [
    (label: 'Пользователи', value: '1 247', change: '+12.3%', positive: true),
    (label: 'Заявки', value: '834', change: '+8.7%', positive: true),
    (label: 'Оценщики', value: '23', change: '+2', positive: true),
    (label: 'Доход', value: '12.4M ₸', change: '+18.2%', positive: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'АДМИН-ПАНЕЛЬ',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Обзор статистики платформы',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: AppColors.paper,
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'СТАТИСТИКА',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        SizedBox(
                          width: 80,
                          child: InformationTile(
                            content: _stats[0].value,
                            name: _stats[0].label,
                            icon: Icons.people_rounded,
                            valueColor: AppColors.accent,
                            backgroundColor: AppColors.surface,
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 80,
                          child: InformationTile(
                            content: _stats[1].value,
                            name: _stats[1].label,
                            icon: Icons.description_rounded,
                            valueColor: AppColors.info,
                            backgroundColor: AppColors.surface,
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 80,
                          child: InformationTile(
                            content: _stats[2].value,
                            name: _stats[2].label,
                            icon: Icons.engineering_rounded,
                            valueColor: AppColors.success,
                            backgroundColor: AppColors.surface,
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 80,
                          child: InformationTile(
                            content: _stats[3].value,
                            name: _stats[3].label,
                            icon: Icons.payments_rounded,
                            valueColor: AppColors.warning,
                            backgroundColor: AppColors.surface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: AppColors.paper,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ГРАФИК АКТИВНОСТИ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: AppColors.muted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.muted, width: 1),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bar_chart_rounded,
                            size: 40,
                            color: AppColors.textSecondary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'fl_chart подключится позже',
                            style: TextStyle(fontSize: 12, color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

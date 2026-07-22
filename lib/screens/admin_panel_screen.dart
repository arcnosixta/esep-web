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
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: c.surface,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'АДМИН-ПАНЕЛЬ',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Обзор статистики платформы',
                    style: TextStyle(fontSize: 14, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: c.paper,
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'СТАТИСТИКА',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: c.textSecondary,
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
                            valueColor: c.accent,
                            backgroundColor: c.surface,
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 80,
                          child: InformationTile(
                            content: _stats[1].value,
                            name: _stats[1].label,
                            icon: Icons.description_rounded,
                            valueColor: c.info,
                            backgroundColor: c.surface,
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 80,
                          child: InformationTile(
                            content: _stats[2].value,
                            name: _stats[2].label,
                            icon: Icons.engineering_rounded,
                            valueColor: c.success,
                            backgroundColor: c.surface,
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 80,
                          child: InformationTile(
                            content: _stats[3].value,
                            name: _stats[3].label,
                            icon: Icons.payments_rounded,
                            valueColor: c.warning,
                            backgroundColor: c.surface,
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
              color: c.paper,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ГРАФИК АКТИВНОСТИ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: c.muted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: c.muted, width: 1),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bar_chart_rounded,
                            size: 40,
                            color: c.textSecondary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'fl_chart подключится позже',
                            style: TextStyle(fontSize: 12, color: c.textHint),
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

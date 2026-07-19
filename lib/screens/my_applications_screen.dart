import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_badge.dart';

class _ApplicationItem {
  final String number;
  final String type;
  final String area;
  final String date;
  final BadgeStatus status;
  final String statusLabel;

  const _ApplicationItem({
    required this.number,
    required this.type,
    required this.area,
    required this.date,
    required this.status,
    required this.statusLabel,
  });
}

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  int _filterIndex = 0;
  final _filters = ['Все', 'В работе', 'Завершённые'];

  static final List<_ApplicationItem> _applications = [
    const _ApplicationItem(
      number: '2847', type: 'Квартира', area: '85 м²',
      date: '12.01.2026', status: BadgeStatus.inProgress, statusLabel: 'В работе',
    ),
    const _ApplicationItem(
      number: '2831', type: 'Дом', area: '180 м²',
      date: '10.01.2026', status: BadgeStatus.completed, statusLabel: 'Завершён',
    ),
    const _ApplicationItem(
      number: '2819', type: 'Квартира', area: '62 м²',
      date: '08.01.2026', status: BadgeStatus.pending, statusLabel: 'Ожидание',
    ),
    const _ApplicationItem(
      number: '2805', type: 'Офис', area: '120 м²',
      date: '05.01.2026', status: BadgeStatus.completed, statusLabel: 'Завершён',
    ),
    const _ApplicationItem(
      number: '2798', type: 'Квартира', area: '94 м²',
      date: '03.01.2026', status: BadgeStatus.rejected, statusLabel: 'Отклонена',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'Мои заявки',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Filters
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final active = _filterIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _filterIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        gradient: active ? AppColors.buttonGradient : null,
                        color: active ? null : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: AppColors.accentGlow,
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _filters[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              active ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // List
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _applications.length,
                itemBuilder: (context, index) {
                  final app = _applications[index];
                  return GlassCard(
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '#${app.number}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    app.type,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  StatusBadge(
                                    status: app.status,
                                    label: app.statusLabel,
                                    small: true,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Text(
                                    app.area,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                  const Text('  ·  ',
                                      style:
                                          TextStyle(color: AppColors.textHint)),
                                  Text(
                                    app.date,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

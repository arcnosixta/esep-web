import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
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
      number: '2847',
      type: 'Квартира',
      area: '85 м²',
      date: '12.01.2026',
      status: BadgeStatus.inProgress,
      statusLabel: 'В работе',
    ),
    const _ApplicationItem(
      number: '2831',
      type: 'Дом',
      area: '180 м²',
      date: '10.01.2026',
      status: BadgeStatus.completed,
      statusLabel: 'Завершён',
    ),
    const _ApplicationItem(
      number: '2819',
      type: 'Квартира',
      area: '62 м²',
      date: '08.01.2026',
      status: BadgeStatus.pending,
      statusLabel: 'Ожидание',
    ),
    const _ApplicationItem(
      number: '2805',
      type: 'Офис',
      area: '120 м²',
      date: '05.01.2026',
      status: BadgeStatus.completed,
      statusLabel: 'Завершён',
    ),
    const _ApplicationItem(
      number: '2798',
      type: 'Квартира',
      area: '94 м²',
      date: '03.01.2026',
      status: BadgeStatus.rejected,
      statusLabel: 'Отклонена',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заявки'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: List.generate(_filters.length, (i) {
                final active = _filterIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _filterIndex = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: active ? AppColors.accent : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _filters[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: active
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _applications.length,
              itemBuilder: (context, index) {
                final app = _applications[index];
                return AppCard(
                  onTap: () {
                    // TODO: Open application card
                  },
                  child: Row(
                    children: [
                      // Number badge
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
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  app.area,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const Text(
                                  '  ·  ',
                                  style: TextStyle(
                                    color: AppColors.textHint,
                                  ),
                                ),
                                Text(
                                  app.date,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
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
    );
  }
}

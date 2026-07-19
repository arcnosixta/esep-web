import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class _StatCard {
  final String title;
  final String value;
  final String change;
  final bool positive;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.change,
    required this.positive,
    required this.icon,
    required this.color,
  });
}

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  static final List<_StatCard> _stats = const [
    _StatCard(
      title: 'Пользователи',
      value: '1 247',
      change: '+12.3%',
      positive: true,
      icon: Icons.people_rounded,
      color: Color(0xFF38BDF8),
    ),
    _StatCard(
      title: 'Заявки',
      value: '834',
      change: '+8.7%',
      positive: true,
      icon: Icons.description_rounded,
      color: Color(0xFF7C5CFC),
    ),
    _StatCard(
      title: 'Оценщики',
      value: '23',
      change: '+2',
      positive: true,
      icon: Icons.assignment_ind_rounded,
      color: Color(0xFF2DD4A8),
    ),
    _StatCard(
      title: 'Доход',
      value: '12.4M ₸',
      change: '+18.2%',
      positive: true,
      icon: Icons.payments_rounded,
      color: Color(0xFFFBBF24),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Админ-панель',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Обзор статистики платформы',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),

            // Stats grid
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.45,
                ),
                delegate: SliverChildListDelegate(
                  _stats.map((stat) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(18),
                        border:
                            Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: stat.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(stat.icon,
                                    color: stat.color, size: 18),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: stat.positive
                                      ? const Color(0x202DD4A8)
                                      : const Color(0x20EF4444),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  stat.change,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: stat.positive
                                        ? const Color(0xFF2DD4A8)
                                        : const Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stat.value,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                stat.title,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Chart placeholder
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              sliver: SliverToBoxAdapter(
                child: GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    height: 180,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bar_chart_rounded,
                            size: 48,
                            color: AppColors.accent.withValues(alpha: 0.25),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'График активности',
                            style: TextStyle(
                                fontSize: 14, color: AppColors.textHint),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'fl_chart подключится позже',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

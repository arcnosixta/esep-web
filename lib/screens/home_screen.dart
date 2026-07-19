import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_badge.dart';
import '../navigation/app_navigator.dart';
import 'payment_screen.dart';
import 'application_card_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ESEP',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Оценка недвижимости',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentGlow,
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Stats
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    _statCard('Заявки', '12', Icons.description_rounded,
                        const Color(0xFF7C5CFC)),
                    const SizedBox(width: 12),
                    _statCard('В работе', '3', Icons.pending_rounded,
                        const Color(0xFF38BDF8)),
                    const SizedBox(width: 12),
                    _statCard('Готово', '9', Icons.check_circle_rounded,
                        const Color(0xFF2DD4A8)),
                  ],
                ),
              ),
            ),

            // Quick actions
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: const Text(
                  'Быстрые действия',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                ),
                delegate: SliverChildListDelegate([
                  _actionCard(
                    context,
                    'Новая заявка',
                    'Создать оценку',
                    Icons.add_location_alt_rounded,
                    const Color(0xFF7C5CFC),
                    () {},
                  ),
                  _actionCard(
                    context,
                    'AI помощник',
                    'Задать вопрос',
                    Icons.smart_toy_rounded,
                    const Color(0xFF38BDF8),
                    () {},
                  ),
                  _actionCard(
                    context,
                    'Документы',
                    'Загрузить файлы',
                    Icons.upload_file_rounded,
                    const Color(0xFFFBBF24),
                    () {},
                  ),
                  _actionCard(
                    context,
                    'Оплата',
                    'Оплатить услугу',
                    Icons.payments_rounded,
                    const Color(0xFF2DD4A8),
                    () => AppNavigator.push(context, const PaymentScreen()),
                  ),
                ]),
              ),
            ),

            // Recent
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Последние заявки',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Все',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _recentCard(
                    context,
                    '#2847',
                    'Квартира',
                    '85 м² · Алматы, ул. Абая 52',
                    BadgeStatus.inProgress,
                    'В работе',
                  ),
                  _recentCard(
                    context,
                    '#2831',
                    'Дом',
                    '180 м² · Алматы, пр. Достык 45',
                    BadgeStatus.completed,
                    'Завершён',
                  ),
                  _recentCard(
                    context,
                    '#2819',
                    'Квартира',
                    '62 м² · Астана, ул. Кенесары 38',
                    BadgeStatus.pending,
                    'Ожидание',
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentCard(
    BuildContext context,
    String number,
    String type,
    String details,
    BadgeStatus status,
    String statusLabel,
  ) {
    return GlassCard(
      onTap: () => AppNavigator.push(context, const ApplicationCardScreen()),
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
                number,
                style: const TextStyle(
                  fontSize: 13,
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
                Text(
                  type,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  details,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          StatusBadge(status: status, label: statusLabel, small: true),
        ],
      ),
    );
  }
}

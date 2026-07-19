import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_badge.dart';
import '../navigation/app_navigator.dart';
import '../services/supabase_service.dart';
import 'payment_screen.dart';
import 'application_card_screen.dart';
import 'my_applications_screen.dart';
import 'new_application_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, int> _stats = {'total': 0, 'inProgress': 0, 'completed': 0};
  List<Map<String, dynamic>> _recentApps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        SupabaseService.getStats(),
        SupabaseService.getApplications(),
      ]);
      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, int>;
          _recentApps = (results[1] as List<Map<String, dynamic>>)
              .take(3)
              .toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _statusLabel(String status) => switch (status) {
        'new' => 'Новая',
        'in_progress' => 'В работе',
        'completed' => 'Завершена',
        'rejected' => 'Отклонена',
        'paid' => 'Оплачена',
        _ => status,
      };

  BadgeStatus _badgeStatus(String status) => switch (status) {
        'new' => BadgeStatus.pending,
        'in_progress' => BadgeStatus.inProgress,
        'completed' => BadgeStatus.completed,
        'rejected' => BadgeStatus.rejected,
        _ => BadgeStatus.pending,
      };

  String _propertyTypeLabel(String type) => switch (type) {
        'apartment' => 'Квартира',
        'house' => 'Дом',
        'land' => 'Участок',
        'commercial' => 'Коммерческая',
        _ => type,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.accent,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
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
                          const Text(
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
                      GestureDetector(
                        onTap: () => AppNavigator.push(
                            context, const ProfileScreen()),
                        child: Container(
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
                      _statCard(
                        context,
                        'Заявки',
                        '${_stats['total'] ?? 0}',
                        Icons.description_rounded,
                        const Color(0xFF7C5CFC),
                        () => AppNavigator.push(
                          context,
                          const MyApplicationsScreen(initialFilter: 0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _statCard(
                        context,
                        'В работе',
                        '${_stats['inProgress'] ?? 0}',
                        Icons.pending_rounded,
                        const Color(0xFF38BDF8),
                        () => AppNavigator.push(
                          context,
                          const MyApplicationsScreen(initialFilter: 1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _statCard(
                        context,
                        'Готово',
                        '${_stats['completed'] ?? 0}',
                        Icons.check_circle_rounded,
                        const Color(0xFF2DD4A8),
                        () => AppNavigator.push(
                          context,
                          const MyApplicationsScreen(initialFilter: 2),
                        ),
                      ),
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
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
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
                      () => AppNavigator.push(
                          context, const NewApplicationScreen()),
                    ),
                    _actionCard(
                      context,
                      'AI помощник',
                      'Задать вопрос',
                      Icons.smart_toy_rounded,
                      const Color(0xFF38BDF8),
                      () {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Перейдите во вкладку AI внизу экрана',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: AppColors.accent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    ),
                    _actionCard(
                      context,
                      'Документы',
                      'Загрузить файлы',
                      Icons.upload_file_rounded,
                      const Color(0xFFFBBF24),
                      () {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Перейдите во вкладку Документы внизу экрана',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: AppColors.accent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    ),
                    _actionCard(
                      context,
                      'Оплата',
                      'Оплатить услугу',
                      Icons.payments_rounded,
                      const Color(0xFF2DD4A8),
                      () => AppNavigator.push(
                          context, const PaymentScreen()),
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
                        onPressed: () => AppNavigator.push(
                          context,
                          const MyApplicationsScreen(),
                        ),
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
                sliver: _loading
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: CircularProgressIndicator(
                                color: AppColors.accent),
                          ),
                        ),
                      )
                    : _recentApps.isEmpty
                        ? SliverToBoxAdapter(
                            child: GlassCard(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(
                                    'Пока нет заявок. Создайте первую!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildListDelegate(
                              _recentApps.map((app) {
                                final prop = app['properties'];
                                final propType =
                                    prop != null ? (prop['type'] ?? '') : '';
                                final address =
                                    prop != null ? (prop['address'] ?? '') : '';
                                final area = prop != null
                                    ? '${prop['area'] ?? 0} м²'
                                    : '';
                                final status = app['status'] ?? 'new';
                                final detail =
                                    area.isNotEmpty ? '$area · $address' : address;

                                return GlassCard(
                                  onTap: () => AppNavigator.push(context,
                                      const ApplicationCardScreen()),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.accent
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '#${(app['id'] ?? '').toString().substring(0, 4).toUpperCase()}',
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _propertyTypeLabel(propType),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              detail,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color:
                                                    AppColors.textSecondary,
                                              ),
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      StatusBadge(
                                        status: _badgeStatus(status),
                                        label: _statusLabel(status),
                                        small: true,
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
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
}

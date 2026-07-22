import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/border_icon.dart';
import '../widgets/information_tile.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.accent,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            slivers: [
              // ── Header ──
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      GestureDetector(
                        onTap: () =>
                            AppNavigator.push(context, const ProfileScreen()),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'A',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Stats strip ──
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.paper,
                  padding: const EdgeInsets.fromLTRB(24, 24, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ЗАЯВКИ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GestureDetector(
                            onTap: () => AppNavigator.push(
                              context,
                              const MyApplicationsScreen(initialFilter: 0),
                            ),
                            child: InformationTile(
                              content: '${_stats['total'] ?? 0}',
                              name: 'Всего',
                              icon: Icons.description_rounded,
                              valueColor: AppColors.textPrimary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => AppNavigator.push(
                              context,
                              const MyApplicationsScreen(initialFilter: 1),
                            ),
                            child: InformationTile(
                              content: '${_stats['inProgress'] ?? 0}',
                              name: 'В работе',
                              icon: Icons.pending_actions_rounded,
                              valueColor: AppColors.info,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => AppNavigator.push(
                              context,
                              const MyApplicationsScreen(initialFilter: 2),
                            ),
                            child: InformationTile(
                              content: '${_stats['completed'] ?? 0}',
                              name: 'Готово',
                              icon: Icons.check_circle_outline_rounded,
                              valueColor: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Quick Actions strip ──
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(24, 24, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'БЫСТРЫЕ ДЕЙСТВИЯ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _actionItem(
                              Icons.add_location_alt_rounded,
                              'Новая заявка',
                              'Создать оценку',
                              AppColors.accent,
                              () => AppNavigator.push(
                                  context, const NewApplicationScreen()),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 64,
                            color: AppColors.border,
                          ),
                          Expanded(
                            child: _actionItem(
                              Icons.smart_toy_rounded,
                              'AI помощник',
                              'Задать вопрос',
                              AppColors.info,
                              () {
                                Navigator.of(context).popUntil(
                                    (route) => route.isFirst);
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
                          ),
                        ],
                      ),
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: AppColors.border,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _actionItem(
                              Icons.upload_file_rounded,
                              'Документы',
                              'Загрузить файлы',
                              AppColors.warning,
                              () {
                                Navigator.of(context).popUntil(
                                    (route) => route.isFirst);
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
                          ),
                          Container(
                            width: 1,
                            height: 64,
                            color: AppColors.border,
                          ),
                          Expanded(
                            child: _actionItem(
                              Icons.payments_rounded,
                              'Оплата',
                              'Оплатить услугу',
                              AppColors.success,
                              () => AppNavigator.push(
                                  context, const PaymentScreen()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Recent Applications strip ──
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.paper,
                  padding: const EdgeInsets.fromLTRB(24, 24, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ПОСЛЕДНИЕ ЗАЯВКИ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                          letterSpacing: 2,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => AppNavigator.push(
                          context,
                          const MyApplicationsScreen(),
                        ),
                        child: const Text(
                          'Все →',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              _loading
                  ? SliverToBoxAdapter(
                      child: Container(
                        color: AppColors.paper,
                        padding: const EdgeInsets.all(40),
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accent, strokeWidth: 2),
                        ),
                      ),
                    )
                  : _recentApps.isEmpty
                      ? SliverToBoxAdapter(
                          child: Container(
                            color: AppColors.paper,
                            padding: const EdgeInsets.all(40),
                            child: const Center(
                              child: Text(
                                'Пока нет заявок',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ),
                          ),
                        )
                      : SliverToBoxAdapter(
                          child: Container(
                            color: AppColors.paper,
                            padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                            child: Column(
                              children: [
                                ..._recentApps.map((app) {
                                  final prop = app['properties'];
                                  final propType =
                                      prop != null ? (prop['type'] ?? '') : '';
                                  final address = prop != null
                                      ? (prop['address'] ?? '')
                                      : '';
                                  final area = prop != null
                                      ? '${prop['area'] ?? 0} м²'
                                      : '';
                                  final status = app['status'] ?? 'new';
                                  final detail = area.isNotEmpty
                                      ? '$area · $address'
                                      : address;

                                  return GestureDetector(
                                    onTap: () => AppNavigator.push(
                                        context, const ApplicationCardScreen()),
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: AppColors.accent
                                                      .withValues(alpha: 0.08),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '#${(app['id'] ?? '').toString().substring(0, 4).toUpperCase()}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
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
                                                      propertyTypeLabel(
                                                          propType),
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: AppColors
                                                            .textPrimary,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      detail,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              StatusBadge(
                                                status:
                                                    badgeStatusFromKey(status),
                                                label: statusLabel(status),
                                                small: true,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          height: 1,
                                          color: AppColors.muted,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionItem(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            BorderIcon(
              width: 40,
              height: 40,
              padding: EdgeInsets.zero,
              backgroundColor: color.withValues(alpha: 0.08),
              borderColor: color.withValues(alpha: 0.15),
              borderRadius: 12,
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_badge.dart';
import '../services/supabase_service.dart';
import '../navigation/app_navigator.dart';
import 'application_card_screen.dart';

class MyApplicationsScreen extends StatefulWidget {
  final int initialFilter;

  const MyApplicationsScreen({super.key, this.initialFilter = 0});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  late int _filterIndex;
  List<Map<String, dynamic>> _applications = [];
  bool _loading = true;

  final _filters = ['Все', 'В работе', 'Завершённые'];

  @override
  void initState() {
    super.initState();
    _filterIndex = widget.initialFilter;
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    try {
      final data = await SupabaseService.getApplications();
      if (mounted) {
        setState(() {
          _applications = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredApplications {
    switch (_filterIndex) {
      case 1:
        return _applications
            .where((a) => a['status'] == 'in_progress')
            .toList();
      case 2:
        return _applications
            .where((a) => a['status'] == 'completed')
            .toList();
      default:
        return _applications;
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
    final filtered = _filteredApplications;

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
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accent))
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.description_rounded,
                                size: 48,
                                color: AppColors.textHint.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Нет заявок',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadApplications,
                          color: AppColors.accent,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final app = filtered[index];
                              final prop = app['properties'];
                              final propType =
                                  prop != null ? (prop['type'] ?? '') : '';
                              final address =
                                  prop != null ? (prop['address'] ?? '') : '';
                              final area = prop != null
                                  ? '${prop['area'] ?? 0} м²'
                                  : '';
                              final status = app['status'] ?? 'new';

                              return GlassCard(
                                onTap: () => AppNavigator.push(
                                  context,
                                  const ApplicationCardScreen(),
                                ),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceBetween,
                                            children: [
                                              Text(
                                                _propertyTypeLabel(
                                                    propType),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  color: AppColors
                                                      .textPrimary,
                                                ),
                                              ),
                                              StatusBadge(
                                                status:
                                                    _badgeStatus(status),
                                                label:
                                                    _statusLabel(status),
                                                small: true,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                          Row(
                                            children: [
                                              Text(
                                                area,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors
                                                        .textSecondary),
                                              ),
                                              const Text('  ·  ',
                                                  style: TextStyle(
                                                      color: AppColors
                                                          .textHint)),
                                              Expanded(
                                                child: Text(
                                                  address,
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors
                                                          .textSecondary),
                                                  overflow: TextOverflow
                                                      .ellipsis,
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
            ),
          ],
        ),
      ),
    );
  }
}

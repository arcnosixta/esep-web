import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/app_filter_chip.dart';
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredApplications;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── White strip: title ──
            Container(
              width: double.infinity,
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
              child: const Text(
                'МОИ ЗАЯВКИ',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // ── Paper strip: filter chips ──
            Container(
              width: double.infinity,
              color: AppColors.paper,
              padding: const EdgeInsets.fromLTRB(24, 12, 20, 12),
              child: SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: List.generate(_filters.length, (index) {
                    return AppFilterChip(
                      label: _filters[index],
                      isSelected: _filterIndex == index,
                      onTap: () => setState(() => _filterIndex = index),
                    );
                  }),
                ),
              ),
            ),

            // ── White strip: list ──
            Expanded(
              child: Container(
                color: AppColors.surface,
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                          strokeWidth: 2,
                        ),
                      )
                    : filtered.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadApplications,
                            color: AppColors.accent,
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              itemCount: filtered.length,
                              separatorBuilder: (context, _) => Container(
                                height: 1,
                                color: AppColors.border,
                              ),
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

                                return GestureDetector(
                                  onTap: () => AppNavigator.push(
                                    context,
                                    const ApplicationCardScreen(),
                                  ),
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    child: Row(
                                      children: [
                                        // ID pill
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.accent
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '#${(app['id'] ?? '').toString().substring(0, 4).toUpperCase()}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.accent,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),

                                        // Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                propertyTypeLabel(propType),
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Text(
                                                    area,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                  const Text('  ·  ',
                                                      style: TextStyle(
                                                          color: AppColors
                                                              .textHint)),
                                                  Expanded(
                                                    child: Text(
                                                      address,
                                                      style:
                                                          const TextStyle(
                                                        fontSize: 12,
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(width: 10),

                                        // Status badge
                                        StatusBadge(
                                          status:
                                              badgeStatusFromKey(status),
                                          label: statusLabel(status),
                                          small: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_rounded,
            size: 48,
            color: AppColors.muted,
          ),
          const SizedBox(height: 14),
          const Text(
            'Нет заявок',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

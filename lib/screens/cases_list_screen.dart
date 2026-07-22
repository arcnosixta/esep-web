import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/app_filter_chip.dart';
import '../widgets/status_badge.dart';
import '../services/supabase_service.dart';
import '../navigation/app_navigator.dart';
import 'case_detail_screen.dart';

class CasesListScreen extends StatefulWidget {
  final int initialFilter;

  const CasesListScreen({super.key, this.initialFilter = 0});

  @override
  State<CasesListScreen> createState() => _CasesListScreenState();
}

class _CasesListScreenState extends State<CasesListScreen> {
  late int _filterIndex;
  List<Map<String, dynamic>> _applications = [];
  bool _loading = true;

  final _filters = kCaseFilters;

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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: const Text(
                'Заявки',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
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

            const SizedBox(height: 8),

            Expanded(
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
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                            itemCount: filtered.length,
                            separatorBuilder: (context, _) =>
                                const SizedBox(height: 12),
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
                                  const CaseDetailScreen(),
                                ),
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: AppColors.border, width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.03),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.accent
                                              .withValues(alpha: 0.08),
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
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              propertyTypeLabel(context, propType),
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              area.isNotEmpty
                                                  ? '$area · $address'
                                                  : address,
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
                                      const SizedBox(width: 10),
                                      StatusBadge(
                                        status:
                                            badgeStatusFromKey(status),
                                        label: statusLabel(context, status),
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
            Icons.folder_open_rounded,
            size: 56,
            color: AppColors.muted,
          ),
          const SizedBox(height: 16),
          const Text(
            'Нет заявок',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Создайте первую заявку на оценку',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

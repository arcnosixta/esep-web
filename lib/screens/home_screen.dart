import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/case_progress_bar.dart';
import '../widgets/status_badge.dart';
import '../l10n/app_strings.dart';
import '../navigation/app_navigator.dart';
import '../services/supabase_service.dart';
import 'ai_chat_screen.dart';
import 'case_detail_screen.dart';
import 'cases_list_screen.dart';
import 'new_application_screen.dart';
import 'payment_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onDocumentsTap;

  const HomeScreen({super.key, this.onDocumentsTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _recentApps = [];
  bool _loading = true;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        SupabaseService.getApplications(),
        SupabaseService.getProfile(),
      ]);
      if (mounted) {
        final profile = results[1] as Map<String, dynamic>?;
        setState(() {
          _recentApps = (results[0] as List<Map<String, dynamic>>)
              .take(3)
              .toList();
          _userName = (profile?['full_name'] ?? '').toString().split(' ').first;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${greeting(context)},',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _userName.isNotEmpty ? _userName : 'ESEP',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () =>
                            AppNavigator.push(context, const ProfileScreen()),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _userName.isNotEmpty
                                  ? _userName[0].toUpperCase()
                                  : 'E',
                              style: const TextStyle(
                                fontSize: 17,
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

              if (!_loading && _recentApps.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                    child: GestureDetector(
                      onTap: () => AppNavigator.push(
                          context, const CaseDetailScreen()),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  s.homeCurrentApplication,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                StatusBadge(
                                  status: badgeStatusFromKey(
                                    _recentApps.first['status'] ?? 'new',
                                  ),
                                  label: statusLabel(
                                    context,
                                    _recentApps.first['status'] ?? 'new',
                                  ),
                                  small: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              caseNumber(
                                (_recentApps.first['id'] ?? '').toString(),
                              ),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _buildCaseSubtitle(_recentApps.first),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            CaseProgressBar(
                              progress: _getProgress(
                                _recentApps.first['status'] ?? 'new',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  child: Text(
                    s.homeContinueWork,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _quickAction(
                          Icons.add_location_alt_rounded,
                          s.homeNewApplication,
                          AppColors.accent,
                          () => AppNavigator.push(
                              context, const NewApplicationScreen()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _quickAction(
                          Icons.description_rounded,
                          s.homeDocuments,
                          AppColors.warning,
                          widget.onDocumentsTap ?? () {},
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _quickAction(
                          Icons.payments_rounded,
                          s.homePayment,
                          AppColors.success,
                          () => AppNavigator.push(
                              context, const PaymentScreen()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _quickAction(
                          Icons.auto_awesome_rounded,
                          s.homeEvaluate,
                          AppColors.gold,
                          () => AppNavigator.push(
                              context, const AiChatScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.homeRecentApplications,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => AppNavigator.push(
                          context,
                          const CasesListScreen(),
                        ),
                        child: Text(
                          s.homeAll,
                          style: const TextStyle(
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
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accent, strokeWidth: 2),
                        ),
                      ),
                    )
                  : _recentApps.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.folder_open_rounded,
                                    size: 48,
                                    color: AppColors.muted,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    s.homeNoApplications,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: AppColors.border, width: 1),
                              ),
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
                                          context, const CaseDetailScreen()),
                                      behavior: HitTestBehavior.opaque,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 16),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 42,
                                              height: 42,
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
                                                        context, propType),
                                                    style: const TextStyle(
                                                      fontSize: 15,
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
                                              label: statusLabel(
                                                  context, status),
                                              small: true,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildCaseSubtitle(Map<String, dynamic> app) {
    final prop = app['properties'];
    if (prop == null) return '';
    final type = propertyTypeLabel(context, prop['type'] ?? '');
    final address = prop['address'] ?? '';
    return '$type · $address';
  }

  double _getProgress(String status) {
    return switch (status) {
      'new' => 0.15,
      'in_progress' => 0.55,
      'completed' => 1.0,
      'paid' => 1.0,
      'rejected' => 0.0,
      _ => 0.15,
    };
  }

  Widget _quickAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

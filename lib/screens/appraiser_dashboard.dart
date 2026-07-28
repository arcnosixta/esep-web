import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/supabase_service.dart';
import '../models/user_profile.dart';
import '../utils/formatters.dart';
import '../widgets/status_badge.dart';
import '../widgets/app_filter_chip.dart';
import 'document_upload_screen.dart';

class AppraiserDashboard extends StatefulWidget {
  const AppraiserDashboard({super.key});

  @override
  State<AppraiserDashboard> createState() => _AppraiserDashboardState();
}

class _AppraiserDashboardState extends State<AppraiserDashboard> {
  int _currentIndex = 0;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await SupabaseService.getUserProfile();
    if (mounted) setState(() => _profile = profile);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    final pages = [
      _AppraiserHome(profile: _profile),
      const _AppraiserRequests(),
      const _AppraiserEvaluations(),
      const _AppraiserDocuments(),
      _AppraiserProfile(profile: _profile, onRefresh: _loadProfile),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: c.surface),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_rounded, 'Главная'),
                _navItem(1, Icons.assignment_rounded, 'Запросы'),
                _navItem(2, Icons.assessment_rounded, 'Оценки'),
                _navItem(3, Icons.description_rounded, 'Документы'),
                _navItem(4, Icons.person_rounded, 'Профиль'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final c = AppColors.of(context);
    final active = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 32,
              decoration: BoxDecoration(
                color: active ? c.accent.withValues(alpha: 0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: active ? c.accent : c.textHint),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? c.accent : c.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// HOME
// ============================================

class _AppraiserHome extends StatefulWidget {
  final UserProfile? profile;
  const _AppraiserHome({required this.profile});

  @override
  State<_AppraiserHome> createState() => _AppraiserHomeState();
}

class _AppraiserHomeState extends State<_AppraiserHome> {
  bool _loading = true;
  int _newCount = 0;
  int _completedCount = 0;
  int _inProgressCount = 0;
  List<Map<String, dynamic>> _recentActions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        SupabaseService.getAvailableApplications(),
        SupabaseService.getAppraiserApplications(),
      ]);
      final available = results[0];
      final assigned = results[1];

      final completed = assigned.where((a) => a['status'] == 'completed').length;
      final inProgress = assigned.where((a) => a['status'] == 'in_progress').length;

      if (mounted) {
        setState(() {
          _newCount = available.length;
          _completedCount = completed;
          _inProgressCount = inProgress;
          _recentActions = assigned.take(5).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final name = widget.profile?.fullName.split(' ').first ?? 'Оценщик';

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: c.accent,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
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
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: c.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            name.isNotEmpty ? name : 'Оценщик',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: c.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: c.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: c.success, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Оценщик',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.success),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  child: Text(
                    'СТАТИСТИКА',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      Expanded(child: _statCard(c, 'Новые', '$_newCount', Icons.fiber_new_rounded, c.warning)),
                      const SizedBox(width: 10),
                      Expanded(child: _statCard(c, 'В работе', '$_inProgressCount', Icons.work_rounded, c.info)),
                      const SizedBox(width: 10),
                      Expanded(child: _statCard(c, 'Готово', '$_completedCount', Icons.check_circle_rounded, c.success)),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  child: Text(
                    'ПОСЛЕДНИЕ ДЕЙСТВИЯ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ),

              if (_loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                )
              else if (_recentActions.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox_rounded, size: 48, color: c.muted),
                          const SizedBox(height: 12),
                          Text('Нет назначенных заявок', style: TextStyle(fontSize: 14, color: c.textHint)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
                    child: Container(
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.border, width: 1),
                      ),
                      child: Column(
                        children: _recentActions.map((app) {
                          final status = app['status'] ?? 'new';
                          final userName = (app['profiles']?['full_name'] ?? '').toString();
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: c.accent.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '#${(app['id'] ?? '').toString().substring(0, 4).toUpperCase()}',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.accent),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName.isNotEmpty ? userName : 'Клиент',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        statusLabel(context, status),
                                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusBadge(
                                  status: badgeStatusFromKey(status),
                                  label: statusLabel(context, status),
                                  small: true,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(AppColors c, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border, width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ============================================
// REQUESTS
// ============================================

class _AppraiserRequests extends StatefulWidget {
  const _AppraiserRequests();

  @override
  State<_AppraiserRequests> createState() => _AppraiserRequestsState();
}

class _AppraiserRequestsState extends State<_AppraiserRequests> {
  bool _loading = true;
  List<Map<String, dynamic>> _available = [];
  List<Map<String, dynamic>> _assigned = [];
  int _filterIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        SupabaseService.getAvailableApplications(),
        SupabaseService.getAppraiserApplications(),
      ]);
      if (mounted) {
        setState(() {
          _available = results[0];
          _assigned = results[1];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredAssigned {
    switch (_filterIndex) {
      case 1:
        return _assigned.where((a) => a['status'] == 'in_progress').toList();
      case 2:
        return _assigned.where((a) => a['status'] == 'completed').toList();
      default:
        return _assigned;
    }
  }

  Future<void> _assignToMe(String applicationId) async {
    try {
      await SupabaseService.assignApplication(applicationId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заявка назначена на вас')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Text(
                'Запросы',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: c.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    AppFilterChip(
                      label: 'Доступные (${_available.length})',
                      isSelected: _filterIndex == 0,
                      onTap: () => setState(() => _filterIndex = 0),
                    ),
                    AppFilterChip(
                      label: 'В работе',
                      isSelected: _filterIndex == 1,
                      onTap: () => setState(() => _filterIndex = 1),
                    ),
                    AppFilterChip(
                      label: 'Завершённые',
                      isSelected: _filterIndex == 2,
                      onTap: () => setState(() => _filterIndex == 2),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: c.accent, strokeWidth: 2))
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: c.accent,
                      child: _filterIndex == 0
                          ? _buildAvailableList(c)
                          : _buildAssignedList(c),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableList(AppColors c) {
    if (_available.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 56, color: c.muted),
            const SizedBox(height: 16),
            Text('Нет доступных заявок', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: c.textSecondary)),
          ],
        ),
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      itemCount: _available.length,
      separatorBuilder: (context, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildAvailableCard(c, _available[index]),
    );
  }

  Widget _buildAvailableCard(AppColors c, Map<String, dynamic> app) {
    final userName = (app['profiles']?['full_name'] ?? '').toString();
    final iin = (app['profiles']?['iin'] ?? '').toString();
    final prop = app['properties'];
    final address = prop?['address'] ?? '';
    final propType = prop?['type'] ?? '';
    final area = prop?['area'] ?? 0;
    final createdAt = app['created_at']?.toString() ?? '';
    final date = createdAt.isNotEmpty
        ? '${DateTime.parse(createdAt).day.toString().padLeft(2, '0')}.${DateTime.parse(createdAt).month.toString().padLeft(2, '0')}.${DateTime.parse(createdAt).year}'
        : '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '#${(app['id'] ?? '').toString().substring(0, 4).toUpperCase()}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.warning),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName.isNotEmpty ? userName : 'Клиент',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary)),
                    if (iin.isNotEmpty)
                      Text('ИИН: $iin', style: TextStyle(fontSize: 12, color: c.textSecondary)),
                  ],
                ),
              ),
              StatusBadge(status: BadgeStatus.pending, label: 'Новая', small: true),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 14, color: c.textHint),
              const SizedBox(width: 4),
              Expanded(
                child: Text(address.isNotEmpty ? address : '—',
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _meta(c, propertyTypeLabel(context, propType)),
              const SizedBox(width: 12),
              _meta(c, '$area м²'),
              const SizedBox(width: 12),
              _meta(c, date),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _assignToMe(app['id']),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Начать оценку', style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedList(AppColors c) {
    final list = _filteredAssigned;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_rounded, size: 56, color: c.muted),
            const SizedBox(height: 16),
            Text('Нет заявок', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: c.textSecondary)),
          ],
        ),
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      itemCount: list.length,
      separatorBuilder: (context, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildAssignedCard(c, list[index]),
    );
  }

  Widget _buildAssignedCard(AppColors c, Map<String, dynamic> app) {
    final status = app['status'] ?? 'new';
    final userName = (app['profiles']?['full_name'] ?? '').toString();
    final prop = app['properties'];
    final address = prop?['address'] ?? '';
    final area = prop?['area'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '#${(app['id'] ?? '').toString().substring(0, 4).toUpperCase()}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.accent),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName.isNotEmpty ? userName : 'Клиент',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  area > 0 ? '$area м² · $address' : address,
                  style: TextStyle(fontSize: 12, color: c.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          StatusBadge(status: badgeStatusFromKey(status), label: statusLabel(context, status), small: true),
        ],
      ),
    );
  }

  Widget _meta(AppColors c, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: c.surfaceLight,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(text, style: TextStyle(fontSize: 11, color: c.textSecondary)),
        ),
      ],
    );
  }
}

// ============================================
// EVALUATIONS
// ============================================

class _AppraiserEvaluations extends StatefulWidget {
  const _AppraiserEvaluations();

  @override
  State<_AppraiserEvaluations> createState() => _AppraiserEvaluationsState();
}

class _AppraiserEvaluationsState extends State<_AppraiserEvaluations> {
  bool _loading = true;
  List<Map<String, dynamic>> _evaluations = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await SupabaseService.getAppraiserApplications();
      if (mounted) {
        setState(() {
          _evaluations = data.where((a) => a['status'] == 'completed' || a['estimated_price'] != null).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Text(
                'Мои оценки',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: c.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: c.accent, strokeWidth: 2))
                  : _evaluations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assessment_rounded, size: 56, color: c.muted),
                              const SizedBox(height: 16),
                              Text('Пока нет завершённых оценок',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: c.textSecondary)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: c.accent,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                            itemCount: _evaluations.length,
                            separatorBuilder: (context, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final app = _evaluations[index];
                              final price = app['estimated_price'];
                              final userName = (app['profiles']?['full_name'] ?? '').toString();
                              final status = app['status'] ?? 'new';

                              return Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: c.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: c.border, width: 1),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: c.success.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.check_circle_rounded, color: c.success, size: 22),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(userName.isNotEmpty ? userName : 'Клиент',
                                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary)),
                                          const SizedBox(height: 4),
                                          Text(
                                            price != null ? '$price ₸' : 'Оценка в процессе',
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.accent),
                                          ),
                                        ],
                                      ),
                                    ),
                                    StatusBadge(status: badgeStatusFromKey(status), label: statusLabel(context, status), small: true),
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

// ============================================
// DOCUMENTS
// ============================================

class _AppraiserDocuments extends StatelessWidget {
  const _AppraiserDocuments();

  @override
  Widget build(BuildContext context) {
    return const DocumentUploadScreen();
  }
}

// ============================================
// PROFILE
// ============================================

class _AppraiserProfile extends StatelessWidget {
  final UserProfile? profile;
  final VoidCallback onRefresh;

  const _AppraiserProfile({required this.profile, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final name = profile?.fullName ?? '';
    final email = profile?.email ?? SupabaseService.currentUser?.email ?? '';
    final phone = profile?.phone ?? '';
    final iin = profile?.iin ?? '';

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: [
            Text(
              'Профиль',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(color: c.success, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        profile?.initials ?? 'О',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name.isNotEmpty ? name : '—',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.textPrimary)),
                        const SizedBox(height: 2),
                        Text('Оценщик',
                            style: TextStyle(fontSize: 13, color: c.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: c.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 14, color: c.success),
                        const SizedBox(width: 4),
                        Text('Оценщик',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.success)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border, width: 1),
              ),
              child: Column(
                children: [
                  infoRow(context, 'ФИО', name.isNotEmpty ? name : '—'),
                  divider(context),
                  infoRow(context, 'ИИН', iin.isNotEmpty ? iin : '—'),
                  divider(context),
                  infoRow(context, 'Телефон', phone.isNotEmpty ? phone : '—'),
                  divider(context),
                  infoRow(context, 'Email', email),
                  divider(context),
                  infoRow(context, 'Роль', 'Оценщик'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border, width: 1),
              ),
              child: Column(
                children: [
                  _settingsRow(context, Icons.help_rounded, 'Помощь'),
                  Container(height: 1, margin: const EdgeInsets.only(left: 52), color: c.divider),
                  _settingsRow(context, Icons.info_outline_rounded, 'О приложении'),
                  Container(height: 1, margin: const EdgeInsets.only(left: 52), color: c.divider),
                  _settingsRow(
                    context,
                    Icons.logout_rounded,
                    'Выйти',
                    color: c.error,
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: c.surface,
                          title: Text('Выйти из аккаунта?', style: TextStyle(color: c.textPrimary)),
                          content: Text('Вы сможете войти снова', style: TextStyle(color: c.textSecondary)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Отмена', style: TextStyle(color: c.textSecondary))),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Выйти', style: TextStyle(color: c.error))),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        await SupabaseService.signOut();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsRow(BuildContext context, IconData icon, String label, {Color? color, VoidCallback? onTap}) {
    final c = AppColors.of(context);
    final effectiveColor = color ?? c.textPrimary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: effectiveColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: effectiveColor)),
            ),
            if (color == null)
              Icon(Icons.chevron_right_rounded, size: 20, color: c.textHint),
          ],
        ),
      ),
    );
  }
}



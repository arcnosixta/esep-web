import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../services/payment_service.dart';
import '../services/supabase_service.dart';
import '../models/user_profile.dart';
import '../utils/formatters.dart';
import '../widgets/status_badge.dart';
import '../widgets/app_filter_chip.dart';
import 'admin_user_info_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await SupabaseService.getUserProfile();
    debugPrint('[AdminDashboard] profile loaded: role=${profile?.role}, userId=${SupabaseService.userId}');
    if (mounted) setState(() => _profile = profile);
  }

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    final pages = [
      _AdminHome(profile: _profile, onNavigate: _switchTab),
      _AdminUsers(onRefresh: _loadProfile),
      const _AdminAppraisers(),
      _AdminRequests(onRefresh: _loadProfile),
      const _AdminPayments(),
      const _AdminDocuments(),
      const _AdminLogs(),
      _AdminProfile(profile: _profile, onRefresh: _loadProfile),
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
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.dashboard_rounded, 'Главная'),
                _navItem(1, Icons.people_rounded, 'Юзеры'),
                _navItem(2, Icons.engineering_rounded, 'Оценщики'),
                _navItem(3, Icons.assignment_rounded, 'Заявки'),
                _navItem(4, Icons.payments_rounded, 'Платежи'),
                _navItem(5, Icons.description_rounded, 'Доки'),
                _navItem(6, Icons.history_rounded, 'Логи'),
                _navItem(7, Icons.person_rounded, 'Профиль'),
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
        width: 48,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 28,
              decoration: BoxDecoration(
                color: active ? c.accent.withValues(alpha: 0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: active ? c.accent : c.textHint),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? c.accent : c.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// ADMIN HOME
// ============================================

class _AdminHome extends StatefulWidget {
  final UserProfile? profile;
  final ValueChanged<int> onNavigate;

  const _AdminHome({required this.profile, required this.onNavigate});

  @override
  State<_AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<_AdminHome> {
  bool _loading = true;
  Map<String, int> _stats = {};
  List<Map<String, dynamic>> _recentApps = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        SupabaseService.getAdminStats(),
        SupabaseService.getAllApplications(),
      ]);
      final stats = results[0] as Map<String, int>;
      final apps = results[1] as List<Map<String, dynamic>>;
      debugPrint('[AdminHome] stats=$stats, apps=${apps.length}');
      if (mounted) {
        setState(() {
          _stats = stats;
          _recentApps = apps.take(5).toList();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[AdminHome] error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final name = widget.profile?.fullName.split(' ').first ?? 'Админ';

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
                            name.isNotEmpty ? name : 'Админ',
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
                          color: c.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: c.error, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Админ',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.error),
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
                    'СТАТИСТИКА ПЛАТФОРМЫ',
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
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                      : GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.6,
                          children: [
                            _statCard(c, 'Пользователи', '${_stats['totalUsers'] ?? 0}', Icons.people_rounded, c.accent, () => widget.onNavigate(1)),
                            _statCard(c, 'Заявки', '${_stats['totalApplications'] ?? 0}', Icons.assignment_rounded, c.info, () => widget.onNavigate(3)),
                            _statCard(c, 'Оценщики', '${_stats['totalAppraisers'] ?? 0}', Icons.engineering_rounded, c.success, () => widget.onNavigate(2)),
                            _statCard(c, 'Завершено', '${_stats['completedApplications'] ?? 0}', Icons.check_circle_rounded, c.gold, () => widget.onNavigate(3)),
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
                        'ПОСЛЕДНИЕ ЗАЯВКИ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: c.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => widget.onNavigate(3),
                        child: Text(
                          'Все →',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.accent),
                        ),
                      ),
                    ],
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
              else if (_recentApps.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox_rounded, size: 48, color: c.muted),
                          const SizedBox(height: 12),
                          Text('Нет заявок', style: TextStyle(fontSize: 14, color: c.textHint)),
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
                        children: _recentApps.map((app) {
                          final status = app['status'] ?? 'new';
                          final userName = (app['profiles']?['full_name'] ?? '').toString();
                          final prop = app['properties'];
                          final address = prop?['address'] ?? '';
                          final propType = prop?['type'] ?? '';
                          final priority = app['priority'] ?? 'normal';
                          final priorityColor = priority == 'urgent'
                              ? c.error
                              : priority == 'high'
                                  ? c.warning
                                  : c.textHint;

                          return GestureDetector(
                            onTap: () => _openApplicationDetail(app),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
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
                                          address.isNotEmpty ? '$propType · $address' : propType,
                                          style: TextStyle(fontSize: 12, color: c.textSecondary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      StatusBadge(status: badgeStatusFromKey(status), label: statusLabel(context, status), small: true),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: priorityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                        child: Text(priority.toUpperCase(),
                                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: priorityColor)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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

  void _openApplicationDetail(Map<String, dynamic> app) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AdminApplicationDetailScreen(applicationId: app['id']),
      ),
    );
  }

  Widget _statCard(AppColors c, String label, String value, IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.textPrimary),
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: c.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// ADMIN USERS
// ============================================

class _AdminUsers extends StatefulWidget {
  final VoidCallback? onRefresh;

  const _AdminUsers({this.onRefresh});

  @override
  State<_AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<_AdminUsers> {
  bool _loading = true;
  List<Map<String, dynamic>> _allUsers = [];
  String _searchQuery = '';
  String _roleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getAllProfiles();
      debugPrint('[AdminUsers] loaded ${data.length} profiles');
      if (mounted) {
        setState(() {
          _allUsers = data;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[AdminUsers] error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    var result = _allUsers.where((u) => u['role'] != 'admin').toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      result = result.where((u) {
        final name = (u['full_name'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        final iin = (u['iin'] ?? '').toString().toLowerCase();
        final phone = (u['phone'] ?? '').toString().toLowerCase();
        return name.contains(q) || email.contains(q) || iin.contains(q) || phone.contains(q);
      }).toList();
    }

    if (_roleFilter != 'all') {
      result = result.where((u) => u['role'] == _roleFilter).toList();
    }

    return result;
  }

  Future<void> _changeRole(Map<String, dynamic> user, String newRole) async {
    try {
      await SupabaseService.updateUserRole(user['user_id'], newRole);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Роль обновлена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  Future<void> _toggleBlock(Map<String, dynamic> user) async {
    final blocked = user['is_blocked'] == true;
    try {
      await SupabaseService.toggleUserBlock(user['user_id'], !blocked);
      await _loadData();
      widget.onRefresh?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(blocked ? 'Пользователь разблокирован' : 'Пользователь заблокирован')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  void _showEditDialog(Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['full_name'] ?? '');
    final phoneController = TextEditingController(text: user['phone'] ?? '');
    final iinController = TextEditingController(text: user['iin'] ?? '');
    final emailController = TextEditingController(text: user['email'] ?? '');
    final c = AppColors.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Редактировать', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(c, nameController, 'ФИО', Icons.person_rounded),
              const SizedBox(height: 12),
              _dialogField(c, phoneController, 'Телефон', Icons.phone_rounded),
              const SizedBox(height: 12),
              _dialogField(c, iinController, 'ИИН', Icons.badge_rounded),
              const SizedBox(height: 12),
              _dialogField(c, emailController, 'Email', Icons.email_rounded),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Отмена', style: TextStyle(color: c.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              await SupabaseService.updateUserProfile(
                user['user_id'],
                fullName: nameController.text.trim(),
                phone: phoneController.text.trim(),
                iin: iinController.text.trim(),
                email: emailController.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              await _loadData();
              widget.onRefresh?.call();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Профиль обновлён')),
                );
              }
            },
            child: Text('Сохранить', style: TextStyle(color: c.accent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(AppColors c, TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      style: TextStyle(color: c.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: c.textSecondary),
        filled: true,
        fillColor: c.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.accent, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  void _showUserActions(Map<String, dynamic> user) {
    final c = AppColors.of(context);
    final name = user['full_name'] ?? 'Пользователь';
    final role = user['role'] ?? 'client';
    final blocked = user['is_blocked'] == true;
    final iin = (user['iin'] ?? '').toString();
    final bin = (user['bin'] ?? '').toString();
    final orgName = (user['org_name'] ?? '').toString();
    final phone = (user['phone'] ?? '').toString();
    final email = (user['email'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (role == 'appraiser' ? c.success : c.accent).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : '?',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: role == 'appraiser' ? c.success : c.accent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name.toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary)),
                          Text(role == 'appraiser' ? 'Оценщик' : 'Клиент', style: TextStyle(fontSize: 13, color: c.textSecondary)),
                          if (iin.isNotEmpty)
                            Text('ИИН: $iin', style: TextStyle(fontSize: 12, color: c.textSecondary)),
                          if (bin.isNotEmpty)
                            Text('БИН: $bin${orgName.isNotEmpty ? ' · $orgName' : ''}', style: TextStyle(fontSize: 12, color: c.textSecondary)),
                          if (phone.isNotEmpty)
                            Text('Тел: $phone', style: TextStyle(fontSize: 12, color: c.textSecondary)),
                          if (email.isNotEmpty)
                            Text(email, style: TextStyle(fontSize: 12, color: c.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _actionTile(c, Icons.info_outline_rounded, 'Информация по ИИН', c.accent, () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminUserInfoScreen(user: user),
                  ),
                );
              }),
              _actionTile(c, Icons.edit_rounded, 'Редактировать профиль', c.accent, () {
                Navigator.pop(context);
                _showEditDialog(user);
              }),
              _actionTile(c, Icons.swap_horiz_rounded, role == 'appraiser' ? 'Сделать клиентом' : 'Сделать оценщиком', c.warning, () {
                Navigator.pop(context);
                _changeRole(user, role == 'appraiser' ? 'client' : 'appraiser');
              }),
              _actionTile(
                c,
                blocked ? Icons.lock_open_rounded : Icons.block_rounded,
                blocked ? 'Разблокировать' : 'Заблокировать',
                blocked ? c.success : c.error,
                () {
                  Navigator.pop(context);
                  _toggleBlock(user);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionTile(AppColors c, IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.textPrimary)),
      trailing: Icon(Icons.chevron_right_rounded, color: c.textHint, size: 20),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final filtered = _filteredUsers;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Пользователи',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: c.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: c.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${filtered.length}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.accent),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(color: c.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Поиск по ФИО, email, ИИН, телефону...',
                  hintStyle: TextStyle(color: c.textHint, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: c.textHint, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded, color: c.textHint, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  filled: true,
                  fillColor: c.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.accent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _roleChip('Все (${_allUsers.where((u) => u['role'] != 'admin').length})', 'all'),
                    _roleChip('Клиенты', 'client'),
                    _roleChip('Оценщики', 'appraiser'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: c.accent, strokeWidth: 2))
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_rounded, size: 48, color: c.muted),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty ? 'Ничего не найдено' : 'Нет пользователей',
                                style: TextStyle(fontSize: 14, color: c.textHint),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: c.accent,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                            itemCount: filtered.length,
                            separatorBuilder: (context, _) => const SizedBox(height: 8),
                            itemBuilder: (context, index) => _buildUserCard(filtered[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleChip(String label, String value) {
    final c = AppColors.of(context);
    final selected = _roleFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _roleFilter = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.accent.withValues(alpha: 0.08) : c.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? c.accent.withValues(alpha: 0.3) : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? c.accent : c.textSecondary)),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final c = AppColors.of(context);
    final name = user['full_name'] ?? '';
    final email = user['email'] ?? '';
    final phone = user['phone'] ?? '';
    final iin = (user['iin'] ?? '').toString();
    final bin = (user['bin'] ?? '').toString();
    final orgName = (user['org_name'] ?? '').toString();
    final role = user['role'] ?? 'client';
    final blocked = user['is_blocked'] == true;
    final roleColor = role == 'appraiser' ? c.success : c.accent;
    final roleLabel = role == 'appraiser' ? 'Оценщик' : 'Клиент';

    return GestureDetector(
      onTap: () => _showUserActions(user),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: blocked ? c.error.withValues(alpha: 0.3) : c.border, width: 1),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: blocked ? c.error.withValues(alpha: 0.1) : roleColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: blocked ? c.error : roleColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(name.isNotEmpty ? name : '—',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary)),
                          ),
                          if (blocked)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: c.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                              child: Text('Заблокирован', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: c.error)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(email, style: TextStyle(fontSize: 12, color: c.textSecondary), overflow: TextOverflow.ellipsis),
                      if (phone.isNotEmpty)
                        Text(phone, style: TextStyle(fontSize: 11, color: c.textHint)),
                      if (iin.isNotEmpty)
                        Text('ИИН: $iin', style: TextStyle(fontSize: 11, color: c.textHint, fontWeight: FontWeight.w500)),
                      if (bin.isNotEmpty)
                        Text('БИН: $bin${orgName.isNotEmpty ? ' · $orgName' : ''}',
                            style: TextStyle(fontSize: 11, color: c.textHint, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(roleLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: roleColor)),
                ),
                const SizedBox(width: 2),
                // Кнопка «Инфо» — вся доступная информация по ИИН.
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminUserInfoScreen(user: user),
                      ),
                    );
                  },
                  child: Tooltip(
                    message: 'Информация по ИИН',
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: c.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.info_outline_rounded,
                          size: 18, color: c.accent),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// ADMIN APPRAISERS
// ============================================

class _AdminAppraisers extends StatefulWidget {
  const _AdminAppraisers();

  @override
  State<_AdminAppraisers> createState() => _AdminAppraisersState();
}

class _AdminAppraisersState extends State<_AdminAppraisers> {
  bool _loading = true;
  List<Map<String, dynamic>> _appraisers = [];
  List<Map<String, dynamic>> _appraiserApps = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        SupabaseService.getAllProfiles(),
        SupabaseService.getAllApplications(),
      ]);
      final profiles = results[0];
      final apps = results[1];
      debugPrint('[AdminAppraisers] profiles=${profiles.length}, apps=${apps.length}');
      if (mounted) {
        setState(() {
          _appraisers = profiles.where((u) => u['role'] == 'appraiser').toList();
          _appraiserApps = apps;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[AdminAppraisers] error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  int _appraiserActiveCount(String appraiserUserId) {
    return _appraiserApps.where((a) => a['appraiser_id'] == appraiserUserId && a['status'] == 'in_progress').length;
  }

  int _appraiserCompletedCount(String appraiserUserId) {
    return _appraiserApps.where((a) => a['appraiser_id'] == appraiserUserId && a['status'] == 'completed').length;
  }

  void _showAppraiserActions(Map<String, dynamic> appraiser) {
    final c = AppColors.of(context);
    final name = appraiser['full_name'] ?? '';
    final blocked = appraiser['is_blocked'] == true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16)),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: c.success.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: Center(
                        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.success)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name.isNotEmpty ? name : '—',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary)),
                          Text('В работе: ${_appraiserActiveCount(appraiser['user_id'])} · Завершено: ${_appraiserCompletedCount(appraiser['user_id'])}',
                              style: TextStyle(fontSize: 12, color: c.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: c.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.edit_rounded, color: c.accent, size: 18)),
                title: Text('Редактировать', style: TextStyle(fontSize: 14, color: c.textPrimary)),
                trailing: Icon(Icons.chevron_right_rounded, color: c.textHint, size: 20),
                onTap: () {
                  Navigator.pop(context);
                  _showEditAppraiserDialog(appraiser);
                },
              ),
              ListTile(
                leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: c.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.swap_horiz_rounded, color: c.warning, size: 18)),
                title: Text('Сделать клиентом', style: TextStyle(fontSize: 14, color: c.textPrimary)),
                trailing: Icon(Icons.chevron_right_rounded, color: c.textHint, size: 20),
                onTap: () async {
                  Navigator.pop(context);
                  await SupabaseService.updateUserRole(appraiser['user_id'], 'client');
                  await _loadData();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Роль изменена')));
                },
              ),
              ListTile(
                leading: Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: (blocked ? c.success : c.error).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(blocked ? Icons.lock_open_rounded : Icons.block_rounded, color: blocked ? c.success : c.error, size: 18)),
                title: Text(blocked ? 'Разблокировать' : 'Заблокировать',
                    style: TextStyle(fontSize: 14, color: blocked ? c.success : c.error)),
                trailing: Icon(Icons.chevron_right_rounded, color: c.textHint, size: 20),
                onTap: () async {
                  Navigator.pop(context);
                  await SupabaseService.toggleUserBlock(appraiser['user_id'], !blocked);
                  await _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(blocked ? 'Разблокирован' : 'Заблокирован')),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditAppraiserDialog(Map<String, dynamic> appraiser) {
    final nameController = TextEditingController(text: appraiser['full_name'] ?? '');
    final phoneController = TextEditingController(text: appraiser['phone'] ?? '');
    final iinController = TextEditingController(text: appraiser['iin'] ?? '');
    final c = AppColors.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Редактировать оценщика', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: 'ФИО')),
              const SizedBox(height: 12),
              TextField(controller: phoneController, decoration: InputDecoration(labelText: 'Телефон')),
              const SizedBox(height: 12),
              TextField(controller: iinController, decoration: InputDecoration(labelText: 'ИИН')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Отмена', style: TextStyle(color: c.textSecondary))),
          TextButton(
            onPressed: () async {
              await SupabaseService.updateUserProfile(
                appraiser['user_id'],
                fullName: nameController.text.trim(),
                phone: phoneController.text.trim(),
                iin: iinController.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              await _loadData();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Обновлено')));
            },
            child: Text('Сохранить', style: TextStyle(color: c.accent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Оценщики',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: c.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: c.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_appraisers.length}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.success),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: c.accent, strokeWidth: 2))
                  : _appraisers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.engineering_rounded, size: 56, color: c.muted),
                              const SizedBox(height: 16),
                              Text('Нет оценщиков', style: TextStyle(fontSize: 16, color: c.textSecondary)),
                              const SizedBox(height: 6),
                              Text('Назначьте роль оценщика пользователям',
                                  style: TextStyle(fontSize: 13, color: c.textHint)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: c.accent,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                            itemCount: _appraisers.length,
                            separatorBuilder: (context, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final a = _appraisers[index];
                              final name = a['full_name'] ?? '';
                              final email = a['email'] ?? '';
                              final blocked = a['is_blocked'] == true;
                              final active = _appraiserActiveCount(a['user_id']);
                              final completed = _appraiserCompletedCount(a['user_id']);

                              return GestureDetector(
                                onTap: () => _showAppraiserActions(a),
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: c.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: c.border, width: 1),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 46,
                                            height: 46,
                                            decoration: BoxDecoration(
                                              color: c.success.withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.success),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(name.isNotEmpty ? name : '—',
                                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary)),
                                                    ),
                                                    if (blocked)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(color: c.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                                        child: Text('Заблокирован', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: c.error)),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(email, style: TextStyle(fontSize: 12, color: c.textSecondary)),
                                              ],
                                            ),
                                          ),
                                          Icon(Icons.chevron_right_rounded, color: c.textHint, size: 22),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          _apprStat(c, 'В работе', '$active', c.info),
                                          const SizedBox(width: 16),
                                          _apprStat(c, 'Завершено', '$completed', c.success),
                                        ],
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

  Widget _apprStat(AppColors c, String label, String value, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label: ', style: TextStyle(fontSize: 12, color: c.textSecondary)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.textPrimary)),
      ],
    );
  }
}

// ============================================
// ADMIN REQUESTS
// ============================================

class _AdminRequests extends StatefulWidget {
  final VoidCallback? onRefresh;

  const _AdminRequests({this.onRefresh});

  @override
  State<_AdminRequests> createState() => _AdminRequestsState();
}

class _AdminRequestsState extends State<_AdminRequests> {
  bool _loading = true;
  List<Map<String, dynamic>> _applications = [];
  int _filterIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await SupabaseService.getAllApplications();
      debugPrint('[AdminRequests] loaded ${data.length} applications');
      if (mounted) {
        setState(() {
          _applications = data;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[AdminRequests] error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    switch (_filterIndex) {
      case 1:
        return _applications.where((a) => a['status'] == 'new').toList();
      case 2:
        return _applications.where((a) => a['status'] == 'in_progress').toList();
      case 3:
        return _applications.where((a) => a['status'] == 'completed').toList();
      default:
        return _applications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Text(
                'Заявки',
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
                    AppFilterChip(label: 'Все (${_applications.length})', isSelected: _filterIndex == 0, onTap: () => setState(() => _filterIndex = 0)),
                    AppFilterChip(label: 'Новые', isSelected: _filterIndex == 1, onTap: () => setState(() => _filterIndex = 1)),
                    AppFilterChip(label: 'В работе', isSelected: _filterIndex == 2, onTap: () => setState(() => _filterIndex = 2)),
                    AppFilterChip(label: 'Завершённые', isSelected: _filterIndex == 3, onTap: () => setState(() => _filterIndex = 3)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: c.accent, strokeWidth: 2))
                  : filtered.isEmpty
                      ? Center(child: Text('Нет заявок', style: TextStyle(fontSize: 14, color: c.textHint)))
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: c.accent,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                            itemCount: filtered.length,
                            separatorBuilder: (context, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final app = filtered[index];
                              final status = app['status'] ?? 'new';
                              final userName = (app['profiles']?['full_name'] ?? '').toString();
                              final iin = (app['profiles']?['iin'] ?? '').toString();
                              final bin = (app['profiles']?['bin'] ?? '').toString();
                              final prop = app['properties'];
                              final address = prop?['address'] ?? '';
                              final propType = prop?['type'] ?? '';
                              final priority = app['priority'] ?? 'normal';
                              final priorityColor = priority == 'urgent'
                                  ? c.error
                                  : priority == 'high'
                                      ? c.warning
                                      : c.textHint;

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => _AdminApplicationDetailScreen(applicationId: app['id']),
                                    ),
                                  );
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: c.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: c.border, width: 1),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 38,
                                            height: 38,
                                            decoration: BoxDecoration(
                                              color: c.accent.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '#${(app['id'] ?? '').toString().substring(0, 4).toUpperCase()}',
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.accent),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(userName.isNotEmpty ? userName : 'Клиент',
                                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary)),
                                                if (iin.isNotEmpty)
                                                  Text('ИИН: $iin', style: TextStyle(fontSize: 11, color: c.textSecondary)),
                                                if (bin.isNotEmpty)
                                                  Text('БИН: $bin', style: TextStyle(fontSize: 11, color: c.textSecondary)),
                                              ],
                                            ),
                                          ),
                                          StatusBadge(status: badgeStatusFromKey(status), label: statusLabel(context, status), small: true),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on_rounded, size: 12, color: c.textHint),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(address.isNotEmpty ? '$propType · $address' : propType.isNotEmpty ? propType : '—',
                                                style: TextStyle(fontSize: 12, color: c.textSecondary),
                                                overflow: TextOverflow.ellipsis),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: priorityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                            child: Text(priority.toUpperCase(),
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: priorityColor)),
                                          ),
                                        ],
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
}

// ============================================
// ADMIN APPLICATION DETAIL
// ============================================

class _AdminApplicationDetailScreen extends StatefulWidget {
  final String applicationId;

  const _AdminApplicationDetailScreen({required this.applicationId});

  @override
  State<_AdminApplicationDetailScreen> createState() => _AdminApplicationDetailScreenState();
}

class _AdminApplicationDetailScreenState extends State<_AdminApplicationDetailScreen> {
  bool _loading = true;
  Map<String, dynamic>? _app;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await SupabaseService.getApplicationDetail(widget.applicationId);
      if (mounted) {
        setState(() {
          _app = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      if (newStatus == 'paid') {
        // Админ подтверждает оплату: создаём запись в payments, если её нет,
        // и сразу подтверждаем (заявка → paid).
        final existing =
            await PaymentService.getPaymentsForApplication(widget.applicationId);
        if (existing.isEmpty) {
          await PaymentService.createPayment(
            applicationId: widget.applicationId,
            amount: PaymentService.appraisalPrice,
            method: 'manual',
          );
        }
        final refreshed =
            await PaymentService.getPaymentsForApplication(widget.applicationId);
        if (refreshed.isNotEmpty &&
            refreshed.every((p) => p['status'] != 'paid')) {
          await PaymentService.confirmPayment(refreshed.first['id'] as String);
        }
      }
      await SupabaseService.updateApplicationStatus(widget.applicationId, newStatus);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Статус обновлён: ${statusLabel(context, newStatus)}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: c.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Заявка #${widget.applicationId.substring(0, 4).toUpperCase()}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.textPrimary)),
        centerTitle: true,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: c.accent, strokeWidth: 2))
          : _app == null
              ? Center(child: Text(_error ?? 'Заявка не найдена', style: TextStyle(color: c.textHint)))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: c.accent,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.all(24),
                    children: [
                      _detailHeader(c),
                      const SizedBox(height: 20),
                      _detailInfoCard(c, 'СТАТУС', [
                        _detailRow(c, 'Текущий статус', statusLabel(context, _app!['status'] ?? 'new')),
                        _detailRow(c, 'Приоритет', (_app!['priority'] ?? 'normal').toString().toUpperCase()),
                      ]),
                      const SizedBox(height: 16),
                      _detailInfoCard(c, 'СОБСТВЕННИК', [
                        _detailRow(c, 'ФИО', (_app!['profiles']?['full_name'] ?? '').toString()),
                        _detailRow(c, 'ИИН', (_app!['profiles']?['iin'] ?? '').toString()),
                        _detailRow(c, 'Телефон', (_app!['profiles']?['phone'] ?? '').toString()),
                        _detailRow(c, 'Email', (_app!['profiles']?['email'] ?? '').toString()),
                      ]),
                      const SizedBox(height: 16),
                      _detailInfoCard(c, 'ОБЪЕКТ', [
                        _detailRow(c, 'Тип', propertyTypeLabel(context, (_app!['properties']?['type'] ?? '').toString())),
                        _detailRow(c, 'Адрес', (_app!['properties']?['address'] ?? '').toString()),
                        _detailRow(c, 'Площадь', '${_app!['properties']?['area'] ?? 0} м²'),
                        if (_app!['properties']?['rooms'] != null)
                          _detailRow(c, 'Комнат', '${_app!['properties']?['rooms']}'),
                        if (_app!['properties']?['floor'] != null)
                          _detailRow(c, 'Этаж', '${_app!['properties']?['floor']}'),
                      ]),
                      if (_app!['estimated_price'] != null) ...[
                        const SizedBox(height: 16),
                        _detailInfoCard(c, 'ОЦЕНКА', [
                          _detailRow(c, 'Оценочная стоимость', '${_app!['estimated_price']} ₸', highlight: true),
                        ]),
                      ],
                      const SizedBox(height: 24),
                      _statusActions(c),
                    ],
                  ),
                ),
    );
  }

  Widget _detailHeader(AppColors c) {
    final status = _app!['status'] ?? 'new';
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '#${(_app!['id'] ?? '').toString().substring(0, 4).toUpperCase()}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.accent),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (_app!['profiles']?['full_name'] ?? '').toString(),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  (_app!['properties']?['address'] ?? '').toString(),
                  style: TextStyle(fontSize: 13, color: c.textSecondary),
                ),
              ],
            ),
          ),
          StatusBadge(status: badgeStatusFromKey(status), label: statusLabel(context, status)),
        ],
      ),
    );
  }

  Widget _detailInfoCard(AppColors c, String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.textSecondary, letterSpacing: 0.8)),
          const SizedBox(height: 14),
          ...rows,
        ],
      ),
    );
  }

  Widget _detailRow(AppColors c, String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: c.textSecondary)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: TextStyle(
                fontSize: 13,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                color: highlight ? c.accent : c.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusActions(AppColors c) {
    final status = _app!['status'] ?? 'new';
    final actions = <Map<String, dynamic>>[];

    if (status == 'new') {
      actions.add({'label': 'Взять в работу', 'status': 'in_progress', 'color': c.info});
    }
    if (status == 'in_progress') {
      actions.add({'label': 'Завершить', 'status': 'completed', 'color': c.success});
      actions.add({'label': 'Отклонить', 'status': 'rejected', 'color': c.error});
    }
    if (status == 'completed') {
      actions.add({'label': 'Отметить оплату', 'status': 'paid', 'color': c.gold});
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ДЕЙСТВИЯ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.textSecondary, letterSpacing: 0.8)),
        const SizedBox(height: 12),
        ...actions.map((a) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _updateStatus(a['status']),
              style: ElevatedButton.styleFrom(
                backgroundColor: a['color'],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: Text(a['label'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        )),
      ],
    );
  }
}

// ============================================
// ADMIN PAYMENTS
// ============================================

class _AdminPayments extends StatefulWidget {
  const _AdminPayments();

  @override
  State<_AdminPayments> createState() => _AdminPaymentsState();
}

class _AdminPaymentsState extends State<_AdminPayments> {
  bool _loading = true;
  List<Map<String, dynamic>> _payments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await PaymentService.getAllPayments();
      if (mounted) {
        setState(() {
          _payments = data;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[AdminPayments] error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm(String paymentId) async {
    try {
      await PaymentService.confirmPayment(paymentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Платёж подтверждён, заявка оплачена')),
        );
        _load();
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
      appBar: AppBar(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Платежи',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: c.accent, strokeWidth: 2))
          : _payments.isEmpty
              ? Center(
                  child: Text(
                    'Платежей пока нет',
                    style: TextStyle(color: c.textSecondary),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _payments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) =>
                        _paymentCard(c, _payments[i]),
                  ),
                ),
    );
  }

  Widget _paymentCard(AppColors c, Map<String, dynamic> p) {
    final status = (p['status'] as String?) ?? 'pending';
    final paid = status == 'paid';
    final method = (p['method'] as String?) ?? 'manual';
    final amount = (p['amount'] as num?)?.toInt() ?? 0;
    final appId = (p['application_id'] as String?) ?? '';
    final createdAt = p['created_at'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Заявка ${PaymentService.applicationNumber(appId)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      (paid ? c.success : c.warning).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  PaymentService.statusLabel(status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: paid ? c.success : c.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${PaymentService.methodLabel(method)} · $amount ₸',
            style: TextStyle(fontSize: 13, color: c.textSecondary),
          ),
          if (createdAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Создан: ${_formatDate(createdAt)}',
              style: TextStyle(fontSize: 12, color: c.textHint),
            ),
          ],
          if (!paid) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _confirm(p['id'] as String),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Подтвердить оплату',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.'
          '${dt.month.toString().padLeft(2, '0')}.'
          '${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

// ============================================
// ADMIN DOCUMENTS
// ============================================

class _AdminDocuments extends StatefulWidget {
  const _AdminDocuments();

  @override
  State<_AdminDocuments> createState() => _AdminDocumentsState();
}

class _AdminDocumentsState extends State<_AdminDocuments> {
  bool _loading = true;
  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await SupabaseService.getAllDocuments();
      debugPrint('[AdminDocs] loaded ${data.length} documents');
      if (mounted) {
        setState(() {
          _documents = data;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[AdminDocs] error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Открыть документ: изображение — превью в диалоге, PDF — новая вкладка.
  Future<void> _openDocument(Map<String, dynamic> doc) async {
    final filePath = doc['file_url']?.toString();
    if (filePath == null || filePath.isEmpty) return;

    final String url;
    try {
      url = await SupabaseService.getDocumentUrl(filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка открытия документа: $e')),
        );
      }
      return;
    }

    final fileType = (doc['file_type'] ?? '').toString().toLowerCase();
    if (!mounted) return;

    if (fileType == 'jpg' || fileType == 'jpeg' || fileType == 'png') {
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          final c = AppColors.of(ctx);
          return Dialog(
            backgroundColor: c.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          doc['name'] ?? 'Просмотр',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(18),
                    ),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Padding(
                        padding: const EdgeInsets.all(40),
                        child: Icon(Icons.broken_image_rounded,
                            size: 48, color: c.muted),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  /// Удалить документ с подтверждением (и файл из Storage, и запись).
  Future<void> _deleteDocument(Map<String, dynamic> doc) async {
    final c = AppColors.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Удалить документ?'),
        content: Text(
          '«${doc['name']}» будет удалён. '
          'Пользователь сможет загрузить его заново.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Удалить', style: TextStyle(color: c.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await SupabaseService.deleteDocument(
        doc['id'].toString(),
        filePath: doc['file_url']?.toString(),
      );
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Документ удалён')),
        );
      }
    } catch (e) {
      debugPrint('[AdminDocs] delete error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка удаления')),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Документы',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: c.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: c.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_documents.length}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.accent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: c.accent, strokeWidth: 2))
                  : _documents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_open_rounded, size: 56, color: c.muted),
                              const SizedBox(height: 16),
                              Text('Нет документов', style: TextStyle(fontSize: 16, color: c.textSecondary)),
                              const SizedBox(height: 6),
                              Text('Документы появятся после загрузки пользователями',
                                  style: TextStyle(fontSize: 13, color: c.textHint)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: c.accent,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                            itemCount: _documents.length,
                            separatorBuilder: (context, _) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final doc = _documents[index];
                              final fileType = (doc['file_type'] ?? '').toString().toLowerCase();
                              final userName = (doc['profiles']?['full_name'] ?? '').toString();
                              final fileSize = doc['file_size'];
                              final createdAt = doc['created_at']?.toString();
                              final sizeLabel = fileSize != null
                                  ? _formatFileSize((fileSize as num).toDouble())
                                  : '';
                              final dateLabel = createdAt != null
                                  ? _formatDate(createdAt)
                                  : '';

                              return GestureDetector(
                                onTap: () => _openDocument(doc),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: c.surface,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: c.border, width: 1),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: _fileColor(c, fileType).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(_fileIcon(fileType), color: _fileColor(c, fileType), size: 20),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                doc['name'] ?? '',
                                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.textPrimary),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                userName.isNotEmpty ? '$userName · $sizeLabel' : sizeLabel,
                                                style: TextStyle(fontSize: 12, color: c.textSecondary),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (dateLabel.isNotEmpty)
                                          Text(dateLabel, style: TextStyle(fontSize: 11, color: c.textHint)),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          tooltip: 'Открыть',
                                          icon: Icon(
                                            Icons.visibility_outlined,
                                            size: 20,
                                            color: c.accent,
                                          ),
                                          onPressed: () => _openDocument(doc),
                                        ),
                                        IconButton(
                                          tooltip: 'Удалить',
                                          icon: Icon(
                                            Icons.delete_outline_rounded,
                                            size: 20,
                                            color: c.error,
                                          ),
                                          onPressed: () => _deleteDocument(doc),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ).animate(delay: 60.ms * index)
                                  .fadeIn(duration: 300.ms)
                                  .slideY(begin: 0.08);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(double bytes) {
    if (bytes < 1024) return '${bytes.round()} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Color _fileColor(AppColors c, String type) => switch (type) {
        'pdf' => const Color(0xFFEF4444),
        'jpg' || 'jpeg' => const Color(0xFF38BDF8),
        'png' => const Color(0xFF2DD4A8),
        _ => c.textSecondary,
      };

  IconData _fileIcon(String type) => switch (type) {
        'pdf' => Icons.picture_as_pdf_rounded,
        'jpg' || 'jpeg' => Icons.photo_rounded,
        'png' => Icons.image_rounded,
        _ => Icons.insert_drive_file_rounded,
      };
}

// ============================================
// ADMIN LOGS
// ============================================

class _AdminLogs extends StatefulWidget {
  const _AdminLogs();

  @override
  State<_AdminLogs> createState() => _AdminLogsState();
}

class _AdminLogsState extends State<_AdminLogs> {
  bool _loading = true;
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await SupabaseService.getAdminActivityLogs();
      debugPrint('[AdminLogs] loaded ${data.length} logs');
      if (mounted) {
        setState(() {
          _logs = data;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[AdminLogs] error: $e');
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
                'Логи',
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
                  : _logs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_rounded, size: 56, color: c.muted),
                              const SizedBox(height: 16),
                              Text('Нет записей', style: TextStyle(fontSize: 16, color: c.textSecondary)),
                              const SizedBox(height: 6),
                              Text('Логи появятся после действий пользователей',
                                  style: TextStyle(fontSize: 13, color: c.textHint)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: c.accent,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                            itemCount: _logs.length,
                            separatorBuilder: (context, _) => Container(height: 1, color: c.border),
                            itemBuilder: (context, index) {
                              final log = _logs[index];
                              final action = log['action'] ?? '';
                              final userName = (log['profiles']?['full_name'] ?? '').toString();
                              final createdAt = log['created_at']?.toString() ?? '';
                              String date = '';
                              if (createdAt.isNotEmpty) {
                                try {
                                  final dt = DateTime.parse(createdAt).toLocal();
                                  date = '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                                } catch (_) {
                                  date = createdAt;
                                }
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: c.info.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.event_note_rounded, size: 16, color: c.info),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _actionLabel(action),
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.textPrimary),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$userName · $date',
                                            style: TextStyle(fontSize: 11, color: c.textSecondary),
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

  String _actionLabel(String action) {
    switch (action) {
      case 'application_assigned':
        return 'Заявка назначена';
      case 'application_completed':
        return 'Заявка завершена';
      case 'appraisal_created':
        return 'Оценка создана';
      case 'appraisal_signed':
        return 'Оценка подписана ЭЦП';
      case 'user_role_changed':
        return 'Роль пользователя изменена';
      case 'user_blocked':
        return 'Пользователь заблокирован';
      case 'user_unblocked':
        return 'Пользователь разблокирован';
      case 'user_profile_updated':
        return 'Профиль пользователя обновлён';
      case 'application_status_changed':
        return 'Статус заявки изменён';
      default:
        return action;
    }
  }
}

// ============================================
// ADMIN PROFILE
// ============================================

class _AdminProfile extends StatelessWidget {
  final UserProfile? profile;
  final VoidCallback onRefresh;

  const _AdminProfile({required this.profile, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final name = profile?.fullName ?? '';
    final email = profile?.email ?? SupabaseService.currentUser?.email ?? '';

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
                    decoration: BoxDecoration(color: c.error, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        profile?.initials ?? 'А',
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
                        Text('Администратор', style: TextStyle(fontSize: 13, color: c.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: c.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.admin_panel_settings_rounded, size: 14, color: c.error),
                        const SizedBox(width: 4),
                        Text('Админ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.error)),
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
                  infoRow(context, 'Email', email),
                  divider(context),
                  infoRow(context, 'Роль', 'Администратор'),
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

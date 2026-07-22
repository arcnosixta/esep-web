import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/border_icon.dart';
import '../widgets/information_tile.dart';
import '../widgets/status_badge.dart';
import '../services/supabase_service.dart';
import '../utils/formatters.dart';
import 'egov_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _properties = [];
  List<Map<String, dynamic>> _documents = [];
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        SupabaseService.getProfile(),
        SupabaseService.getProperties(),
        SupabaseService.getDocuments(),
        SupabaseService.getApplications(),
      ]);
      if (mounted) {
        setState(() {
          _profile = results[0] as Map<String, dynamic>?;
          _properties = results[1] as List<Map<String, dynamic>>;
          _documents = results[2] as List<Map<String, dynamic>>;
          _history = results[3] as List<Map<String, dynamic>>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _getInitials() {
    final name = _profile?['full_name'] ?? '';
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    final name = _profile?['full_name'] ?? 'Без имени';
    final iin = _profile?['iin'] ?? 'Не указан';
    final phone = _profile?['phone'] ?? 'Не указан';
    final email = _profile?['email'] ??
        SupabaseService.currentUser?.email ??
        'Не указан';
    final role = _profile?['role'] == 'appraiser'
        ? 'Оценщик'
        : _profile?['role'] == 'admin'
            ? 'Администратор'
            : 'Клиент';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.accent,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ── Title ──
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                  child: const Text(
                    'ПРОФИЛЬ',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),

              // ── Profile card ──
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(24, 0, 16, 20),
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 20),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.divider,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        BorderIcon(
                          width: 56,
                          height: 56,
                          padding: EdgeInsets.zero,
                          borderRadius: 28,
                          backgroundColor: AppColors.accent,
                          borderColor: AppColors.accent,
                          child: Text(
                            _getInitials(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                role,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded,
                                  size: 14, color: AppColors.success),
                              SizedBox(width: 4),
                              Text(
                                'Верифицирован',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Stats ──
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(24, 0, 16, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      InformationTile(
                        content: '${_properties.length}',
                        name: 'Объектов',
                        icon: Icons.home_rounded,
                        valueColor: AppColors.accent,
                      ),
                      InformationTile(
                        content: '${_documents.length}',
                        name: 'Документов',
                        icon: Icons.folder_rounded,
                        valueColor: AppColors.warning,
                      ),
                      InformationTile(
                        content: '${_history.length}',
                        name: 'Оценок',
                        icon: Icons.assessment_rounded,
                        valueColor: AppColors.success,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Personal info ──
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.paper,
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                  child: Column(
                    children: [
                      infoRow('ИИН', iin),
                      divider(),
                      infoRow('Телефон', phone),
                      divider(),
                      infoRow('Email', email),
                      divider(),
                      infoRow('Роль', role),
                    ],
                  ),
                ),
              ),

              // ── EGOV ──
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ГОСУСЛУГИ (EGOV)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(
                              color: AppColors.info,
                              width: 3,
                            ),
                            top: BorderSide(
                              color: AppColors.divider,
                              width: 1,
                            ),
                            right: BorderSide(
                              color: AppColors.divider,
                              width: 1,
                            ),
                            bottom: BorderSide(
                              color: AppColors.divider,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            BorderIcon(
                              width: 40,
                              height: 40,
                              padding: EdgeInsets.zero,
                              borderRadius: 10,
                              backgroundColor: AppColors.info.withValues(alpha: 0.1),
                              borderColor: AppColors.info.withValues(alpha: 0.2),
                              child: const Icon(
                                Icons.account_balance_rounded,
                                color: AppColors.info,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ЭЦП статус',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Подключение к Госуслугам',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const EgovScreen()),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: AppColors.info, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: const Text(
                            'Открыть',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Properties ──
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.paper,
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'МОЁ ИМУЩЕСТВО',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        '${_properties.length} объектов',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_properties.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.paper,
                    padding: const EdgeInsets.fromLTRB(24, 16, 16, 20),
                    child: const Text(
                      'Пока нет имущества',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.paper,
                    padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
                    child: Column(
                      children: [
                        for (int i = 0; i < _properties.length; i++) ...[
                          if (i > 0) divider(),
                          _buildPropertyRow(_properties[i]),
                        ],
                      ],
                    ),
                  ),
                ),

              // ── Documents ──
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'МОИ ДОКУМЕНТЫ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        '${_documents.length} файлов',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_documents.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.fromLTRB(24, 16, 16, 20),
                    child: const Text(
                      'Пока нет документов',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
                    child: Column(
                      children: [
                        for (int i = 0; i < _documents.length; i++) ...[
                          if (i > 0) divider(),
                          _buildDocumentRow(_documents[i]),
                        ],
                      ],
                    ),
                  ),
                ),

              // ── History ──
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.paper,
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
                  child: const Text(
                    'ИСТОРИЯ ОЦЕНОК',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              if (_history.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.paper,
                    padding: const EdgeInsets.fromLTRB(24, 16, 16, 20),
                    child: const Text(
                      'Пока нет оценок',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.paper,
                    padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
                    child: Column(
                      children: [
                        for (int i = 0; i < _history.length; i++) ...[
                          if (i > 0) divider(),
                          _buildHistoryRow(_history[i]),
                        ],
                      ],
                    ),
                  ),
                ),

              // ── Settings ──
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.muted,
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 40),
                  child: Column(
                    children: [
                      _settingsRow(
                          Icons.settings_rounded, 'Настройки'),
                      divider(),
                      _settingsRow(
                          Icons.help_rounded, 'Помощь'),
                      divider(),
                      _settingsRow(
                          Icons.info_outline_rounded, 'О приложении'),
                      divider(),
                      _settingsRow(Icons.logout_rounded, 'Выйти',
                          color: AppColors.error, onTap: _signOut),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyRow(Map<String, dynamic> item) {
    final type = item['type'] ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          BorderIcon(
            width: 40,
            height: 40,
            padding: EdgeInsets.zero,
            borderRadius: 10,
            backgroundColor: propertyTypeColor(type).withValues(alpha: 0.1),
            borderColor: propertyTypeColor(type).withValues(alpha: 0.2),
            child: Icon(
              propertyTypeIcon(type),
              color: propertyTypeColor(type),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  propertyTypeLabel(type),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item['area'] ?? 0} м² · ${item['address'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textHint,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(Map<String, dynamic> doc) {
    final fileType = doc['file_type'] ?? 'pdf';
    final color = fileType == 'pdf'
        ? const Color(0xFFEF4444)
        : fileType == 'jpg'
            ? const Color(0xFF38BDF8)
            : const Color(0xFF2DD4A8);
    final icon = fileType == 'pdf'
        ? Icons.picture_as_pdf_rounded
        : fileType == 'jpg'
            ? Icons.photo_rounded
            : Icons.image_rounded;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          BorderIcon(
            width: 40,
            height: 40,
            padding: EdgeInsets.zero,
            borderRadius: 10,
            backgroundColor: color.withValues(alpha: 0.1),
            borderColor: color.withValues(alpha: 0.2),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  doc['created_at'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textHint,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(Map<String, dynamic> item) {
    final status = item['status'] ?? 'new';
    final prop = item['properties'];
    final propType = prop != null ? (prop['type'] ?? '') : '';
    final price = item['estimated_price'];
    final priceStr =
        price != null ? '${price.toStringAsFixed(0)} ₸' : 'Не оценено';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          BorderIcon(
            width: 40,
            height: 40,
            padding: EdgeInsets.zero,
            borderRadius: 10,
            backgroundColor: AppColors.accent.withValues(alpha: 0.1),
            borderColor: AppColors.accent.withValues(alpha: 0.2),
            child: Center(
              child: Text(
                '#${(item['id'] ?? '').toString().substring(0, 4).toUpperCase()}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      propertyTypeLabel(propType),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    StatusBadge(
                      status: badgeStatusFromKey(status),
                      label: statusLabel(status),
                      small: true,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  priceStr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsRow(IconData icon, String label,
      {Color? color, VoidCallback? onTap}) {
    final effectiveColor = color ?? AppColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: effectiveColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: effectiveColor,
                ),
              ),
            ),
            if (color == null)
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textHint,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Выйти из аккаунта?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Вы сможете войти снова',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Выйти',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await SupabaseService.signOut();
    }
  }
}

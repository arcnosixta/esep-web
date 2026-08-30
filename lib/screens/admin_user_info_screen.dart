import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/supabase_service.dart';
import '../utils/iin_validator.dart';

/// Экран админа: вся доступная информация по ИИН/БИН пользователя.
///
/// Два слоя данных:
/// 1. Что указал сам пользователь в профиле (ФИО, телефон, email) —
///    может быть не настоящим.
/// 2. Что зашито в самом номере ИИН (дата рождения, пол, век) —
///    не зависит от пользователя. Настоящее ФИО по ИИН будет доступно
///    после подключения ГБД ФЛ (MINJ-S-0086, этап 2) — см. блок-заглушку.
class AdminUserInfoScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminUserInfoScreen({super.key, required this.user});

  @override
  State<AdminUserInfoScreen> createState() => _AdminUserInfoScreenState();
}

class _AdminUserInfoScreenState extends State<AdminUserInfoScreen> {
  List<Map<String, dynamic>> _applications = [];
  List<Map<String, dynamic>> _documents = [];
  bool _loadingApps = true;
  bool _loadingDocs = true;

  @override
  void initState() {
    super.initState();
    _loadApplications();
    _loadDocuments();
  }

  Future<void> _loadApplications() async {
    try {
      final apps = await SupabaseService.getApplicationsForUser(
        (widget.user['user_id'] ?? '').toString(),
      );
      if (mounted) {
        setState(() {
          _applications = apps;
          _loadingApps = false;
        });
      }
    } catch (e) {
      debugPrint('[AdminUserInfo] apps error: $e');
      if (mounted) setState(() => _loadingApps = false);
    }
  }

  Future<void> _loadDocuments() async {
    try {
      final docs = await SupabaseService.getDocumentsForUser(
        (widget.user['user_id'] ?? '').toString(),
      );
      if (mounted) {
        setState(() {
          _documents = docs;
          _loadingDocs = false;
        });
      }
    } catch (e) {
      debugPrint('[AdminUserInfo] docs error: $e');
      if (mounted) setState(() => _loadingDocs = false);
    }
  }

  String _fmtDate(Object? v) {
    final s = v?.toString() ?? '';
    if (s.isEmpty) return '—';
    // ISO-строка '2026-08-09T...' → '09.08.2026'
    final d = DateTime.tryParse(s);
    if (d == null) return s;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'new':
        return 'Новая';
      case 'in_progress':
        return 'В работе';
      case 'completed':
        return 'Завершена';
      case 'cancelled':
        return 'Отменена';
      case 'paid':
        return 'Оплачена';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final u = widget.user;
    final isOrg = (u['client_type'] ?? 'person') == 'org';
    final iin = (u['iin'] ?? '').toString();
    final bin = (u['bin'] ?? '').toString();
    final idNumber = isOrg ? bin : iin;
    final info = idNumber.isNotEmpty ? IinValidator.decode(idNumber) : null;
    final blocked = u['is_blocked'] == true;
    final role = u['role'] ?? 'client';
    final fullName = (u['full_name'] ?? '').toString();

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        foregroundColor: c.textPrimary,
        elevation: 0,
        title: const Text('Информация по ИИН',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ===== Шапка: ФИО + роль/статус =====
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
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: (blocked ? c.error : c.accent).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: blocked ? c.error : c.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fullName.isNotEmpty ? fullName : '—',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary)),
                      const SizedBox(height: 3),
                      Text(
                        isOrg
                            ? 'Юрлицо · ${(u['org_name'] ?? '—').toString()}'
                            : role == 'appraiser'
                                ? 'Оценщик'
                                : 'Физлицо',
                        style: TextStyle(fontSize: 13, color: c.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _pill(c, role == 'appraiser' ? 'Оценщик' : 'Клиент',
                              role == 'appraiser' ? c.success : c.accent),
                          if (blocked) ...[
                            const SizedBox(width: 6),
                            _pill(c, 'Заблокирован', c.error),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ===== Идентификация по номеру =====
          _sectionTitle(c, 'Идентификация по номеру'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border, width: 1),
            ),
            child: Column(
              children: [
                _row(c, Icons.badge_rounded, isOrg ? 'БИН' : 'ИИН', idNumber),
                if (info == null && idNumber.isNotEmpty)
                  _row(c, Icons.warning_amber_rounded, 'Проверка',
                      'Номер не прошёл checksum-валидацию',
                      valueColor: c.error),
                if (info != null && !info.isOrg) ...[
                  _divider(c),
                  _row(c, Icons.cake_rounded, 'Дата рождения (из ИИН)',
                      info.birthDateLabel, valueColor: c.accent),
                  _row(c, Icons.wc_rounded, 'Пол (из ИИН)', info.gender,
                      valueColor: c.accent),
                  _row(c, Icons.history_rounded, 'Век (из ИИН)',
                      info.centuryLabel, valueColor: c.accent),
                ],
                if (isOrg) ...[
                  _divider(c),
                  _row(c, Icons.business_rounded, 'Наименование',
                      (u['org_name'] ?? '—').toString()),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user_rounded, size: 18, color: c.warning),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Дата рождения и пол зашиты в сам ИИН — их нельзя подделать '
                    'при регистрации. Настоящее ФИО по ИИН (ГБД ФЛ) появится '
                    'после подключения к государственной базе — этап 2.',
                    style: TextStyle(fontSize: 12.5, height: 1.4, color: c.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ===== Контакты (как указал пользователь) =====
          _sectionTitle(c, 'Контакты (указаны пользователем)'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border, width: 1),
            ),
            child: Column(
              children: [
                _row(c, Icons.phone_rounded, 'Телефон',
                    (u['phone'] ?? '').toString().isEmpty
                        ? '—'
                        : u['phone'].toString()),
                _divider(c),
                _row(c, Icons.email_rounded, 'Email',
                    (u['email'] ?? '').toString().isEmpty
                        ? '—'
                        : u['email'].toString()),
                _divider(c),
                _row(c, Icons.calendar_today_rounded, 'Регистрация',
                    _fmtDate(u['created_at'])),
                _divider(c),
                _row(c, Icons.account_circle_rounded, 'ID аккаунта',
                    (u['user_id'] ?? '—').toString()),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ===== Медиа профиля =====
          _sectionTitle(c, 'Профиль'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border, width: 1),
            ),
            child: Column(
              children: [
                if ((u['avatar_url'] ?? '').toString().isEmpty && (u['cover_url'] ?? '').toString().isEmpty)
                  Text('Нет фото профиля или обложки', style: TextStyle(fontSize: 13, color: c.textHint))
                else ...[
                  if ((u['cover_url'] ?? '').toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          u['cover_url'].toString(),
                          width: double.infinity,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 120,
                            color: c.inputFill,
                            child: Icon(Icons.image_rounded, color: c.textHint),
                          ),
                        ),
                      ),
                    ),
                  if ((u['avatar_url'] ?? '').toString().isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage(u['avatar_url'].toString()),
                        onBackgroundImageError: (_, __) {},
                        child: (u['avatar_url'] ?? '').toString().isEmpty
                            ? Icon(Icons.person_rounded, color: c.textHint)
                            : null,
                      ),
                    )
                ]
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ===== Заявки пользователя =====
          _sectionTitle(c, 'Заявки (${_loadingApps ? '…' : _applications.length})'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border, width: 1),
            ),
            child: _loadingApps
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                          color: c.accent, strokeWidth: 2),
                    ),
                  )
                : _applications.isEmpty
                    ? Text('Заявок нет',
                        style: TextStyle(fontSize: 13, color: c.textHint))
                    : Column(
                        children: _applications.take(10).map((app) {
                          final status = (app['status'] ?? 'new').toString();
                          final prop = app['properties'];
                          final address = (prop?['address'] ?? '—').toString();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Icon(Icons.assignment_rounded,
                                    size: 15, color: c.textHint),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(address,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: c.textPrimary),
                                      overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 8),
                                Text(_statusLabel(status),
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: c.textSecondary)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
          ),
          const SizedBox(height: 14),
          _sectionTitle(c, 'Документы (${_loadingDocs ? '…' : _documents.length})'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border, width: 1),
            ),
            child: _loadingDocs
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircularProgressIndicator(color: c.accent, strokeWidth: 2),
                    ),
                  )
                : _documents.isEmpty
                    ? Text('Документов нет', style: TextStyle(fontSize: 13, color: c.textHint))
                    : Column(
                        children: _documents.take(20).map((doc) {
                          final name = (doc['name'] ?? '').toString();
                          final created = (doc['created_at'] ?? '').toString();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Icon(Icons.folder_rounded, size: 15, color: c.textHint),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(name.isEmpty ? 'Документ' : name,
                                      style: TextStyle(fontSize: 13, color: c.textPrimary),
                                      overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 8),
                                Text(_fmtDate(created),
                                    style: TextStyle(fontSize: 12, color: c.textSecondary)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionTitle(AppColors c, String title) {
    return Text(title,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: c.textSecondary));
  }

  Widget _pill(AppColors c, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _divider(AppColors c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Container(height: 1, color: c.border),
      );

  Widget _row(AppColors c, IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: c.textHint),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: TextStyle(fontSize: 13.5, color: c.textSecondary)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? c.textPrimary)),
        ),
      ],
    );
  }
}

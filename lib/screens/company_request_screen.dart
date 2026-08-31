import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/supabase_service.dart';
import '../l10n/app_strings.dart';

class CompanyRequestScreen extends StatefulWidget {
  const CompanyRequestScreen({super.key});

  @override
  State<CompanyRequestScreen> createState() => _CompanyRequestScreenState();
}

class _CompanyRequestScreenState extends State<CompanyRequestScreen> {
  bool _loading = true;
  Map<String, dynamic>? _company;
  List<Map<String, dynamic>> _requests = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        SupabaseService.getMyCompany(),
        SupabaseService.getMyApiKeyRequests(),
      ]);
      if (mounted) {
        setState(() {
          _company = results[0] as Map<String, dynamic>?;
          _requests = results[1] as List<Map<String, dynamic>>;
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

  Future<void> _requestApiKey() async {
    final reasonController = TextEditingController();
    final c = AppColors.of(context);
    final s = AppStrings.of(context);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(
          'Запросить API-ключ',
          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'После одобрения админом ключ будет показан только один раз.',
                style: TextStyle(fontSize: 13, color: c.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Причина запроса',
                  hintText: 'Например, интеграция с CRM',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.border),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel, style: TextStyle(color: c.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              try {
                await SupabaseService.requestApiKey(
                  companyId: _company!['id'] as String,
                  reason: reason,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                await _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Запрос отправлен')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              }
            },
            child: Text(
              'Отправить',
              style: TextStyle(color: c.accent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final s = AppStrings.of(context);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        foregroundColor: c.textPrimary,
        elevation: 0,
        title: const Text(
          'API-доступ компании',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: c.accent, strokeWidth: 2))
          : _error != null
              ? Center(child: Text('Ошибка: $_error', style: TextStyle(color: c.textHint)))
              : _company == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.business_rounded, size: 48, color: c.textHint),
                            const SizedBox(height: 12),
                            Text(
                              'Сначала создайте профиль компании в редактировании профиля.',
                              style: TextStyle(fontSize: 14, color: c.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: c.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: c.border, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _company!['name'] as String? ?? 'Компания',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: c.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'БИН: ${_company!['bin'] ?? ''}',
                                style: TextStyle(fontSize: 13, color: c.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Статус компании: ${_company!['status'] ?? 'pending_verification'}',
                                style: TextStyle(fontSize: 12, color: c.textHint),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'МОИ ЗАПРОСЫ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: c.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_requests.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: c.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: c.border, width: 1),
                            ),
                            child: Text(
                              'Запросов пока нет',
                              style: TextStyle(fontSize: 13, color: c.textHint),
                            ),
                          )
                        else
                          Column(
                            children: _requests.map((r) {
                              final status = r['status'] as String? ?? 'pending';
                              final statusColor = status == 'approved'
                                  ? c.success
                                  : status == 'rejected'
                                      ? c.error
                                      : c.warning;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
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
                                        Expanded(
                                          child: Text(
                                            'Запрос API-ключа',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: c.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            status.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: statusColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    if ((r['reason'] as String? ?? '').isNotEmpty)
                                      Text(
                                        r['reason'],
                                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _requests.any(
                                (r) => (r['status'] as String? ?? '') == 'pending')
                                ? null
                                : _requestApiKey,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Запросить API-ключ',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

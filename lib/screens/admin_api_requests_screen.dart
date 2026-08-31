import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/supabase_service.dart';

class AdminApiRequestsScreen extends StatefulWidget {
  const AdminApiRequestsScreen({super.key});

  @override
  State<AdminApiRequestsScreen> createState() => _AdminApiRequestsScreenState();
}

class _AdminApiRequestsScreenState extends State<AdminApiRequestsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await SupabaseService.getAllApiKeyRequests();
      if (mounted) {
        setState(() {
          _requests = data;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[AdminApiRequests] error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(Map<String, dynamic> request) async {
    try {
      await SupabaseService.approveApiKeyRequest(request['id'] as String);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Запрос одобрен')),
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

  Future<void> _reject(Map<String, dynamic> request) async {
    try {
      await SupabaseService.rejectApiKeyRequest(request['id'] as String);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Запрос отклонён')),
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
      appBar: AppBar(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Запросы API-ключей',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: c.accent, strokeWidth: 2))
          : _requests.isEmpty
              ? Center(
                  child: Text(
                    'Запросов пока нет',
                    style: TextStyle(color: c.textSecondary),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: c.accent,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final request = _requests[index];
                      final company = request['companies'] as Map<String, dynamic>?;
                      final profile = request['profiles'] as Map<String, dynamic>?;
                      final status = request['status'] as String? ?? 'pending';

                      return Container(
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
                                    company?['name']?.toString() ?? 'Компания',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: status == 'approved'
                                        ? c.success.withValues(alpha: 0.12)
                                        : status == 'rejected'
                                            ? c.error.withValues(alpha: 0.12)
                                            : c.warning.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: status == 'approved'
                                          ? c.success
                                          : status == 'rejected'
                                              ? c.error
                                              : c.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'БИН: ${company?['bin'] ?? '-'}',
                              style: TextStyle(fontSize: 12, color: c.textSecondary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Заявитель: ${profile?['full_name'] ?? '-'}',
                              style: TextStyle(fontSize: 12, color: c.textSecondary),
                            ),
                            if ((request['reason'] as String? ?? '').isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Причина: ${request['reason']}',
                                style: TextStyle(fontSize: 12, color: c.textHint),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: status != 'pending' ? null : () => _approve(request),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: c.success,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'Одобрить',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: status != 'pending' ? null : () => _reject(request),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: c.error,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'Отклонить',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

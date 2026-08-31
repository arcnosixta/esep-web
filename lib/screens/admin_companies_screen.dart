import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/supabase_service.dart';

class AdminCompaniesScreen extends StatefulWidget {
  const AdminCompaniesScreen({super.key});

  @override
  State<AdminCompaniesScreen> createState() => _AdminCompaniesScreenState();
}

class _AdminCompaniesScreenState extends State<AdminCompaniesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _loading = true;
  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        SupabaseService.getUnverifiedCompanies(),
        SupabaseService.getAllApiKeyRequests(),
      ]);
      if (mounted) {
        setState(() {
          _companies = results[0] as List<Map<String, dynamic>>;
          _requests = results[1] as List<Map<String, dynamic>>;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[AdminCompanies] error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyCompany(String companyId) async {
    try {
      await SupabaseService.verifyCompany(companyId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Компания подтверждена')),
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
          'Компании и API',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: c.accent,
          labelColor: c.accent,
          unselectedLabelColor: c.textSecondary,
          tabs: const [
            Tab(text: 'Компании'),
            Tab(text: 'Запросы ключей'),
          ],
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: c.accent, strokeWidth: 2))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCompaniesTab(c),
                _buildRequestsTab(c),
              ],
            ),
    );
  }

  Widget _buildCompaniesTab(AppColors c) {
    if (_companies.isEmpty) {
      return Center(
        child: Text('Нет неподтверждённых компаний',
            style: TextStyle(color: c.textSecondary)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: c.accent,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _companies.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final company = _companies[index];
          final name = company['name']?.toString() ?? 'Компания';
          final bin = company['bin']?.toString() ?? '-';

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.border, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary)),
                      const SizedBox(height: 4),
                      Text('БИН: $bin',
                          style: TextStyle(fontSize: 12, color: c.textSecondary)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _verifyCompany(company['id'].toString()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    elevation: 0,
                  ),
                  child: const Text('Подтвердить',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestsTab(AppColors c) {
    final pending = _requests.where((r) => (r['status'] ?? '') == 'pending').toList();

    if (pending.isEmpty) {
      return Center(
        child: Text('Нет новых запросов API-ключей',
            style: TextStyle(color: c.textSecondary)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: c.accent,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: pending.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final request = pending[index];
          final company = request['companies'] as Map<String, dynamic>?;
          final profile = request['profiles'] as Map<String, dynamic>?;
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
                Text(company?['name']?.toString() ?? 'Компания',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary)),
                const SizedBox(height: 4),
                Text('Заявитель: ${profile?['full_name'] ?? '-'}',
                    style: TextStyle(fontSize: 12, color: c.textSecondary)),
              ],
            ),
          );
        },
      ),
    );
  }
}

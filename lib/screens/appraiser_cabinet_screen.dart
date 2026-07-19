import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/status_badge.dart';

class _AppraiserJob {
  final String address;
  final String area;
  final String date;
  final BadgeStatus status;
  final String statusLabel;

  const _AppraiserJob({
    required this.address,
    required this.area,
    required this.date,
    required this.status,
    required this.statusLabel,
  });
}

class AppraiserCabinetScreen extends StatefulWidget {
  const AppraiserCabinetScreen({super.key});

  @override
  State<AppraiserCabinetScreen> createState() => _AppraiserCabinetScreenState();
}

class _AppraiserCabinetScreenState extends State<AppraiserCabinetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static final List<_AppraiserJob> _newJobs = [
    const _AppraiserJob(
      address: 'г. Алматы, пр. Достык 45',
      area: '110 м²',
      date: '18.01.2026',
      status: BadgeStatus.pending,
      statusLabel: 'Новая',
    ),
    const _AppraiserJob(
      address: 'г. Астана, ул. Кенесары 38',
      area: '72 м²',
      date: '18.01.2026',
      status: BadgeStatus.pending,
      statusLabel: 'Новая',
    ),
  ];

  static final List<_AppraiserJob> _inProgressJobs = [
    const _AppraiserJob(
      address: 'г. Алматы, ул. Абая 52',
      area: '85 м²',
      date: '13.01.2026',
      status: BadgeStatus.inProgress,
      statusLabel: 'В работе',
    ),
  ];

  static final List<_AppraiserJob> _completedJobs = [
    const _AppraiserJob(
      address: 'г. Алматы, ул. Сатпаева 22',
      area: '95 м²',
      date: '10.01.2026',
      status: BadgeStatus.completed,
      statusLabel: 'Завершена',
    ),
    const _AppraiserJob(
      address: 'г. Шымкент, пр. Мира 78',
      area: '130 м²',
      date: '08.01.2026',
      status: BadgeStatus.completed,
      statusLabel: 'Завершена',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Кабинет оценщика'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textHint,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          tabs: [
            Tab(text: 'Новые (${_newJobs.length})'),
            Tab(text: 'В работе (${_inProgressJobs.length})'),
            Tab(text: 'Завершённые (${_completedJobs.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _jobList(_newJobs),
          _jobList(_inProgressJobs),
          _jobList(_completedJobs),
        ],
      ),
    );
  }

  Widget _jobList(List<_AppraiserJob> jobs) {
    if (jobs.isEmpty) {
      return const Center(
        child: Text(
          'Нет заявок',
          style: TextStyle(color: AppColors.textHint, fontSize: 14),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return AppCard(
          onTap: () {
            // TODO: Open job details
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            job.address,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: job.status, label: job.statusLabel),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _metaItem(Icons.straighten_rounded, job.area),
                  const SizedBox(width: 16),
                  _metaItem(Icons.calendar_today_rounded, job.date),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Open report form
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.accent, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Сформировать отчёт',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _metaItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/information_tile.dart';
import '../widgets/option_button.dart';
import '../widgets/status_badge.dart';
import '../widgets/case_progress_bar.dart';
import '../navigation/app_navigator.dart';
import 'payment_screen.dart';
import 'report_screen.dart';

class CaseDetailScreen extends StatelessWidget {
  const CaseDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Заявка №FA1D',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    StatusBadge(
                      status: BadgeStatus.inProgress,
                      label: 'В работе',
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.border, width: 1),
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
                      Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          color: c.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.apartment_rounded,
                            size: 48,
                            color: c.muted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Квартира',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'г. Алматы, ул. Абая 52',
                        style: TextStyle(
                          fontSize: 14,
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CaseProgressBar(progress: 0.55),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Text(
                  'Детали объекта',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    InformationTile(
                      content: '85',
                      name: 'Площадь м²',
                      icon: Icons.square_foot_rounded,
                      valueColor: c.textPrimary,
                    ),
                    InformationTile(
                      content: '3',
                      name: 'Комнаты',
                      icon: Icons.meeting_room_rounded,
                      valueColor: c.info,
                    ),
                    InformationTile(
                      content: '12',
                      name: 'Этаж',
                      icon: Icons.layers_rounded,
                      valueColor: c.warning,
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.border, width: 1),
                  ),
                  child: Column(
                    children: [
                      infoRow(context, 'Тип', 'Квартира'),
                      divider(context),
                      infoRow(context, 'Адрес', 'г. Алматы, ул. Абая 52'),
                      divider(context),
                      infoRow(
                        context,
                        'Стоимость',
                        '42 500 000 ₸',
                        highlight: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Text(
                  'История',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.border, width: 1),
                  ),
                  child: Column(
                    children: [
                      _statusStep(
                        context: context,
                        title: 'Заявка создана',
                        time: '12 января, 10:30',
                        done: true,
                        isFirst: true,
                      ),
                      _statusStep(
                        context: context,
                        title: 'Документы получены',
                        time: '12 января, 11:15',
                        done: true,
                      ),
                      _statusStep(
                        context: context,
                        title: 'В работе у оценщика',
                        time: '13 января, 09:00',
                        done: true,
                      ),
                      _statusStep(
                        context: context,
                        title: 'Ожидает оплаты',
                        done: false,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  children: [
                    OptionButton(
                      text: 'Оплатить',
                      icon: Icons.payments_rounded,
                      onTap: () => AppNavigator.push(
                          context, const PaymentScreen()),
                    ),
                    const SizedBox(height: 12),
                    OptionButton(
                      text: 'Посмотреть отчёт',
                      icon: Icons.description_rounded,
                      backgroundColor: AppColors.of(context).surface,
                      textColor: AppColors.of(context).textPrimary,
                      onTap: () =>
                          AppNavigator.push(context, const ReportScreen()),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusStep({
    required BuildContext context,
    required String title,
    String? time,
    bool done = false,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final c = AppColors.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: done ? c.accent : c.muted,
                shape: BoxShape.circle,
              ),
              child: done
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: c.textHint,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
            ),
            if (!isLast)
              Container(
                width: 1.5,
                height: 32,
                color: done ? c.accent : c.muted,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: done
                        ? c.textPrimary
                        : c.textSecondary,
                  ),
                ),
                if (time != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: TextStyle(
                        fontSize: 12, color: c.textHint),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

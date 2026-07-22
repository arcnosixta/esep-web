import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/information_tile.dart';
import '../widgets/option_button.dart';
import '../widgets/status_badge.dart';
import '../navigation/app_navigator.dart';
import 'report_screen.dart';

class ApplicationCardScreen extends StatelessWidget {
  const ApplicationCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Заявка №2847'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ЗАЯВКА №2847',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Создана 12 января 2026',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const StatusBadge(
                    status: BadgeStatus.inProgress,
                    label: 'В работе',
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              color: AppColors.border,
            ),

            // ── Object info with InformationTile row ──
            Container(
              width: double.infinity,
              color: AppColors.paper,
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ДЕТАЛИ ОБЪЕКТА',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      InformationTile(
                        content: '85',
                        name: 'Площадь м²',
                        icon: Icons.square_foot_rounded,
                        valueColor: AppColors.textPrimary,
                      ),
                      InformationTile(
                        content: '3',
                        name: 'Комнаты',
                        icon: Icons.meeting_room_rounded,
                        valueColor: AppColors.info,
                      ),
                      InformationTile(
                        content: '12',
                        name: 'Этаж',
                        icon: Icons.layers_rounded,
                        valueColor: AppColors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  infoRow('Тип', 'Квартира'),
                  divider(),
                  infoRow('Адрес', 'г. Алматы, ул. Абая 52'),
                  divider(),
                  infoRow(
                    'Стоимость',
                    '42 500 000 ₸',
                    highlight: true,
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              color: AppColors.border,
            ),

            Container(
              width: double.infinity,
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: const Text(
                'ИСТОРИЯ СТАТУСОВ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 24),
              child: Column(
                children: [
                  _statusStep(
                    title: 'Заявка создана',
                    time: '12 января, 10:30',
                    done: true,
                    isFirst: true,
                  ),
                  _statusStep(
                    title: 'Документы получены',
                    time: '12 января, 11:15',
                    done: true,
                  ),
                  _statusStep(
                    title: 'В работе у оценщика',
                    time: '13 января, 09:00',
                    done: true,
                  ),
                  _statusStep(
                    title: 'Ожидает оплаты',
                    done: false,
                    isLast: true,
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              color: AppColors.border,
            ),

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 16, 0),
              child: OptionButton(
                text: 'Посмотреть отчёт',
                icon: Icons.description_rounded,
                onTap: () =>
                    AppNavigator.push(context, const ReportScreen()),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _statusStep({
    required String title,
    String? time,
    bool done = false,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: done ? AppColors.accent : AppColors.muted,
                shape: BoxShape.circle,
              ),
              child: done
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.textHint,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
            ),
            if (!isLast)
              Container(
                width: 1.5,
                height: 32,
                color: done
                    ? AppColors.accent
                    : AppColors.muted,
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
                    color:
                        done ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                if (time != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textHint),
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

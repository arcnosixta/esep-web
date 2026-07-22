import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/information_tile.dart';
import '../widgets/option_button.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Отчёт об оценке'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.accent,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ИТОГОВАЯ СТОИМОСТЬ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: Color(0x99FFFFFF),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '42 500 000 ₸',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: AppColors.paper,
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ДАННЫЕ ОБЪЕКТА',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: AppColors.textSecondary,
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
                  const SizedBox(height: 24),
                  infoRow('Адрес', 'г. Алматы, ул. Абая 52'),
                  divider(),
                  infoRow('Дата оценки', '15 января 2026'),
                  divider(),
                  infoRow('Тип', 'Квартира'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
              child: const Text(
                'РЕКОМЕНДАЦИИ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _recItem(
                    Icons.trending_up_rounded,
                    'Рынок стабилен',
                    'Рост +3.2% за 6 месяцев',
                  ),
                  divider(),
                  _recItem(
                    Icons.home_rounded,
                    'Выгодное расположение',
                    'Престижный район, развитая инфраструктура',
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OptionButton(
                      text: 'Скачать PDF',
                      icon: Icons.download_rounded,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OptionButton(
                      text: 'Поделиться',
                      icon: Icons.share_rounded,
                      backgroundColor: Colors.transparent,
                      textColor: AppColors.accent,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _recItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

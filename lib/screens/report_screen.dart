import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_button.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Отчёт об оценке'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Price
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentGlow,
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Итоговая стоимость',
                    style: TextStyle(
                        fontSize: 14, color: Color(0xCCFFFFFF)),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '42 500 000 ₸',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Заявка №2847',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xAAFFFFFF)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Info
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Данные объекта',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _infoRow('Адрес', 'г. Алматы, ул. Абая 52'),
                  _divider(),
                  _infoRow('Площадь', '85 м²'),
                  _divider(),
                  _infoRow('Дата оценки', '15 января 2026'),
                  _divider(),
                  _infoRow('Тип', 'Квартира'),
                  _divider(),
                  _infoRow('Комнаты', '3'),
                  _divider(),
                  _infoRow('Этаж', '12 из 16'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Recommendations
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Рекомендации',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _recItem(
                    Icons.trending_up_rounded,
                    'Рынок стабилен',
                    'Рост +3.2% за 6 месяцев',
                  ),
                  const SizedBox(height: 14),
                  _recItem(
                    Icons.home_rounded,
                    'Выгодное расположение',
                    'Престижный район, развитая инфраструктура',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Скачать PDF',
                    icon: Icons.download_rounded,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Поделиться',
                    outlined: true,
                    icon: Icons.share_rounded,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(height: 0.5, color: AppColors.divider);

  Widget _recItem(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

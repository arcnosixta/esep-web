import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_button.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedMethod = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оплата'),
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
            // Amount card
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
                    'Сумма к оплате',
                    style: TextStyle(
                        fontSize: 14, color: Color(0xCCFFFFFF)),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '15 000 ₸',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Оценка · Заявка №2847',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xAAFFFFFF)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Payment methods
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Способ оплаты',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _paymentMethod(
              index: 0,
              icon: Icons.account_balance_wallet_rounded,
              label: 'Kaspi Pay',
              color: const Color(0xFFE8394A),
              subtitle: 'Оплата через приложение Kaspi',
            ),
            const SizedBox(height: 10),
            _paymentMethod(
              index: 1,
              icon: Icons.credit_card_rounded,
              label: 'Банковская карта',
              color: AppColors.accent,
              subtitle: 'Visa, Mastercard, Mir',
            ),
            const SizedBox(height: 28),
            if (_selectedMethod == 1)
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Номер карты',
                        prefixIcon: Icon(Icons.credit_card_rounded,
                            size: 20, color: AppColors.textHint),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 15),
                            decoration: const InputDecoration(hintText: 'MM/YY'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 15),
                            decoration: const InputDecoration(hintText: 'CVV'),
                            obscureText: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Оплатить 15 000 ₸',
              icon: Icons.lock_rounded,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentMethod({
    required int index,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
  }) {
    final selected = _selectedMethod == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.06) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? color : AppColors.textHint,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/option_button.dart';
import '../utils/formatters.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Оплата'),
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
                    'СУММА К ОПЛАТЕ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: Color(0x99FFFFFF),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '15 000 ₸',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1.5,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Оценка · Заявка №2847',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0x80FFFFFF),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
              child: const Text(
                'СПОСОБ ОПЛАТЫ',
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
                  _paymentRow(
                    index: 0,
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Kaspi Pay',
                    subtitle: 'Оплата через приложение Kaspi',
                    color: const Color(0xFFE8394A),
                  ),
                  divider(),
                  _paymentRow(
                    index: 1,
                    icon: Icons.credit_card_rounded,
                    label: 'Банковская карта',
                    subtitle: 'Visa, Mastercard, Mir',
                    color: AppColors.accent,
                  ),
                ],
              ),
            ),
            if (_selectedMethod == 1)
              Container(
                width: double.infinity,
                color: AppColors.paper,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Column(
                  children: [
                    _field('Номер карты', Icons.credit_card_rounded),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _field('MM/YY', null)),
                        const SizedBox(width: 12),
                        Expanded(child: _field('CVV', null)),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            Container(
              width: double.infinity,
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: OptionButton(
                text: 'Оплатить 15 000 ₸',
                icon: Icons.lock_rounded,
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentRow({
    required int index,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
  }) {
    final selected = _selectedMethod == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selectedMethod = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
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
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _field(String hint, IconData? prefix) {
    return TextField(
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface,
        prefixIcon: prefix != null
            ? Icon(prefix, size: 20, color: AppColors.textHint)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

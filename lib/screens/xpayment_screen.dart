import 'package:flutter/material.dart';

/// Заглушка экрана XPayment.
///
/// Вторая часть разработчика: здесь нужно встроить реальный виджет оплаты
/// через XPayment и связать его с `XPaymentService`.
class XPaymentScreen extends StatelessWidget {
  const XPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: c.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.payment_rounded, size: 48, color: c.primary),
              const SizedBox(height: 16),
              Text(
                'XPayment',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'Заглушка оплаты. Сюда встроим XPayment.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: c.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.bolt_rounded),
                label: const Text('Оплатить через XPayment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

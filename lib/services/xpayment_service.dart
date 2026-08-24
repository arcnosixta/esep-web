import 'dart:convert';

import 'package:http/http.dart' as http';
import '../main.dart' show supabase;

/// Заглушка интеграции XPayment.
///
/// TODO: заменить на реальный SDK/серверные вызовы XPayment.
/// Контракт подогнан под существующий `PaymentService`, чтобы второй
/// человек мог быстро вкрутить готовую точку входа.
class XPaymentService {
  XPaymentService._();

  static const int appraisalPrice = 15000;

  static Future<Map<String, dynamic>> createSession({
    required String applicationId,
    required int amount,
  }) async {
    // TODO: создать сессию оплаты в XPayment и вернуть `checkout_url`.
    throw UnimplementedError('XPayment: createSession not implemented');
  }

  static Future<Map<String, dynamic>> confirmPayment({
    required String paymentId,
  }) async {
    // TODO: подтвердить платёж в XPayment / через вебхук.
    throw UnimplementedError('XPayment: confirmPayment not implemented');
  }

  static Future<List<Map<String, dynamic>>> getPaymentsForApplication(
    String applicationId,
  ) async {
    // TODO: вернуть историю платежей по заявке из XPayment/ Supabase.
    return <Map<String, dynamic>>[];
  }
}

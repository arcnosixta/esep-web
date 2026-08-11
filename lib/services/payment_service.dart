import 'dart:convert';

import 'package:http/http.dart' as http;

import '../main.dart' show supabase;
import 'supabase_service.dart';

/// Сервис платежей ESEP.
///
/// Сейчас работает режим «ручного подтверждения» (провайдер = manual):
/// клиент платит переводом на Kaspi / картой, запись создаётся со статусом
/// `pending`, менеджер подтверждает в админке → статус `paid` + заявка
/// становится `paid`. Когда будет договор с платёжным провайдером (PayBox /
/// Kaspi API), добавим режим `provider` + вебхук — метод confirmPayment уже
/// готов для этого.
class PaymentService {
  PaymentService._();

  /// Фиксированный тариф за оценку, тенге.
  /// TODO: вынести в таблицу tariffs, когда появятся разные тарифы.
  static const int appraisalPrice = 15000;

  /// Номер Kaspi-счёта/телефона для переводов (международный формат, без +).
  /// TODO: заменить на реальный номер ИП/компании.
  static const String kaspiBusinessPhone = '77029315415';

  /// Базовый URL Cloudflare Pages Functions (/api/*).
  /// TODO: вынести в конфиг/домен esep.kz, когда подключим.
  static const String apiBaseUrl = 'https://esep.pages.dev';

  static const String _table = 'payments';

  /// Короткий номер заявки для UI: №FA1D (первые 4 символа UUID).
  static String applicationNumber(String applicationId) =>
      '№${applicationId.replaceAll('-', '').substring(0, 4).toUpperCase()}';

  /// Создать платёж в статусе pending.
  static Future<Map<String, dynamic>> createPayment({
    required String applicationId,
    required int amount,
    required String method, // 'kaspi' | 'card' | 'manual'
  }) async {
    final data = await supabase.from(_table).insert({
      'application_id': applicationId,
      'user_id': supabase.auth.currentUser?.id,
      'amount': amount,
      'method': method,
      'status': 'pending',
      'provider': 'manual',
    }).select().single();
    return data;
  }

  /// Подтвердить платёж (менеджер в админке или вебхук провайдера).
  /// Заодно переводит заявку в статус paid.
  static Future<void> confirmPayment(
    String paymentId, {
    String? confirmedBy,
  }) async {
    final payment = await supabase
        .from(_table)
        .update({
          'status': 'paid',
          'confirmed_at': DateTime.now().toIso8601String(),
          'confirmed_by': confirmedBy ?? supabase.auth.currentUser?.id,
        })
        .eq('id', paymentId)
        .select()
        .single();

    final applicationId = payment['application_id'] as String?;
    if (applicationId != null) {
      await supabase
          .from('applications')
          .update({'status': 'paid'})
          .eq('id', applicationId);

      // Отчёт становится оплаченным → клиент может скачать официальный PDF.
      try {
        final report = await SupabaseService.getReportForApplication(applicationId);
        if (report != null) {
          await SupabaseService.markReportPaid(report['id'].toString());
        }
      } catch (_) {}
    }
  }

  /// Отметить заявку как ожидающую оплаты (вызывается из экрана оплаты).
  static Future<void> markApplicationPendingPayment(String applicationId) async {
    await supabase
        .from('applications')
        .update({'status': 'pending_payment'})
        .eq('id', applicationId);
  }

  /// Платежи по заявке (свежие сверху).
  static Future<List<Map<String, dynamic>>> getPaymentsForApplication(
    String applicationId,
  ) async {
    final data = await supabase
        .from(_table)
        .select('*')
        .eq('application_id', applicationId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Все платежи (для админки).
  static Future<List<Map<String, dynamic>>> getAllPayments() async {
    final data = await supabase
        .from(_table)
        .select('*, applications(id, status)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Метка способа оплаты для UI.
  static String methodLabel(String method) => switch (method) {
        'kaspi' => 'Kaspi Pay',
        'kaspi_online' => 'Kaspi Pay (онлайн)',
        'card' => 'Банковская карта',
        'bank' => 'Банковский перевод',
        _ => 'Вручную',
      };

  /// Создать сессию Kaspi Pay через edge-функцию /api/kaspi/create.
  /// Возвращает checkout_url (мок-страница, пока Kaspi не подключён).
  static Future<String> createKaspiSession({
    required String applicationId,
    required int amount,
  }) async {
    final token = SupabaseService.accessToken;
    final resp = await http.post(
      Uri.parse('$apiBaseUrl/api/kaspi/create'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'application_id': applicationId, 'amount': amount}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Kaspi Pay: ${resp.body}');
    }
    final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final url = data['checkout_url'] as String?;
    if (url == null) throw Exception('Kaspi Pay: пустой checkout_url');
    return url;
  }

  /// Метка статуса платежа для UI.
  static String statusLabel(String status) => switch (status) {
        'pending' => 'Ожидает подтверждения',
        'paid' => 'Оплачен',
        'failed' => 'Ошибка',
        'cancelled' => 'Отменён',
        _ => status,
      };
}

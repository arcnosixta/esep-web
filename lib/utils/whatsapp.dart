import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Помощник для WhatsApp-ссылок (wa.me).
/// Работает на вебе и на мобилках без API-ключей.
class WhatsApp {
  WhatsApp._();

  /// Номер менеджера/компании в международном формате БЕЗ '+' (для wa.me).
  /// TODO: заменить на реальный номер.
  static const String managerPhone = '77029315415';

  /// Собрать ссылку wa.me с предзаполненным текстом.
  static Uri link({
    String phone = managerPhone,
    String text = '',
  }) {
    final base = Uri.parse('https://wa.me/$phone');
    if (text.isEmpty) return base;
    return base.replace(queryParameters: {'text': text});
  }

  /// Открыть WhatsApp с готовым сообщением.
  static Future<bool> open({
    String phone = managerPhone,
    String text = '',
  }) async {
    try {
      final uri = link(phone: phone, text: text);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) debugPrint('[WA] Не удалось открыть $uri');
      return ok;
    } catch (e) {
      debugPrint('[WA] Ошибка: $e');
      return false;
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../main.dart';
import '../models/chat_message.dart';
import '../services/supabase_service.dart';

class OpenRouterService {
  OpenRouterService._();

  static const _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const _defaultModel = 'google/gemini-2.0-flash-001';

  static const _systemPrompt = '''
Ты — AI-ассистент оценщика недвижимости в Казахстане (система ESEP).
Твоя задача — помогать оценщикам анализировать объекты недвижимости.

Возможности:
1. Анализировать предварительную стоимость квартиры/дома по адресу и параметрам
2. Искать похожие объекты в базе данных ESEP
3. Сравнивать объекты с рыночными аналогами
4. Объяснять факторы влияния на стоимость
5. Давать рекомендации по оценке
6. Анализировать фотографии объектов недвижимости (состояние, ремонт, тип отделки, вид из окна)

Правила:
- Отвечай на русском языке
- Будь точен в цифрах, указывай диапазоны если точная оценка невозможна
- Ссылайся на конкретные факторы (район, этаж, состояние, инфраструктура)
- Если данных недостаточно — задай уточняющие вопросы
- Форматируй ответ структурированно: используй списки, выделяй цифры
- Если пользователь прислал фото — опиши что видишь и оцени влияние на стоимость
''';

  static Future<List<Map<String, dynamic>>> _fetchMarketContext({
    String? propertyType,
    int limit = 5,
  }) async {
    try {
      return await SupabaseService.getMarketData(
        type: propertyType,
        limit: limit,
      );
    } catch (_) {
      return [];
    }
  }

  static String _buildContextPrompt(List<Map<String, dynamic>> marketData) {
    if (marketData.isEmpty) return '';

    final buffer = StringBuffer('\n--- Данные рынка из БД ESEP ---\n');
    for (final item in marketData) {
      final address = item['address'] ?? '';
      final price = item['price'] ?? '';
      final area = item['area'] ?? '';
      final type = item['type'] ?? '';
      buffer.writeln('$type | $address | $area м² | $price₸');
    }
    buffer.writeln('--- Конец данных ---\n');
    return buffer.toString();
  }

  static Stream<String> streamCompletion({
    required List<ChatMessage> messages,
    String model = _defaultModel,
  }) async* {
    final marketData = await _fetchMarketContext();
    final contextPrompt = _buildContextPrompt(marketData);

    final apiMessages = <Map<String, dynamic>>[
      {'role': 'system', 'content': _systemPrompt + contextPrompt},
      ...messages.map((m) => m.toApiFormat()),
    ];

    final body = jsonEncode({
      'model': model,
      'messages': apiMessages,
      'stream': true,
      'max_tokens': 2048,
      'temperature': 0.7,
    });

    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse(_baseUrl));
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', 'Bearer $openRouterApiKey');
      request.headers.set('HTTP-Referer', 'https://esep.kz');
      request.headers.set('X-OpenRouter-Title', 'ESEP Real Estate');
      request.write(body);

      final response = await request.close();
      if (response.statusCode != 200) {
        final error = await response.transform(utf8.decoder).join();
        yield '\n[Ошибка ${response.statusCode}: $error]';
        return;
      }

      String buffer = '';
      await for (final chunk in response.transform(utf8.decoder)) {
        buffer += chunk;
        final lines = buffer.split('\n');
        buffer = lines.removeLast();

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || !trimmed.startsWith('data: ')) continue;

          final data = trimmed.substring(6);
          if (data == '[DONE]') return;

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final choices = json['choices'] as List?;
            if (choices == null || choices.isEmpty) continue;

            final delta = choices[0]['delta'] as Map<String, dynamic>?;
            if (delta == null) continue;

            final content = delta['content'] as String?;
            if (content != null && content.isNotEmpty) {
              yield content;
            }
          } catch (_) {
            // skip malformed chunks
          }
        }
      }
    } finally {
      client.close();
    }
  }
}

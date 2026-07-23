import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../main.dart';
import '../models/chat_message.dart';
import '../services/supabase_service.dart';

class OpenRouterService {
  OpenRouterService._();

  static const _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  static const _textModels = [
    'google/gemma-4-26b-a4b-it:free',
    'google/gemma-4-31b-it:free',
    'google/gemini-3.5-flash-lite',
  ];

  static const _visionModels = [
    'google/gemma-4-26b-a4b-it:free',
    'google/gemini-3.5-flash-lite',
    'google/gemini-2.5-flash',
  ];

  static const _systemPrompt = '''
Ты — Айдар Нурланович, профессиональный оценщик недвижимости в системе ESEP (Единая Система Оценки Недвижимости Казахстана). Тебе 34 года, высшее образование по специальности «Оценка недвижимости и управление имуществом», сертификат оценщика Агентства Республики Казахстан по регулированию и развитию финансового рынка. Стаж работы — 8 лет.

ТВОЯ РОЛЬ:
Ты — штатный AI-сотрудник компании ESEP, который работает как реальный оценщик. Ты не «ассистент» и не «бот» — ты профессионал, который консультирует коллег-оценщиков и помогает им в работе.

ХАРАКТЕР И МАНЕРА ОБЩЕНИЯ:
- Общаешься на «вы» (как с коллегой по работе)
- Говоришь уверенно, но дружелюбно — ты эксперт, который готов помочь
- Используешь профессиональную терминологию, но объясняешь сложные вещи простым языком
- Когда не уверен — честно говоришь «нужно проверить» или «данных недостаточно», но всегда предлагаешь варианты
- Помнишь контекст разговора и предыдущие вопросы пользователя

ТВОИ ОБЯЗАННОСТИ:

1. ПРЕДВАРИТЕЛЬНАЯ ОЦЕНКА СТОИМОСТИ:
   - По адресу, параметрам (площадь, этаж, комнаты) даёшь рыночный диапазон
   - Указываешь цену за м² и общую сумму в тенге (₸)
   - Ссылаешься на конкретные аналоги из БД если они есть
   - Учитываешь: район, этажность, состояние, год постройки, инфраструктуру

2. АНАЛИЗ ФОТОГРАФИЙ ОБЪЕКТОВ:
   - Определяешь: тип отделки, состояние, детали интерьера
   - Даёшь влияние на стоимость

3. СРАВНИТЕЛЬНЫЙ АНАЛИЗ:
   - Сравниваешь объект с рыночными аналогами
   - Показываешь разброс цен по районам

4. ФАКТОРЫ ВЛИЯНИЯ НА СТОИМОСТЬ:
   - Положительные и отрицательные факторы

5. ПОДСКАЗКИ ДЛЯ ОЦЕНЩИКА:
   - Документы, методы, на что обратить внимание

ФОРМАТ ОЦЕНКИ:
┌─────────────────────────────────┐
│  ПРЕДВАРИТЕЛЬНАЯ ОЦЕНКА         │
├─────────────────────────────────┤
│  Объект: [тип], [адрес]         │
│  Площадь: XX м²                 │
│  Цена за м²: XX XXX — XX XXX ₸ │
│  ОБЩАЯ СТОИМОСТЬ:               │
│  XX XXX XXX — XX XXX XXX ₸      │
└─────────────────────────────────┘

ОГРАНИЧЕНИЯ:
- НЕ придумывай данные которых нет в контексте
- НЕ выдавай юридические консультации
- Всегда рекомендуй обратиться к лицензированному оценщику

Язык: русский (основной), казахский (если пользователь пишет на казахском).
''';

  static Future<List<Map<String, dynamic>>> _fetchMarketContext({
    String? propertyType,
    int limit = 10,
  }) async {
    try {
      return await SupabaseService.getMarketData(
        type: propertyType,
        limit: limit,
      );
    } catch (e) {
      debugPrint('[AI] Market data fetch error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> _fetchUserProfile() async {
    try {
      return await SupabaseService.getProfile();
    } catch (e) {
      debugPrint('[AI] Profile fetch error: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchUserProperties() async {
    try {
      return await SupabaseService.getProperties();
    } catch (e) {
      debugPrint('[AI] Properties fetch error: $e');
      return [];
    }
  }

  static String _buildMarketContext(List<Map<String, dynamic>> marketData) {
    if (marketData.isEmpty) return '';

    final buffer = StringBuffer('\n## ДАННЫЕ РЫНКА ИЗ БД ESEP\n');
    buffer.writeln('Актуальные предложения (обновлено: '
        '${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}):\n');

    for (int i = 0; i < marketData.length; i++) {
      final item = marketData[i];
      final address = item['address'] ?? 'не указан';
      final price = item['price'];
      final area = item['area'] ?? '—';
      final type = item['type'] ?? '—';
      final rooms = item['rooms'] ?? '—';
      final floor = item['floor'] ?? '—';
      final totalFloors = item['total_floors'] ?? '—';

      buffer.writeln('${i + 1}. $type | $address');
      buffer.writeln('   $area м² | $rooms комн. | $floor/$totalFloors эт.');
      if (price != null) {
        buffer.writeln('   Цена: $price ₸');
        if (area != null && area != '—' && price is num) {
          final pricePerM2 = price / (area is num ? area : 1);
          buffer.writeln('   За м²: ~${pricePerM2.round()} ₸');
        }
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }

  static String _buildUserContext(
    Map<String, dynamic>? profile,
    List<Map<String, dynamic>> properties,
  ) {
    final buffer = StringBuffer('\n## ИНФОРМАЦИЯ О ПОЛЬЗОВАТЕЛЕ\n');

    if (profile != null) {
      final name = profile['full_name'] ?? 'не указано';
      buffer.writeln('Имя: $name');
    }

    if (properties.isNotEmpty) {
      buffer.writeln('\nОбъекты в системе (${properties.length}):');
      for (int i = 0; i < properties.length; i++) {
        final prop = properties[i];
        final type = prop['type'] ?? '—';
        final address = prop['address'] ?? '—';
        final area = prop['area'] ?? '—';
        buffer.writeln('${i + 1}. $type | $address | $area м²');
      }
    }

    return buffer.toString();
  }

  static bool _hasImages(List<ChatMessage> messages) {
    return messages.any((m) => m.hasImages);
  }

  static Stream<String> streamCompletion({
    required List<ChatMessage> messages,
  }) async* {
    final hasImages = _hasImages(messages);
    final modelsToTry = hasImages ? _visionModels : _textModels;

    debugPrint('[AI] Has images: $hasImages, trying models: $modelsToTry');

    final results = await Future.wait([
      _fetchMarketContext(),
      _fetchUserProfile(),
      _fetchUserProperties(),
    ]);

    final marketData = results[0] as List<Map<String, dynamic>>;
    final profile = results[1] as Map<String, dynamic>?;
    final properties = results[2] as List<Map<String, dynamic>>;

    final marketContext = _buildMarketContext(marketData);
    final userContext = _buildUserContext(profile, properties);

    final fullSystemPrompt = _systemPrompt + marketContext + userContext;

    final apiMessages = <Map<String, dynamic>>[
      {'role': 'system', 'content': fullSystemPrompt},
      ...messages.map((m) => m.toApiFormat()),
    ];

    String? lastError;

    for (final model in modelsToTry) {
      debugPrint('[AI] Trying model: $model');
      try {
        yield* _streamWithModel(
          model: model,
          apiMessages: apiMessages,
        );
        debugPrint('[AI] Model $model succeeded');
        return;
      } catch (e) {
        lastError = e.toString();
        debugPrint('[AI] Model $model failed: $lastError — trying next');
        continue;
      }
    }

    debugPrint('[AI] All models failed. Last error: $lastError');
    yield '\n[Ошибка] Сервис временно недостаточно. '
        'Проверьте подключение к интернету и попробуйте позже.\n'
        'Детали: ${lastError ?? "неизвестная ошибка"}';
  }

  static Stream<String> _streamWithModel({
    required String model,
    required List<Map<String, dynamic>> apiMessages,
  }) async* {
    final body = jsonEncode({
      'model': model,
      'messages': apiMessages,
      'stream': true,
      'max_tokens': 4096,
      'temperature': 0.7,
      'top_p': 0.9,
    });

    debugPrint('[AI] Request body length: ${body.length} chars');
    debugPrint('[AI] Request body preview: ${body.substring(0, body.length > 300 ? 300 : body.length)}');

    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse(_baseUrl));
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', 'Bearer $openRouterApiKey');
      request.headers.set('HTTP-Referer', 'https://esep.kz');
      request.headers.set('X-OpenRouter-Title', 'ESEP Real Estate Appraiser');
      final bodyBytes = utf8.encode(body);
      request.headers.contentLength = bodyBytes.length;
      request.add(bodyBytes);

      final response = await request.close();
      if (response.statusCode != 200) {
        final error = await response.transform(utf8.decoder).join();
        throw Exception('HTTP ${response.statusCode}: $error');
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
          } catch (_) {}
        }
      }
    } finally {
      client.close();
    }
  }
}

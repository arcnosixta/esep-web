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
Ты — Айдар Нурланович, AI-оценщик недвижимости в системе ESEP (Единая Система Оценки Недвижимости Казахстана). Тебе 34 года, сертификат оценщика, стаж 8 лет.

## ГЛАВНОЕ ПРАВИЛО — ДВА ФОТО И ВСЁ

Твоя задача — попросить у пользователя ровно ДВА фото и ничего больше:
1. ФОТО СТРАХОВКИ (полис/договор страхования) — там уже написаны: адрес объекта, площадь в м², кадастровый номер, тип имущества, данные собственника
2. ФОТО САМОГО ИМУЩЕСТВА — внешний вид, состояние, отделка, район

Ты НЕ задаёшь вопросов про адрес, площадь, этаж и т.д. — всё это уже есть в страховке. Просто попроси эти два фото.

## АЛГОРИТМ ПОВЕДЕНИЯ

### Сценарий А — Пользователь только начал диалог:
1. Поприветствуйся кратко
2. Скажи: «Пришлите мне два фото:
   📄 Фото страхового полиса (там есть адрес, площадь и все данные)
   🏠 Фото самого объекта (внутри и снаружи)»
3. БОЛЬШЕ НИЧЕГО НЕ СПРАШИВАЙ — жди фото

### Сценарий Б — Пользователь прислал фото:
1. Если пришли оба фото (страховка + имущество):
   - Благодари кратко
   - Извлеки из страховки: адрес, площадь, тип, кадастровый номер
   - Проанализируй фото имущества: состояние, отделка, вид
   - Ищи похожие варианты: Крыша.кз, OLX.kz, своя БД
   - Дай оценку:
   ```
   📋 ПРЕДВАРИТЕЛЬНАЯ ОЦЕНКА
   Объект: [тип из страховки], [адрес из страховки]
   Площадь: XX м² (из страховки)
   Состояние: [по фото имущества]
   Цена за м²: XX XXX — XX XXX ₸
   💰 ОБЩАЯ СТОИМОСТЬ: XX XXX — XX XXX ₸
   ```
   - Предложи официальный отчёт: «Для банка/сделки нужен официальный отчёт — оформлю»

2. Если пришло только одно фото:
   - Если страховка: «Отлично, данные считал. Теперь пришлите фото самого объекта — так оценка будет точнее»
   - Если только имущество: «Данных из страховки нет. Пришлите фото полиса — там адрес и площадь, оценка станет точнее»

3. Если нет фото, только текст:
   - НЕ задавай кучу вопросов
   - Скажи: «Для точной оценки пришлите фото страхового полиса и самого объекта. Там уже есть всё — адрес, площадь, данные»

### Сценарий В — Общие вопросы:
- Отвечай кратко
- Всегда возвращай к двум фото: «Пришлите страховку и фото объекта — дам оценку»

## ЧТО ИЩЕШЬ В ИНТЕРНЕТЕ:
- Крыша.кz — актуальные цены на похожие объекты
- OLX.kz — предложения продажи
- Своя БД — рыночные данные
- Сравнивай по: район, площадь, этаж, состояние

## ПРОДАЖА ОЦЕНКИ:
В конце каждого ответа с оценкой мягко предложи:
- «Оформлю официальный отчёт об оценке для банка или сделки»
- Не навязывай, но упоминай

## ФОРМАТ ОТВЕТОВ:
- Короткие, структурированные
- Эмодзи для заголовков
- Максимум 5-7 строк
- В конце — CTA: пришли фото или купи отчёт

## ХАРАКТЕР:
- Профессионал, дружелюбный
- На «вы»
- Уверенный
- Помнишь контекст

ОГРАНИЧЕНИЯ:
- Не придумывай данные которых нет
- Не давай юридические консультации
- Рекомендуй официальный отчёт для сделок

Язык: русский (основной), казахский (если пишут на казахском).
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

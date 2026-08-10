import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/chat_message.dart';
import '../models/report_template.dart';
import '../services/supabase_service.dart';

class OpenRouterService {
  OpenRouterService._();

  // Запросы идут через Cloudflare Pages Function (/api/chat):
  // ключ OpenRouter хранится только на сервере (secret в Pages),
  // в клиентском коде (и в JS-бандле) его больше нет.
  static const _baseUrl = 'https://esep.pages.dev/api/chat';

  static const _textModels = [
    'gemini-flash-lite-latest',
    'google/gemma-4-31b-it:free',
    'google/gemma-4-26b-a4b-it:free',
  ];

  static const _visionModels = [
    'gemini-2.5-flash',
    'google/gemma-4-26b-a4b-it:free',
    'google/gemma-4-31b-it:free',
  ];

  static const _systemPrompt = '''
Ты — Айдар Нурланович, AI-оценщик недвижимости в системе ESEP (Единая Система Оценки Недвижимости Казахстана). Тебе 34 года, сертификат оценщика, стаж 8 лет.

## ДВА СПОСОБА ОЦЕНКИ

У пользователя есть ДВА пути получить оценку:

### ПУТЬ 1 — ФОТО (точный):
Пользователь присылает два фото:
1. ФОТО СТРАХОВКИ — там адрес, площадь, кадастровый номер, тип, данные собственника
2. ФОТО ОБЪЕКТА — состояние, отделка, район
Всё извлекается автоматически, вопросы не нужны.

### ПУТЬ 2 — ТЕКСТ (без документов):
Если у пользователя нет документов, он пишет информацию текстом. Попроси его написать:
- Тип объекта (квартира, дом, участок)
- Адрес
- Площадь (м²)
- Комнаты / этаж / общая этажность
- Состояние (отделка, ремонт)
- Год постройки (если знает)

Формат текстового ввода:
```
Квартира, Абая 150, 3-комнатная, 85 м², 5/9 этаж, косметический ремонт, 2005 год
```

### Сценарий А — Пользователь только начал диалог:
1. Поприветствуйся кратко
2. Предложи варианты (по порядку):
   «Загрузите документы во вкладку "Документы" — страховку, план или фото объекта (я учту их при оценке).
   Или пришлите фото прямо сюда:
   📄 Фото страхового полиса (адрес, площадь, данные)
   🏠 Фото самого объекта (состояние, отделка)
   Либо напишите текстом — тип, адрес, площадь, этаж, состояние»
3. Жди ввод

### Сценарий Б — Пользователь прислал фото:
1. Если пришли оба фото (страховка + имущество):
   - Благодари кратко
   - Извлеки из страховки: адрес, площадь, тип, кадастровый номер
   - Проанализируй фото имущества: состояние, отделка, вид
   - Ищи похожие варианты: Крыша.кз, OLX.kz, своя БД
   - Дай оценку в формате:
   ```
   📋 ПРЕДВАРИТЕЛЬНАЯ ОЦЕНКА
   Объект: [тип], [адрес]
   Площадь: XX м²
   Состояние: [по фото]
   Цена за м²: XX XXX — XX XXX ₸
   💰 ОБЩАЯ СТОИМОСТЬ: XX XXX — XX XXX ₸
   ```
   - Предложи официальный отчёт

2. Если пришло только одно фото:
   - Если страховка: «Отлично, данные считал. Пришлите фото объекта для точной оценки»
   - Если только имущество: «Пришлите фото полиса — там адрес и площадь»

### Сценарий В — Пользователь написал текстом:
1. Если текст содержит достаточно данных (адрес + площадь + тип):
   - Поблагодари
   - Определи район по адресу
   - Ищи похожие варианты: Крыша.кz, OLX.kz, своя БД
   - Дай оценку (но с пометкой «ориентировочная, без документов»)
   - Предложи: «Для точной оценки можно приложить фото страховки и объекта»

2. Если данных мало (только адрес или только «квартира»):
   - Вежливо попроси补充: «Для оценки нужно: тип, адрес, площадь, этаж, состояние.
   Напишите, например: Квартира, Абая 150, 3-комн, 85 м², 5/9, косметический ремонт»
   - НЕ задавай больше 2-3 вопросов сразу

### Сценарий Г — Общие вопросы:
- Отвечай кратко
- Возвращай к оценке: «Пришлите фото или опишите объект текстом — дам оценку»

## ЧТО ИЩЕШЬ В ИНТЕРНЕТЕ:
- Крыша.кз — актуальные цены на похожие объекты
- OLX.kz — предложения продажи
- Своя БД — рыночные данные (раздел ДАННЫЕ РЫНКА)
- Сравнивай по: район, площадь, этаж, состояние

ВАЖНО ПРО РЫНОЧНЫЕ ДАННЫЕ (используй ВСЕ источники по порядку):
1. СНАЧАЛА — данные из своей БД: раздел «ДАННЫЕ РЫНКА ИЗ БД ESEP» (если он есть в контексте). Это самые надёжные аналоги.
2. ЗАТЕМ — живой поиск в интернете (инструмент поиска Google доступен, когда в диалоге есть фото): ищи актуальные объявления на krisha.kz, olx.kz, kn.kz и других сайтах.
3. Используй ВСЕ доступные источники ВМЕСТЕ: и БД, и интернет. Не ограничивайся одним.

ПРАВИЛА ДОКАЗАТЕЛЬСТВ:
- Всегда указывай ссылки: для аналогов из БД — их source_url; для интернета — ссылки, которые вернул поиск.
- В конце ответа с оценкой приведи блок «📎 Источники:» со списком использованных ссылок (только если реально есть ссылки из поиска или из БД).
- Если поиск недоступен (нет фото в диалоге): используй данные БД и свои знания рынка, НО честно скажи «точные объявления не проверял, это предварительная оценка», и НЕ выдумывай ссылки.
- Никогда НЕ выдумывай цены, адреса и ссылки. Если данных нет — так и скажи: «похожих предложений пока не найдено, оценка ориентировочная».
- ПУТЬ 2 (без документов): после оценки напомни одной строкой: «Официальный подписанный отчёт — после оплаты заявки в приложении. Документы (страховку, фото) можно приложить позже — оценщик запросит их при подготовке.»

## СТРУКТУРИРОВАННЫЙ ВЫВОД ОЦЕНКИ (ОБЯЗАТЕЛЬНО):
В КОНЦЕ ответа, если ты дал оценку (у тебя есть тип + адрес + площадь), добавь JSON-блок
строго такого вида (между маркерами [ESTIMATE] и [/ESTIMATE]):

[ESTIMATE]
{"property_type":"квартира","address":"г. Алматы, Абая 150","area":85,"rooms":3,"floor":5,"total_floors":9,"condition":"косметический ремонт","year_built":2005,"price_low":32600000,"price_high":44200000,"price_mid":38400000,"has_documents":true}
[/ESTIMATE]

Правила:
- property_type: квартира | дом | земля | коммерческая (по-русски, маленькими буквами)
- price_low/price_high/price_mid — в тенге, целыми числами, реалистично по рыночным данным
- has_documents: true — если пользователь прислал фото страховки/документов; false — если только текст
- Если данных недостаточно для оценки — НЕ выводи блок [ESTIMATE] вообще
- Блок идёт в самом конце ответа, отдельной строкой

## ПРОДАЖА ОЦЕНКИ:
В конце каждого ответа с оценкой мягко предложи:
- «Оформлю официальный отчёт об оценке для банка или сделки»
- Не навязывай, но упоминай

## ДОКУМЕНТЫ ПОЛЬЗОВАТЕЛЯ (вкладка «Документы» в приложении):
В контексте диалога может быть раздел «ДОКУМЕНТЫ ПОЛЬЗОВАТЕЛЯ» — список файлов, которые пользователь загрузил во вкладку «Документы» (фото имущества, страховка, PDF, планы, договоры).

Документы НЕ обязательны для предварительной оценки: если пользователь дал текстовое описание (тип + адрес + площадь) — выдавай [ESTIMATE] сразу, не требуя фото и не откладывая оценку.
ПРАВИЛО: если документы (страховка, фото объекта, план) уже загружены — не проси их повторно, учитывай их в анализе.
В [ESTIMATE] ставь has_documents: true, если есть документы на объект ИЛИ пользователь прислал фото в чат; false — если только текст.

## ОФИЦИАЛЬНЫЙ ОТЧЁТ И ОПЛАТА:
- Любая оценка в чате — ПРЕДВАРИТЕЛЬНАЯ и НЕ является официальным документом, не имеет юридической силы.
- Официальный подписанный отчёт (для банка, сделки, нотариуса) пользователь получает после ОПЛАТЫ заявки в приложении.
- После КАЖДОЙ оценки ОБЯЗАТЕЛЬНО добавляй дисклеймер одной строкой:
  «⚠️ Это предварительная оценка, не официальный документ. Для официального подписанного отчёта оплатите заявку в приложении.»

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

  static Future<List<Map<String, dynamic>>> _fetchUserDocuments() async {
    try {
      return await SupabaseService.getDocuments();
    } catch (e) {
      debugPrint('[AI] Documents fetch error: $e');
      return [];
    }
  }

  static String _formatDocSize(double bytes) {
    if (bytes < 1024) return '${bytes.round()} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Список документов, загруженных пользователем во вкладку «Документы».
  static String _buildDocumentsContext(List<Map<String, dynamic>> docs) {
    if (docs.isEmpty) return '';

    final buffer = StringBuffer('\n## ДОКУМЕНТЫ ПОЛЬЗОВАТЕЛЯ\n');
    buffer.writeln('Пользователь загрузил во вкладку «Документы» '
        '(${docs.length} файл(ов)):');
    for (int i = 0; i < docs.length; i++) {
      final d = docs[i];
      final name = d['name'] ?? 'без имени';
      final type = (d['file_type'] ?? '').toString().toUpperCase();
      final size = d['file_size'];
      final sizeLabel =
          size != null ? ' (${_formatDocSize((size as num).toDouble())})' : '';
      buffer.writeln('${i + 1}. $name [$type]$sizeLabel');
    }
    buffer.writeln(
        'Используй эти документы при анализе. Недостающие проси загрузить '
        'во вкладку «Документы» в приложении.');
    return buffer.toString();
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
      final sourceUrl = item['source_url'];

      buffer.writeln('${i + 1}. $type | $address');
      buffer.writeln('   $area м² | $rooms комн. | $floor/$totalFloors эт.');
      if (price != null) {
        buffer.writeln('   Цена: $price ₸');
        if (area != null && area != '—' && price is num) {
          final pricePerM2 = price / (area is num ? area : 1);
          buffer.writeln('   За м²: ~${pricePerM2.round()} ₸');
        }
      }
      if (sourceUrl != null && sourceUrl.toString().isNotEmpty) {
        buffer.writeln('   Ссылка: $sourceUrl');
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
      _fetchUserDocuments(),
    ]);

    final marketData = results[0] as List<Map<String, dynamic>>;
    final profile = results[1] as Map<String, dynamic>?;
    final properties = results[2] as List<Map<String, dynamic>>;
    final documents = results[3] as List<Map<String, dynamic>>;

    final marketContext = _buildMarketContext(marketData);
    final userContext = _buildUserContext(profile, properties);
    final docsContext = _buildDocumentsContext(documents);

    final fullSystemPrompt =
        _systemPrompt + marketContext + userContext + docsContext;

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

  // ============================================
  // REPORT GENERATION (two-step: JSON → PDF)
  // ============================================

  static const _reportSystemPrompt = '''
Ты — AI-оценщик недвижимости в системе ESEP (Казахстан).
Сгенерируй данные для отчёта об оценке в формате JSON.

Входные данные: тип объекта, адрес, площадь, комнаты, этаж, общая этажность, состояние, год постройки, ФИО клиента, ИИН, телефон, email.

Доступные рыночные данные (если есть):
''';

  static Future<ReportData?> generateReportData({
    required String propertyType,
    required String address,
    required double area,
    required int rooms,
    required int floor,
    required int totalFloors,
    required String condition,
    required int yearBuilt,
    required String clientName,
    required String clientIin,
    String? clientPhone,
    String? clientEmail,
    bool clientIsOrg = false,
    String? appraiserName,
  }) async {
    final results = await Future.wait([
      _fetchMarketContext(propertyType: propertyType, limit: 5),
      _fetchUserProfile(),
    ]);

    final marketData = results[0] as List<Map<String, dynamic>>;
    final marketContext = _buildMarketContext(marketData);

    final userPrompt = '''
Объект для оценки:
- Тип: $propertyType
- Адрес: $address
- Площадь: $area м²
- Комнат: $rooms
- Этаж: $floor/$totalFloors
- Состояние: $condition
- Год постройки: $yearBuilt
- Клиент: $clientName (ИИН: $clientIin${(clientPhone != null && clientPhone.isNotEmpty) ? ', тел: $clientPhone' : ''}${(clientEmail != null && clientEmail.isNotEmpty) ? ', email: $clientEmail' : ''})
- Дата оценки: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}
- Оценщик: ${appraiserName ?? 'Айдар Нурланович'}

$marketContext

Верни ТОЛЬКО валидный JSON без markdown и комментариев:
{
  "client_name": "string",
  "client_iin": "string",
  "property_type": "string",
  "address": "string",
  "area": number,
  "rooms": number,
  "floor": number,
  "total_floors": number,
  "condition": "string",
  "year_built": number,
  "estimated_price": number,
  "price_range_low": number,
  "price_range_high": number,
  "price_per_meter": number,
  "confidence": number от 0.7 до 0.99,
  "comparables": [
    {"address": "string", "area": number, "price": number, "type": "string", "source": "string"}
  ],
  "recommendations": [
    {"icon": "trending_up|home|location|info", "title": "string", "description": "string"}
  ],
  "appraisal_date": "DD.MM.YYYY",
  "appraiser_name": "string",
  "appraiser_certificate": ""
}

Оцени реалистично на основе рыночных данных. Диапазон ±10-15% от основной оценки.
''';

    final apiMessages = [
      {'role': 'system', 'content': _reportSystemPrompt},
      {'role': 'user', 'content': userPrompt},
    ];

    String? lastError;

    for (final model in _textModels) {
      try {
        final body = jsonEncode({
          'model': model,
          'messages': apiMessages,
          'stream': false,
          'max_tokens': 2048,
          'temperature': 0.3,
          'top_p': 0.9,
        });

        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
          },
          body: body,
        );
        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }

        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = json['choices'] as List?;
        if (choices == null || choices.isEmpty) throw Exception('No choices');

        final content = choices[0]['message']?['content'] as String? ?? '';
        if (content.isEmpty) throw Exception('Empty content');

        final cleaned = content
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final reportJson = jsonDecode(cleaned) as Map<String, dynamic>;
        reportJson['client_is_org'] = clientIsOrg;
        debugPrint('[Report] AI model $model succeeded');
        return ReportData.fromJson(reportJson);
      } catch (e) {
        lastError = e.toString();
        debugPrint('[Report] Model $model failed: $lastError');
        continue;
      }
    }

    debugPrint('[Report] All models failed. Last error: $lastError');
    return null;
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

    final request = http.Request('POST', Uri.parse(_baseUrl))
      ..headers.addAll({
        'Content-Type': 'application/json',
      })
      ..body = body;

    final streamed = await request.send();
    if (streamed.statusCode != 200) {
      final error = await streamed.stream.transform(utf8.decoder).join();
      throw Exception('HTTP ${streamed.statusCode}: $error');
    }

    String buffer = '';
    await for (final chunk in streamed.stream.transform(utf8.decoder)) {
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
  }

  // ============================================
  // PARSE [ESTIMATE] JSON FROM ASSISTANT ANSWER
  // ============================================

  /// Извлекает структурированную оценку из ответа ИИ.
  /// Ищет блок [ESTIMATE]...[/ESTIMATE]; если маркеров нет — пробует
  /// распарсить последний JSON-объект в тексте (на случай если модель
  /// забыла маркеры). Возвращает null, если оценки нет.
  static EstimateData? extractEstimate(String text) {
    if (text.isEmpty) return null;

    String? jsonCandidate;

    final markerMatch = RegExp(
      r'\[ESTIMATE\]([\s\S]*?)\[/ESTIMATE\]',
      caseSensitive: false,
    ).firstMatch(text);
    if (markerMatch != null) {
      jsonCandidate = markerMatch.group(1)?.trim();
    } else {
      // Последний {...} блок в тексте
      final matches = RegExp(r'\{[^{}]*\}').allMatches(text).toList();
      if (matches.isNotEmpty) {
        jsonCandidate = matches.last.group(0);
      }
    }

    if (jsonCandidate == null) return null;

    try {
      final map = jsonDecode(jsonCandidate) as Map<String, dynamic>;
      if (map['price_mid'] == null && map['price_low'] == null) return null;
      return EstimateData(
        propertyType: (map['property_type'] as String?) ?? '',
        address: (map['address'] as String?) ?? '',
        area: (map['area'] as num?)?.toDouble(),
        rooms: (map['rooms'] as num?)?.toInt(),
        floor: (map['floor'] as num?)?.toInt(),
        totalFloors: (map['total_floors'] as num?)?.toInt(),
        condition: (map['condition'] as String?) ?? '',
        yearBuilt: (map['year_built'] as num?)?.toInt(),
        priceLow: (map['price_low'] as num?)?.toDouble(),
        priceHigh: (map['price_high'] as num?)?.toDouble(),
        priceMid: (map['price_mid'] as num?)?.toDouble(),
        hasDocuments: map['has_documents'] == true,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Структурированная оценка, извлечённая из ответа ИИ.
class EstimateData {
  final String propertyType;
  final String address;
  final double? area;
  final int? rooms;
  final int? floor;
  final int? totalFloors;
  final String condition;
  final int? yearBuilt;
  final double? priceLow;
  final double? priceHigh;
  final double? priceMid;
  final bool hasDocuments;

  const EstimateData({
    this.propertyType = '',
    this.address = '',
    this.area,
    this.rooms,
    this.floor,
    this.totalFloors,
    this.condition = '',
    this.yearBuilt,
    this.priceLow,
    this.priceHigh,
    this.priceMid,
    this.hasDocuments = false,
  });
}

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
2. Предложи два варианта:
   «Пришлите два фото:
   📄 Фото страхового полиса (адрес, площадь, данные)
   🏠 Фото самого объекта (состояние, отделка)

   Или напишите текстом — укажите тип, адрес, площадь, этаж, состояние»
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

  // ============================================
  // REPORT GENERATION (Недвижимое имущество — официальный формат)
  // Аналог структуры "Kaz Etalon Grade" / SDF-YYYYMMDD-NNNNN
  // ============================================
 
  static const _reportSystemPrompt = '''
Ты — AI-оценщик недвижимого имущества в системе ESEP (Казахстан).
Твоя задача — сгенерировать данные для официального "Отчёта об оценке недвижимого имущества"
в формате JSON, максимально соответствующего требованиям Приказа МФ РК №501 от 03.05.2018
"Об утверждении требований к форме и содержанию отчёта об оценке" и Закона РК
«Об оценочной деятельности» №133-VI от 10.01.2018.
 
Входные данные: тип объекта (квартира/дом/коммерческая недвижимость и т.п.), адрес,
площадь, количество комнат, этаж/этажность, состояние, год постройки, материал стен (если
есть), ФИО/БИН заказчика, ФИО/ИИН собственника, номер и дата договора-основания
(залог/цессия/купля-продажа и т.п.).
 
Доступные рыночные данные (аналоги с площадок krisha.kz и т.п.), если есть:
''';
 
  static Future<RealEstateReportData?> generateReportData({
    required String propertyType,       // "Квартира", "Жилой дом", "Коммерческая недвижимость"
    required String address,
    required double area,
    required int rooms,
    required int floor,
    required int totalFloors,
    required String condition,
    required int yearBuilt,
    String? wallMaterial,
    required String location,            // напр. "г.Астана" / "г.Алматы"
    required String customerName,        // юр./физ. лицо-заказчик
    required String customerBin,         // БИН/ИИН заказчика
    required String customerAddress,
    required String ownerName,
    required String ownerIin,
    required String ownerLocation,
    required String contractBasis,       // "Договор залога №... от ..." / "Договор ипотеки №..."
    String? appraiserName,
    String? appraiserIin,
    String? appraiserCertificate,
  }) async {
    final results = await Future.wait([
      _fetchMarketContext(propertyType: propertyType, limit: 3),
      _fetchUserProfile(),
    ]);
 
    final marketData = results[0] as List<Map<String, dynamic>>;
    final marketContext = _buildMarketContext(marketData);
 
    final now = DateTime.now();
    final reportNumber =
        'SDF-${now.year}${_pad(now.month)}${_pad(now.day)}-${_randomDigits(5)}';
 
    final userPrompt = '''
Объект для оценки (Недвижимое имущество):
- Тип объекта: $propertyType
- Адрес: $address
- Площадь, м²: $area
- Количество комнат: $rooms
- Этаж/этажность: $floor/$totalFloors
- Состояние: $condition
- Год постройки: $yearBuilt
- Материал стен: ${wallMaterial ?? 'не указан'}
- Местонахождение (город): $location
- Дата составления/оценки: ${_pad(now.day)}.${_pad(now.month)}.${now.year}
- Номер отчёта: $reportNumber
 
Заказчик: $customerName, БИН/ИИН: $customerBin, адрес: $customerAddress
Собственник объекта: $ownerName, ИИН: $ownerIin, местонахождение: $ownerLocation
Основание оценки: $contractBasis
Оценщик: ${appraiserName ?? 'Мақсұтұлы Ғазиз'} (ИИН: ${appraiserIin ?? '930226300627'}),
Сертификат: ${appraiserCertificate ?? 'ESEP-KZ-77829-2026'}
 
$marketContext
 
Верни ТОЛЬКО валидный JSON без markdown и комментариев, строго по схеме:
{
  "report_number": "string (SDF-YYYYMMDD-NNNNN)",
  "report_date": "DD.MM.YYYY",
  "object_name": "string (например 'Недвижимое имущество')",
  "property_type": "string",
  "address": "string",
  "area": number,
  "rooms": number,
  "floor": number,
  "total_floors": number,
  "condition": "string",
  "year_built": number,
  "wall_material": "string|null",
  "encumbrance": "string (напр. 'Договор залога №... от ...')",
  "object_location": "string (город)",
  "valuation_purpose": "string (Определение рыночной стоимости объекта)",
  "valuation_assignment": "string (для целей передачи права требования / залога / ипотеки / иное)",
  "value_type": "Рыночная",
  "customer_name": "string",
  "customer_bin": "string",
  "customer_address": "string",
  "owner_name": "string",
  "owner_iin": "string",
  "owner_location": "string",
  "appraiser_name": "string",
  "appraiser_iin": "string",
  "appraiser_certificate": "string",
  "appraiser_chamber": "string (напр. СРО «Содружество оценщиков Казахстана»)",
  "legal_entity_name": "string (ТОО, заключившее договор с оценщиком)",
  "legal_entity_director": "string",
  "legal_entity_address": "string",
  "legal_entity_bin": "string",
  "comparables": [
    {
      "source_url": "string",
      "access_date": "DD.MM.YYYY",
      "offer_price": number,
      "address": "string",
      "area": number,
      "rooms": number,
      "floor": number,
      "total_floors": number,
      "condition": "string",
      "year_built": number
    }
  ],
  "corrections": {
    "trade_correction_pct": -5,
    "area_correction_pct": 0,
    "floor_correction_pct": 0,
    "condition_correction_pct": 0,
    "location_correction_pct": 0,
    "year_correction_pct": 0
  },
  "price_per_meter": number,
  "final_value": number,
  "final_value_words": "string (сумма прописью на русском)",
  "inspection_date": "DD.MM.YYYY",
  "inspection_result": "string (краткий вывод по акту осмотра)"
}
 
Правила расчёта:
1. Скорректированная цена каждого аналога = цена предложения × (1 + сумма_корректировок/100),
   где корректировка на торг применяется первой (обычно -3%..-6% для недвижимости, бери -5%,
   если нет иных данных).
2. Остальные корректировки (площадь, этаж, состояние, местоположение, год постройки) = 0%,
   если объект и аналоги совпадают по этим параметрам, иначе укажи обоснованный % (не более ±10%
   на каждый фактор).
3. price_per_meter = final_value / area, округлённое до целого тенге.
4. final_value = среднеарифметическое (или средневзвешенное, если явно заданы веса) скорректированных
   цен аналогов, округлённое до целого тенге.
5. Используй только реалистичные данные, согласованные с рыночным контекстом выше.
6. Если рыночных данных недостаточно для 3 аналогов — верни минимум 2 аналога, это допустимо.
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
          'max_tokens': 3072,
          'temperature': 0.3,
          'top_p': 0.9,
        });
 
        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {'Content-Type': 'application/json'},
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
        debugPrint('[Report] AI model $model succeeded');
        return RealEstateReportData.fromJson(reportJson);
      } catch (e) {
        lastError = e.toString();
        debugPrint('[Report] Model $model failed: $lastError');
        continue;
      }
    }
 
    debugPrint('[Report] All models failed. Last error: $lastError');
    return null;
  }
 
  static String _pad(int n) => n.toString().padLeft(2, '0');
 
  static String _randomDigits(int len) {
    final rnd = Random();
    return List.generate(len, (_) => rnd.nextInt(10)).join();
  }
/// Модель данных отчёта об оценке (по шаблону GaMa Group).
///
/// Покрывает все типы объектов: квартира, дом, земельный участок,
/// коммерческое помещение, авто. Содержит данные для PDF-генератора
/// и для хранения в таблице `reports`.
class ReportData {
  // ===== Заказчик =====
  final String clientName;
  final String clientIin;
  final bool clientIsOrg;
  final String clientAddress;

  // ===== Объект оценки =====
  final String propertyType; // 'Квартира', 'Дом', 'Земельный участок', 'Автомобиль', ...
  final String address;
  final double area;
  final int rooms;
  final int floor;
  final int totalFloors;
  final String condition;
  final int yearBuilt;
  final String cadastralNumber; // кадастровый номер (если есть)
  final String purpose; // назначение: 'Проживание', 'Коммерческое', ...

  // ===== Детальные характеристики (для таблиц Раздела 2) =====
  final String buildingType; // тип здания: многоквартирный жилой дом...
  final String wallMaterial; // материал стен
  final String buildingCondition; // тех. состояние здания
  final String communications; // инженерные коммуникации
  final String livingArea; // жилая площадь, кв.м.
  final String kitchenArea; // площадь кухни
  final String bathroom; // санузел: совмещенный/раздельный
  final String balcony; // балкон/лоджия
  final String renovationYear; // год ремонта
  final String layout; // планировка: обычная/улучшенная...

  // ===== Авто (заполняется для propertyType == 'Автомобиль') =====
  final Map<String, String> vehicleSpecs; // марка, модель, VIN, пробег, кузов, двигатель, цвет

  // ===== Фото объекта (до 10, пути в storage) =====
  final List<String> photoUrls;

  // ===== Осмотр =====
  final String inspectionDate; // дата осмотра
  final String clientIdDoc; // удостоверение заказчика: №, кем, когда

  // ===== Результаты =====
  final double estimatedPrice;
  final double priceRangeLow;
  final double priceRangeHigh;
  final double pricePerMeter;
  final double confidence;
  final List<ComparableProperty> comparables;
  final List<Recommendation> recommendations;

  // ===== Оформление =====
  final String appraisalDate; // дата оценки
  final String reportNumber; // № G-0338
  final String appraiserName; // Мақсұтұлы Ғазиз
  final String appraiserIin;
  final String appraiserCertificate; // свидетельство
  final String appraiserPalata; // палата оценщиков
  final String appraiserInsurance; // договор страхования
  final String legalEntityName; // ТОО «GaMa Group»
  final String legalEntityAddress;
  final String legalEntityBin;
  final String legalEntityIik;
  final String legalEntityBik;
  final String legalEntityBank;
  final String legalEntityKbe;
  final String legalEntityPhone;

  const ReportData({
    required this.clientName,
    required this.clientIin,
    this.clientIsOrg = false,
    this.clientAddress = '',
    required this.propertyType,
    required this.address,
    required this.area,
    required this.rooms,
    required this.floor,
    required this.totalFloors,
    required this.condition,
    required this.yearBuilt,
    this.cadastralNumber = '',
    this.purpose = 'Проживание',
    this.buildingType = '',
    this.wallMaterial = '',
    this.buildingCondition = '',
    this.communications = '',
    this.livingArea = '',
    this.kitchenArea = '',
    this.bathroom = '',
    this.balcony = '',
    this.renovationYear = '',
    this.layout = '',
    this.vehicleSpecs = const {},
    this.photoUrls = const [],
    this.inspectionDate = '',
    this.clientIdDoc = '',
    required this.estimatedPrice,
    required this.priceRangeLow,
    required this.priceRangeHigh,
    required this.pricePerMeter,
    required this.confidence,
    required this.comparables,
    required this.recommendations,
    required this.appraisalDate,
    this.reportNumber = '',
    this.appraiserName = '',
    this.appraiserIin = '',
    this.appraiserCertificate = '',
    this.appraiserPalata = '',
    this.appraiserInsurance = '',
    this.legalEntityName = '',
    this.legalEntityAddress = '',
    this.legalEntityBin = '',
    this.legalEntityIik = '',
    this.legalEntityBik = '',
    this.legalEntityBank = '',
    this.legalEntityKbe = '',
    this.legalEntityPhone = '',
  });

  factory ReportData.fromJson(Map<String, dynamic> json) {
    return ReportData(
      clientName: json['client_name'] as String? ?? 'Не указано',
      clientIin: json['client_iin'] as String? ?? '',
      clientIsOrg: json['client_is_org'] as bool? ?? false,
      clientAddress: json['client_address'] as String? ?? '',
      propertyType: json['property_type'] as String? ?? 'Квартира',
      address: json['address'] as String? ?? '',
      area: (json['area'] as num?)?.toDouble() ?? 0,
      rooms: json['rooms'] as int? ?? 0,
      floor: json['floor'] as int? ?? 0,
      totalFloors: json['total_floors'] as int? ?? 0,
      condition: json['condition'] as String? ?? 'Не указано',
      yearBuilt: json['year_built'] as int? ?? 0,
      cadastralNumber: json['cadastral_number'] as String? ?? '',
      purpose: json['purpose'] as String? ?? 'Проживание',
      buildingType: json['building_type'] as String? ?? '',
      wallMaterial: json['wall_material'] as String? ?? '',
      buildingCondition: json['building_condition'] as String? ?? '',
      communications: json['communications'] as String? ?? '',
      livingArea: json['living_area'] as String? ?? '',
      kitchenArea: json['kitchen_area'] as String? ?? '',
      bathroom: json['bathroom'] as String? ?? '',
      balcony: json['balcony'] as String? ?? '',
      renovationYear: json['renovation_year'] as String? ?? '',
      layout: json['layout'] as String? ?? '',
      vehicleSpecs: (json['vehicle_specs'] as Map<String, dynamic>?)?.cast<String, String>() ?? const {},
      photoUrls: (json['photo_urls'] as List<dynamic>?)?.cast<String>() ?? const [],
      inspectionDate: json['inspection_date'] as String? ?? '',
      clientIdDoc: json['client_id_doc'] as String? ?? '',
      estimatedPrice: (json['estimated_price'] as num?)?.toDouble() ?? 0,
      priceRangeLow: (json['price_range_low'] as num?)?.toDouble() ?? 0,
      priceRangeHigh: (json['price_range_high'] as num?)?.toDouble() ?? 0,
      pricePerMeter: (json['price_per_meter'] as num?)?.toDouble() ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
      comparables: (json['comparables'] as List<dynamic>?)
              ?.map((e) => ComparableProperty.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => Recommendation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      appraisalDate: json['appraisal_date'] as String? ?? '',
      reportNumber: json['report_number'] as String? ?? '',
      appraiserName: json['appraiser_name'] as String? ?? 'Айдар Нурланович',
      appraiserIin: json['appraiser_iin'] as String? ?? '',
      appraiserCertificate: json['appraiser_certificate'] as String? ?? '',
      appraiserPalata: json['appraiser_palata'] as String? ?? '',
      appraiserInsurance: json['appraiser_insurance'] as String? ?? '',
      legalEntityName: json['legal_entity_name'] as String? ?? '',
      legalEntityAddress: json['legal_entity_address'] as String? ?? '',
      legalEntityBin: json['legal_entity_bin'] as String? ?? '',
      legalEntityIik: json['legal_entity_iik'] as String? ?? '',
      legalEntityBik: json['legal_entity_bik'] as String? ?? '',
      legalEntityBank: json['legal_entity_bank'] as String? ?? '',
      legalEntityKbe: json['legal_entity_kbe'] as String? ?? '',
      legalEntityPhone: json['legal_entity_phone'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'client_name': clientName,
        'client_iin': clientIin,
        'client_is_org': clientIsOrg,
        'client_address': clientAddress,
        'property_type': propertyType,
        'address': address,
        'area': area,
        'rooms': rooms,
        'floor': floor,
        'total_floors': totalFloors,
        'condition': condition,
        'year_built': yearBuilt,
        'cadastral_number': cadastralNumber,
        'purpose': purpose,
        'building_type': buildingType,
        'wall_material': wallMaterial,
        'building_condition': buildingCondition,
        'communications': communications,
        'living_area': livingArea,
        'kitchen_area': kitchenArea,
        'bathroom': bathroom,
        'balcony': balcony,
        'renovation_year': renovationYear,
        'layout': layout,
        'vehicle_specs': vehicleSpecs,
        'photo_urls': photoUrls,
        'inspection_date': inspectionDate,
        'client_id_doc': clientIdDoc,
        'estimated_price': estimatedPrice,
        'price_range_low': priceRangeLow,
        'price_range_high': priceRangeHigh,
        'price_per_meter': pricePerMeter,
        'confidence': confidence,
        'comparables': comparables.map((e) => e.toJson()).toList(),
        'recommendations': recommendations.map((e) => e.toJson()).toList(),
        'appraisal_date': appraisalDate,
        'report_number': reportNumber,
        'appraiser_name': appraiserName,
        'appraiser_iin': appraiserIin,
        'appraiser_certificate': appraiserCertificate,
        'appraiser_palata': appraiserPalata,
        'appraiser_insurance': appraiserInsurance,
        'legal_entity_name': legalEntityName,
        'legal_entity_address': legalEntityAddress,
        'legal_entity_bin': legalEntityBin,
        'legal_entity_iik': legalEntityIik,
        'legal_entity_bik': legalEntityBik,
        'legal_entity_bank': legalEntityBank,
        'legal_entity_kbe': legalEntityKbe,
        'legal_entity_phone': legalEntityPhone,
      };

  String get formattedPrice =>
      '${estimatedPrice.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(?:\d{3})+(?!\d))'), (m) => '${m[1]} ')} ₸';

  String get formattedPriceRangeLow =>
      '${priceRangeLow.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(?:\d{3})+(?!\d))'), (m) => '${m[1]} ')} ₸';

  String get formattedPriceRangeHigh =>
      '${priceRangeHigh.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(?:\d{3})+(?!\d))'), (m) => '${m[1]} ')} ₸';

  String get formattedPricePerMeter =>
      '${pricePerMeter.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(?:\d{3})+(?!\d))'), (m) => '${m[1]} ')} ₸/м²';

  String get confidencePercent => '${(confidence * 100).round()}%';
}

class ComparableProperty {
  final String address;
  final double area;
  final double price;
  final String type;
  final String source;
  final String url; // ссылка на объявление (krisha.kz и т.п.)
  final List<AdjustmentItem> adjustments; // корректировки по элементам сравнения
  final double adjustedPrice; // цена после корректировок

  const ComparableProperty({
    required this.address,
    required this.area,
    required this.price,
    required this.type,
    required this.source,
    this.url = '',
    this.adjustments = const [],
    this.adjustedPrice = 0,
  });

  factory ComparableProperty.fromJson(Map<String, dynamic> json) {
    return ComparableProperty(
      address: json['address'] as String? ?? '',
      area: (json['area'] as num?)?.toDouble() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      type: json['type'] as String? ?? '',
      source: json['source'] as String? ?? '',
      url: json['url'] as String? ?? '',
      adjustments: (json['adjustments'] as List<dynamic>?)
              ?.map((e) => AdjustmentItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      adjustedPrice: (json['adjusted_price'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'address': address,
        'area': area,
        'price': price,
        'type': type,
        'source': source,
        'url': url,
        'adjustments': adjustments.map((e) => e.toJson()).toList(),
        'adjusted_price': adjustedPrice,
      };

  String get formattedPrice =>
      '${price.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(?:\d{3})+(?!\d))'), (m) => '${m[1]} ')} ₸';

  String get formattedAdjustedPrice =>
      '${adjustedPrice.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(?:\d{3})+(?!\d))'), (m) => '${m[1]} ')} ₸';
}

/// Корректировка аналога по элементу сравнения.
/// [percent] — знак учитывается: -10 = минус 10% (хуже аналог), +5 = плюс 5%.
class AdjustmentItem {
  final String name; // 'Местоположение', 'Площадь', 'Этаж', ...
  final double percent;

  const AdjustmentItem({required this.name, required this.percent});

  factory AdjustmentItem.fromJson(Map<String, dynamic> json) {
    return AdjustmentItem(
      name: json['name'] as String? ?? '',
      percent: (json['percent'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'percent': percent};

  String get formattedPercent =>
      '${percent > 0 ? '+' : ''}${percent.round()}%';
}

class Recommendation {
  final String icon;
  final String title;
  final String description;

  const Recommendation({
    required this.icon,
    required this.title,
    required this.description,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      icon: json['icon'] as String? ?? 'info',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'icon': icon,
        'title': title,
        'description': description,
      };
}

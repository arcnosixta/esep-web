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
  final String propertyType; // 'Квартира', 'Дом', 'Земельный участок', ...
  final String address;
  final double area;
  final int rooms;
  final int floor;
  final int totalFloors;
  final String condition;
  final int yearBuilt;
  final String cadastralNumber; // кадастровый номер (если есть)
  final String purpose; // назначение: 'Проживание', 'Коммерческое', ...

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

  const ComparableProperty({
    required this.address,
    required this.area,
    required this.price,
    required this.type,
    required this.source,
  });

  factory ComparableProperty.fromJson(Map<String, dynamic> json) {
    return ComparableProperty(
      address: json['address'] as String? ?? '',
      area: (json['area'] as num?)?.toDouble() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      type: json['type'] as String? ?? '',
      source: json['source'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'address': address,
        'area': area,
        'price': price,
        'type': type,
        'source': source,
      };

  String get formattedPrice =>
      '${price.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(?:\d{3})+(?!\d))'), (m) => '${m[1]} ')} ₸';
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

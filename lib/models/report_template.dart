class ReportData {
  final String clientName;
  final String clientIin;
  final bool clientIsOrg;
  final String propertyType;
  final String address;
  final double area;
  final int rooms;
  final int floor;
  final int totalFloors;
  final String condition;
  final int yearBuilt;
  final double estimatedPrice;
  final double priceRangeLow;
  final double priceRangeHigh;
  final double pricePerMeter;
  final double confidence;
  final List<ComparableProperty> comparables;
  final List<Recommendation> recommendations;
  final String appraisalDate;
  final String appraiserName;
  final String appraiserCertificate;

  const ReportData({
    required this.clientName,
    required this.clientIin,
    this.clientIsOrg = false,
    required this.propertyType,
    required this.address,
    required this.area,
    required this.rooms,
    required this.floor,
    required this.totalFloors,
    required this.condition,
    required this.yearBuilt,
    required this.estimatedPrice,
    required this.priceRangeLow,
    required this.priceRangeHigh,
    required this.pricePerMeter,
    required this.confidence,
    required this.comparables,
    required this.recommendations,
    required this.appraisalDate,
    required this.appraiserName,
    required this.appraiserCertificate,
  });

  factory ReportData.fromJson(Map<String, dynamic> json) {
    return ReportData(
      clientName: json['client_name'] as String? ?? 'Не указано',
      clientIin: json['client_iin'] as String? ?? '',
      clientIsOrg: json['client_is_org'] as bool? ?? false,
      propertyType: json['property_type'] as String? ?? 'Квартира',
      address: json['address'] as String? ?? '',
      area: (json['area'] as num?)?.toDouble() ?? 0,
      rooms: json['rooms'] as int? ?? 0,
      floor: json['floor'] as int? ?? 0,
      totalFloors: json['total_floors'] as int? ?? 0,
      condition: json['condition'] as String? ?? 'Не указано',
      yearBuilt: json['year_built'] as int? ?? 0,
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
      appraiserName: json['appraiser_name'] as String? ?? 'Айдар Нурланович',
      appraiserCertificate: json['appraiser_certificate'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'client_name': clientName,
        'client_iin': clientIin,
        'property_type': propertyType,
        'address': address,
        'area': area,
        'rooms': rooms,
        'floor': floor,
        'total_floors': totalFloors,
        'condition': condition,
        'year_built': yearBuilt,
        'estimated_price': estimatedPrice,
        'price_range_low': priceRangeLow,
        'price_range_high': priceRangeHigh,
        'price_per_meter': pricePerMeter,
        'confidence': confidence,
        'comparables': comparables.map((e) => e.toJson()).toList(),
        'recommendations': recommendations.map((e) => e.toJson()).toList(),
        'appraisal_date': appraisalDate,
        'appraiser_name': appraiserName,
        'appraiser_certificate': appraiserCertificate,
      };

  String get formattedPrice {
    return '${estimatedPrice.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} ₸';
  }

  String get formattedPriceRangeLow {
    return '${priceRangeLow.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} ₸';
  }

  String get formattedPriceRangeHigh {
    return '${priceRangeHigh.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} ₸';
  }

  String get formattedPricePerMeter {
    return '${pricePerMeter.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} ₸/м²';
  }

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

  String get formattedPrice {
    return '${price.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} ₸';
  }
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

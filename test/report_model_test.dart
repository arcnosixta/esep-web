import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:esep/models/report_template.dart';

void main() {
  test('ReportData JSON round-trip keeps new fields', () {
    final data = ReportData(
      clientName: 'Иванов Иван',
      clientIin: '900101300123',
      propertyType: 'Квартира',
      address: 'г. Алматы, ул. Абая 10',
      area: 55.0,
      rooms: 2,
      floor: 4,
      totalFloors: 9,
      condition: 'Хорошее',
      yearBuilt: 2005,
      cadastralNumber: 'КН-123',
      buildingType: 'Многоквартирный жилой дом',
      wallMaterial: 'Кирпич',
      livingArea: '38',
      kitchenArea: '9',
      bathroom: 'Раздельный',
      balcony: 'Лоджия',
      vehicleSpecs: {'make': 'Toyota', 'model': 'Camry'},
      photoUrls: ['report_photos/a.jpg'],
      inspectionDate: '11.08.2026',
      clientIdDoc: 'Удостоверение №123',
      estimatedPrice: 25000000,
      priceRangeLow: 23000000,
      priceRangeHigh: 27000000,
      pricePerMeter: 454545,
      confidence: 0.87,
      comparables: [
        ComparableProperty(
          address: 'ул. Пушкина 5',
          area: 52,
          price: 24000000,
          type: 'Квартира',
          source: 'krisha.kz',
          url: 'https://krisha.kz/a/view/12345',
          adjustments: const [
            AdjustmentItem(name: 'Этаж', percent: -3),
            AdjustmentItem(name: 'Состояние', percent: 5),
          ],
          adjustedPrice: 24480000,
        ),
      ],
      appraisalDate: '11.08.2026',
      reportNumber: 'G-2026-001',
      recommendations: const [],
    );

    final json = data.toJson();
    final restored = ReportData.fromJson(json);

    expect(restored.buildingType, 'Многоквартирный жилой дом');
    expect(restored.wallMaterial, 'Кирпич');
    expect(restored.livingArea, '38');
    expect(restored.vehicleSpecs['make'], 'Toyota');
    expect(restored.photoUrls, ['report_photos/a.jpg']);
    expect(restored.inspectionDate, '11.08.2026');
    expect(restored.clientIdDoc, contains('123'));
    expect(restored.comparables.single.url, 'https://krisha.kz/a/view/12345');
    expect(restored.comparables.single.adjustments.length, 2);
    expect(restored.comparables.single.adjustedPrice, 24480000);
  });

  test('AdjustmentItem percent formatting', () {
    final a = AdjustmentItem(name: 'Этаж', percent: -3);
    expect(a.formattedPercent, '-3%');
    final b = AdjustmentItem(name: 'Состояние', percent: 5);
    expect(b.formattedPercent, '+5%');
  });
}

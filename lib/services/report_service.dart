import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/report_template.dart';
import '../services/openrouter_service.dart';
import '../main.dart';

class ReportService {
  ReportService._();

  // ============================================
  // GENERATE REPORT DATA VIA AI
  // ============================================

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
    return OpenRouterService.generateReportData(
      propertyType: propertyType,
      address: address,
      area: area,
      rooms: rooms,
      floor: floor,
      totalFloors: totalFloors,
      condition: condition,
      yearBuilt: yearBuilt,
      clientName: clientName,
      clientIin: clientIin,
      clientPhone: clientPhone,
      clientEmail: clientEmail,
      clientIsOrg: clientIsOrg,
      appraiserName: appraiserName,
    );
  }

  // ============================================
  // BUILD PDF FROM ReportData
  // ============================================

  static Future<Uint8List> generatePdf(ReportData data) async {
    final pdf = pw.Document();

    final fontData = await rootBundle.load('assets/fonts/DejaVuSans.ttf');
    final fontBoldData = await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf');
    final font = pw.Font.ttf(fontData);
    final fontBold = pw.Font.ttf(fontBoldData);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(data, font, fontBold),
        footer: (context) => _buildFooter(data, font, fontBold),
        build: (context) => [
          _buildClientSection(data, font, fontBold),
          pw.SizedBox(height: 20),
          _buildPropertySection(data, font, fontBold),
          pw.SizedBox(height: 20),
          _buildPriceSection(data, font, fontBold),
          pw.SizedBox(height: 20),
          _buildComparablesSection(data, font, fontBold),
          pw.SizedBox(height: 20),
          _buildRecommendationsSection(data, font, fontBold),
          pw.SizedBox(height: 30),
          _buildSignatureSection(data, font, fontBold),
        ],
      ),
    );

    final bytes = await pdf.save();
    debugPrint('[Report] PDF generated: ${bytes.length} bytes');
    return bytes;
  }

  static pw.Widget _buildHeader(ReportData data, pw.Font font, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ОТЧЁТ ОБ ОЦЕНКЕ',
                  style: pw.TextStyle(font: fontBold, fontSize: 22),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Недвижимого имущества',
                  style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  pw.Text('Дата', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
                  pw.SizedBox(height: 2),
                  pw.Text(data.appraisalDate, style: pw.TextStyle(font: fontBold, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.grey300),
      ],
    );
  }

  static pw.Widget _buildFooter(ReportData data, pw.Font font, pw.Font fontBold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'ESEP — Единая Система Оценки Недвижимости Казахстана',
          style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500),
        ),
        pw.Text(
          '',
          style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500),
        ),
      ],
    );
  }

  static pw.Widget _buildClientSection(ReportData data, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '1. ДАННЫЕ ЗАКАЗЧИКА',
            style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.blue800),
          ),
          pw.SizedBox(height: 12),
          _infoRow(data.clientIsOrg ? 'Наименование' : 'ФИО', data.clientName, font, fontBold),
          if (data.clientIin.isNotEmpty)
            _infoRow(data.clientIsOrg ? 'БИН' : 'ИИН', data.clientIin, font, fontBold),
        ],
      ),
    );
  }

  static pw.Widget _buildPropertySection(ReportData data, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '2. ОПИСАНИЕ ОБЪЕКТА',
            style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.blue800),
          ),
          pw.SizedBox(height: 12),
          _infoRow('Тип объекта', data.propertyType, font, fontBold),
          _infoRow('Адрес', data.address, font, fontBold),
          _infoRow('Площадь', '${data.area} м²', font, fontBold),
          _infoRow('Комнат', '${data.rooms}', font, fontBold),
          _infoRow('Этаж', '${data.floor} / ${data.totalFloors}', font, fontBold),
          _infoRow('Состояние', data.condition, font, fontBold),
          if (data.yearBuilt > 0) _infoRow('Год постройки', '${data.yearBuilt}', font, fontBold),
        ],
      ),
    );
  }

  static pw.Widget _buildPriceSection(ReportData data, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '3. РЕЗУЛЬТАТЫ ОЦЕНКИ',
            style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.blue800),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('ОЦЕНОЧНАЯ СТОИМОСТЬ', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
                  pw.SizedBox(height: 4),
                  pw.Text(data.formattedPrice, style: pw.TextStyle(font: fontBold, fontSize: 18)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Уверенность', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
                  pw.SizedBox(height: 4),
                  pw.Text(data.confidencePercent, style: pw.TextStyle(font: fontBold, fontSize: 16)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: PdfColors.blue100),
          pw.SizedBox(height: 8),
          _infoRow('Диапазон (низ)', data.formattedPriceRangeLow, font, fontBold),
          _infoRow('Диапазон (выс)', data.formattedPriceRangeHigh, font, fontBold),
          _infoRow('Цена за м²', data.formattedPricePerMeter, font, fontBold),
        ],
      ),
    );
  }

  static pw.Widget _buildComparablesSection(ReportData data, pw.Font font, pw.Font fontBold) {
    if (data.comparables.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '4. АНАЛОГИ',
          style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.blue800),
        ),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(font: fontBold, fontSize: 9),
          cellStyle: pw.TextStyle(font: font, fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          cellAlignment: pw.Alignment.centerLeft,
          headerAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerLeft,
          },
          headers: ['Адрес', 'Площадь', 'Цена', 'Источник'],
          data: data.comparables.map((c) => [
            c.address,
            '${c.area} м²',
            c.formattedPrice,
            c.source,
          ]).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildRecommendationsSection(ReportData data, pw.Font font, pw.Font fontBold) {
    if (data.recommendations.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '5. РЕКОМЕНДАЦИИ',
          style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.blue800),
        ),
        pw.SizedBox(height: 12),
        ...data.recommendations.map((r) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 6,
                height: 6,
                margin: const pw.EdgeInsets.only(top: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue400,
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(r.title, style: pw.TextStyle(font: fontBold, fontSize: 10)),
                    pw.SizedBox(height: 2),
                    pw.Text(r.description, style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  static pw.Widget _buildSignatureSection(ReportData data, pw.Font font, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 10),
        pw.Text(
          '6. ПОДПИСЬ ОЦЕНЩИКА',
          style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.blue800),
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Оценщик:', style: pw.TextStyle(font: font, fontSize: 10)),
                pw.SizedBox(height: 2),
                pw.Text(data.appraiserName, style: pw.TextStyle(font: fontBold, fontSize: 11)),
                if (data.appraiserCertificate.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text('Сертификат: ${data.appraiserCertificate}', style: pw.TextStyle(font: font, fontSize: 9)),
                ],
              ],
            ),
            pw.SizedBox(width: 40),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Дата: ${data.appraisalDate}', style: pw.TextStyle(font: font, fontSize: 10)),
                  pw.SizedBox(height: 20),
                  pw.Container(
                    width: 200,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400)),
                    ),
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(
                      'Подпись / ЭЦП',
                      style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey500),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _infoRow(String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  // ============================================
  // UPLOAD PDF TO SUPABASE STORAGE
  // ============================================

  static Future<String?> uploadReportPdf(Uint8List bytes, String applicationId) async {
    try {
      final fileName = 'reports/report_${applicationId}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      await supabase.storage.from('reports').uploadBinary(fileName, bytes);

      final url = supabase.storage.from('reports').getPublicUrl(fileName);
      debugPrint('[Report] PDF uploaded: $url');
      return url;
    } catch (e) {
      debugPrint('[Report] Upload error: $e');
      return null;
    }
  }

  // ============================================
  // FULL FLOW: generate → PDF → upload
  // ============================================

  static Future<ReportResult> generateAndUploadReport({
    required String applicationId,
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
    String? appraiserName,
  }) async {
    final reportData = await generateReportData(
      propertyType: propertyType,
      address: address,
      area: area,
      rooms: rooms,
      floor: floor,
      totalFloors: totalFloors,
      condition: condition,
      yearBuilt: yearBuilt,
      clientName: clientName,
      clientIin: clientIin,
      appraiserName: appraiserName,
    );

    if (reportData == null) {
      return const ReportResult(success: false, error: 'AI не смог сгенерировать данные отчёта');
    }

    final pdfBytes = await generatePdf(reportData);
    final pdfUrl = await uploadReportPdf(pdfBytes, applicationId);

    return ReportResult(
      success: true,
      reportData: reportData,
      pdfBytes: pdfBytes,
      pdfUrl: pdfUrl,
    );
  }
}

class ReportResult {
  final bool success;
  final String? error;
  final ReportData? reportData;
  final Uint8List? pdfBytes;
  final String? pdfUrl;

  const ReportResult({
    required this.success,
    this.error,
    this.reportData,
    this.pdfBytes,
    this.pdfUrl,
  });
}

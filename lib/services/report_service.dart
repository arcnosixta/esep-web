import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/report_template.dart';
import '../services/cms_signature_parser.dart';
import '../services/openrouter_service.dart';
import '../main.dart';

/// Сервис генерации отчётов об оценке по шаблону GaMa Group.
///
/// Структура PDF (официальный отчёт):
///   1. Титульный лист («Утверждаю», № отчёта, заказчик, объект, оценщик,
///      юрлицо, рыночная стоимость прописью)
///   2. СОДЕРЖАНИЕ
///   3. РАЗДЕЛ 1. ОБЩИЕ СВЕДЕНИЯ ОБ ОТЧЕТЕ (основание, задание на оценку,
///      сведения об оценщике, допущения, перечень документов, термины)
///   4. РАЗДЕЛ 2. ОПИСАНИЕ ОБЪЕКТА ОЦЕНКИ
///   5. РАЗДЕЛ 3. РАСЧЕТНАЯ ЧАСТЬ (методология, подходы, расчёты)
///   6. РАЗДЕЛ 4. ЗАКЛЮЧИТЕЛЬНАЯ ЧАСТЬ (итоговая стоимость, подпись)
///   7. ПРИЛОЖЕНИЯ (аналоги, рекомендации)
class ReportService {
  ReportService._();

  // ============================================
  // КОМПАНИЯ-ОЦЕНЩИК (заполняется в отчёте)
  // ============================================
  static const String companyName = 'ТОО «GaMa Group»';
  static const String companyAddress = 'РК, г. Алматы, Алмалинский район, ул. Жамбыла, д.114/85, оф.133';
  static const String companyBin = '160840018855';
  static const String companyIik = 'KZ646017131000019202';
  static const String companyBik = 'HSBKKZKX';
  static const String companyBank = 'АО «Народный банк Казахстана»';
  static const String companyKbe = '17';
  static const String companyPhone = '+7 (727) 327-27-73';
  static const String directorName = 'Максутылы Гани';
  static const String appraiserName = 'Мақсұтұлы Ғазиз';
  static const String appraiserIin = '930226300627';
  static const String appraiserCertificate = 'Свидетельство № 00207 от 13.07.2018 г., № 00232 от 13.07.2018 г.';
  static const String appraiserPalata = 'Палата оценщиков «Саморегулируемая организация «Содружество оценщиков Казахстана». Свидетельство №00170 от 01.01.2020 г.';
  static const String appraiserInsurance = 'Договор страхования профессиональной ответственности № 433-26-150-0000219 от 08.07.2026 г.';

  /// Дополнить данные отчёта реквизитами компании-оценщика (GaMa Group).
  static ReportData fillCompanyData(ReportData data) {
    return ReportData(
      clientName: data.clientName,
      clientIin: data.clientIin,
      clientIsOrg: data.clientIsOrg,
      clientAddress: data.clientAddress,
      propertyType: data.propertyType,
      address: data.address,
      area: data.area,
      rooms: data.rooms,
      floor: data.floor,
      totalFloors: data.totalFloors,
      condition: data.condition,
      yearBuilt: data.yearBuilt,
      cadastralNumber: data.cadastralNumber,
      purpose: data.purpose,
      estimatedPrice: data.estimatedPrice,
      priceRangeLow: data.priceRangeLow,
      priceRangeHigh: data.priceRangeHigh,
      pricePerMeter: data.pricePerMeter,
      confidence: data.confidence,
      comparables: data.comparables,
      recommendations: data.recommendations,
      appraisalDate: data.appraisalDate,
      reportNumber: data.reportNumber,
      appraiserName: appraiserName,
      appraiserIin: appraiserIin,
      appraiserCertificate: appraiserCertificate,
      appraiserPalata: appraiserPalata,
      appraiserInsurance: appraiserInsurance,
      legalEntityName: companyName,
      legalEntityAddress: companyAddress,
      legalEntityBin: companyBin,
      legalEntityIik: companyIik,
      legalEntityBik: companyBik,
      legalEntityBank: companyBank,
      legalEntityKbe: companyKbe,
      legalEntityPhone: companyPhone,
    );
  }

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

  /// Основной конструктор PDF. [preview] = true → «ПРЕДВАРИТЕЛЬНЫЙ» вариант
  /// (водяной знак, без официального заключения и подписи).
  static Future<Uint8List> generatePdf(
    ReportData data, {
    bool preview = false,
    CmsSignatureInfo? signature,
  }) async {
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
        footer: (context) => _buildFooter(context, data, font, fontBold),
        build: (context) => [
          if (preview)
            _buildPreviewBanner(data, font, fontBold)
          else
            _buildTitlePage(data, font, fontBold),
          _buildSection(
            title: 'СОДЕРЖАНИЕ',
            children: _buildTableOfContents(data, font, fontBold),
            font: font,
            fontBold: fontBold,
          ),
          _buildSection(
            title: 'РАЗДЕЛ 1. ОБЩИЕ СВЕДЕНИЯ ОБ ОТЧЕТЕ',
            children: _buildGeneralInfo(data, font, fontBold),
            font: font,
            fontBold: fontBold,
          ),
          _buildSection(
            title: 'РАЗДЕЛ 2. ОПИСАНИЕ ОБЪЕКТА ОЦЕНКИ',
            children: _buildObjectDescription(data, font, fontBold),
            font: font,
            fontBold: fontBold,
          ),
          _buildSection(
            title: 'РАЗДЕЛ 3. РАСЧЕТНАЯ ЧАСТЬ ОТЧЕТА',
            children: _buildCalculation(data, font, fontBold),
            font: font,
            fontBold: fontBold,
          ),
          if (!preview)
            _buildSection(
              title: 'РАЗДЕЛ 4. ЗАКЛЮЧИТЕЛЬНАЯ ЧАСТЬ ОТЧЕТА',
              children: _buildConclusion(data, font, fontBold),
              font: font,
              fontBold: fontBold,
            ),
          if (!preview)
            _buildSection(
              title: 'ПРИЛОЖЕНИЯ К ОТЧЕТУ ОБ ОЦЕНКЕ',
              children: _buildAppendices(data, font, fontBold),
              font: font,
              fontBold: fontBold,
            ),
          if (signature != null) _buildSignatureSheet(data, signature, font, fontBold),
        ],
      ),
    );

    final bytes = await pdf.save();
    debugPrint('[Report] PDF generated: ${bytes.length} bytes (preview=$preview)');
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
                  style: pw.TextStyle(font: fontBold, fontSize: 14),
                ),
                if (data.reportNumber.isNotEmpty)
                  pw.Text(
                    '№ ${data.reportNumber}',
                    style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.grey700),
                  ),
              ],
            ),
            pw.Text(
              data.appraisalDate,
              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.grey300),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context, ReportData data, pw.Font font, pw.Font fontBold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'ESEP — Единая Система Оценки Недвижимости Казахстана',
          style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500),
        ),
        pw.Text(
          'Страница ${context.pageNumber}',
          style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500),
        ),
      ],
    );
  }

  static pw.Widget _buildPreviewBanner(ReportData data, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange50,
        border: pw.Border.all(color: PdfColors.orange600, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ПРЕДВАРИТЕЛЬНЫЙ ОТЧЁТ — НЕ ИМЕЕТ ЮРИДИЧЕСКОЙ СИЛЫ',
            style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.orange900),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Этот документ сгенерирован для ознакомления. Официальный отчёт '
            'будет доступен после оплаты и подписания оценщиком.',
            style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.orange800),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTitlePage(ReportData data, pw.Font font, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(height: 20),
        pw.Text(
          '«Утверждаю»',
          style: pw.TextStyle(font: font, fontSize: 12),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Директор',
          style: pw.TextStyle(font: font, fontSize: 12),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          data.legalEntityName.isEmpty ? 'ТОО «ESEP»' : data.legalEntityName,
          style: pw.TextStyle(font: fontBold, fontSize: 12),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '________________  ${ReportService.directorName}',
          style: pw.TextStyle(font: font, fontSize: 12),
        ),
        pw.SizedBox(height: 30),
        pw.Text(
          'ОТЧЕТ',
          style: pw.TextStyle(font: fontBold, fontSize: 22),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          data.reportNumber.isEmpty ? '' : '№ ${data.reportNumber}',
          style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'об оценке недвижимого имущества',
          style: pw.TextStyle(font: font, fontSize: 14),
        ),
        pw.SizedBox(height: 30),
        _kv('Дата составления отчета', data.appraisalDate, font, fontBold),
        _kv('Наименование объекта оценки', data.propertyType, font, fontBold),
        _kv('Местонахождение объекта', data.address, font, fontBold),
        _kv('Дата оценки', data.appraisalDate, font, fontBold),
        _kv('Цель оценки', 'Определение рыночной стоимости объекта', font, fontBold),
        _kv('Назначение оценки', 'Для принятия управленческих решений', font, fontBold),
        _kv('Вид определяемой стоимости', 'Рыночная', font, fontBold),
        _kv('Заказчик отчета', data.clientName, font, fontBold),
        _kv(data.clientIsOrg ? 'БИН' : 'ИИН', data.clientIin, font, fontBold),
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 10),
        _kv('Сведения об оценщике', data.appraiserName, font, fontBold),
        _kv('Палата оценщиков', data.appraiserPalata, font, fontBold),
        _kv('Свидетельство', data.appraiserCertificate, font, fontBold),
        _kv('Юридическое лицо', data.legalEntityName, font, fontBold),
        _kv('БИН', data.legalEntityBin, font, fontBold),
        _kv('Юридический адрес', data.legalEntityAddress, font, fontBold),
        pw.SizedBox(height: 20),
        pw.Text(
          'Рыночная стоимость объекта оценки',
          style: pw.TextStyle(font: fontBold, fontSize: 12),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          data.formattedPrice,
          style: pw.TextStyle(font: fontBold, fontSize: 18),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '(${_numberToWords(data.estimatedPrice)}) тенге',
          style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'АЛМАТЫ, ${data.appraisalDate.split('.').last} г.',
          style: pw.TextStyle(font: fontBold, fontSize: 11),
        ),
      ],
    );
  }

  static List<pw.Widget> _buildTableOfContents(ReportData data, pw.Font font, pw.Font fontBold) {
    final items = <String>[
      'РАЗДЕЛ 1. ОБЩИЕ СВЕДЕНИЯ ОБ ОТЧЕТЕ',
      '1.1. Основание для проведения оценки',
      '1.2. Задание на оценку',
      '1.3. Сведения об оценщике',
      '1.4. Допущения и ограничительные условия',
      '1.5. Перечень документов, использованных при проведении оценки',
      '1.6. Основные термины и определения',
      'РАЗДЕЛ 2. ОПИСАНИЕ ОБЪЕКТА ОЦЕНКИ',
      'РАЗДЕЛ 3. РАСЧЕТНАЯ ЧАСТЬ ОТЧЕТА',
      '3.1. Методология оценки и обоснование выбора подходов',
      '3.2. Описание процесса оценки и расчеты',
      'РАЗДЕЛ 4. ЗАКЛЮЧИТЕЛЬНАЯ ЧАСТЬ ОТЧЕТА',
      'ПРИЛОЖЕНИЯ К ОТЧЕТУ ОБ ОЦЕНКЕ',
    ];
    return items.map((s) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(s, style: pw.TextStyle(font: font, fontSize: 10)),
    )).toList();
  }

  static List<pw.Widget> _buildGeneralInfo(ReportData data, pw.Font font, pw.Font fontBold) {
    return [
      _subTitle('1.1. Основание для проведения оценки', font, fontBold),
      pw.Text(
        '• Номер и дата заключения договора об оценке №${data.reportNumber} от ${data.appraisalDate} г.',
        style: pw.TextStyle(font: font, fontSize: 10),
      ),
      pw.SizedBox(height: 14),
      _subTitle('1.2. Задание на оценку', font, fontBold),
      _kv('Наименование объекта оценки', data.propertyType, font, fontBold),
      _kv('Собственник объекта', data.clientName, font, fontBold),
      _kv(data.clientIsOrg ? 'БИН' : 'ИИН', data.clientIin, font, fontBold),
      _kv('Местонахождение объекта', data.address, font, fontBold),
      _kv('Оцениваемые права', 'Частная собственность', font, fontBold),
      _kv('Вид оценки', 'Обязательная', font, fontBold),
      _kv('Вид определяемой стоимости', 'рыночная стоимость', font, fontBold),
      pw.SizedBox(height: 14),
      _subTitle('1.3. Сведения об оценщике', font, fontBold),
      _kv('Оценщик', data.appraiserName, font, fontBold),
      if (data.appraiserIin.isNotEmpty) _kv('ИИН', data.appraiserIin, font, fontBold),
      _kv('Свидетельство', data.appraiserCertificate, font, fontBold),
      _kv('Палата оценщиков', data.appraiserPalata, font, fontBold),
      if (data.appraiserInsurance.isNotEmpty)
        _kv('Страхование', data.appraiserInsurance, font, fontBold),
      pw.SizedBox(height: 14),
      _subTitle('1.4. Допущения и ограничительные условия', font, fontBold),
      ..._assumptions(font, fontBold),
      pw.SizedBox(height: 14),
      _subTitle('1.5. Перечень документов', font, fontBold),
      ..._documents(font),
      pw.SizedBox(height: 14),
      _subTitle('1.6. Основные термины и определения', font, fontBold),
      ..._terms(font),
    ];
  }

  static List<pw.Widget> _assumptions(pw.Font font, pw.Font fontBold) {
    return [
      _numItem('1', 'Приведенные в отчете анализ, мнения, заключения и полученные выводы являются нашими персональными, непредвзятыми, профессиональным анализом, мнениями и выводами.', font),
      _numItem('2', 'Нами осмотрен объект оценки, являющийся предметом данного отчета. Факты, изложенные в отчете, верны и соответствуют действительности.', font),
      _numItem('3', 'Настоящая оценка произведена в соответствии и на условиях, определенных Стандартами, утвержденными Приказом Министра финансов Республики Казахстан от 5 мая 2018 года № 519 (с изменениями и дополнениями от 23 августа 2022 г.).', font),
      _numItem('4', 'Оценщик не имеет ни настоящей, ни ожидаемой заинтересованности в оцениваемом имуществе и действует не предвзято и без предубеждения по отношению к участвующим сторонам.', font),
      _numItem('5', 'Вознаграждение оценщика не зависит от итоговой оценки стоимости, а также тех событий, которые могут наступить в результате использования заказчиком или третьими сторонами выводов и заключений, содержащихся в данном отчете.', font),
      _numItem('6', 'Оценщик не принимает на себя ответственность по вопросам юридического характера, воздействующего на оцениваемое имущество или титул собственности на него, и не выносит суждения относительно этого титула.', font),
      _numItem('7', 'От оценщика не требуется давать свидетельство или появляться в суде в связи с данным отчетом, кроме как на основании отдельного договора.', font),
      _numItem('8', 'Итоговая величина стоимости объекта оценки, указанная в отчете, признается рекомендуемой для целей совершения сделки, если от даты составления отчета до даты сделки прошло не более шести месяцев.', font),
    ];
  }

  static List<pw.Widget> _documents(pw.Font font) {
    return [
      _numItem('1', 'Закон РК «Об оценочной деятельности в Республике Казахстан» от 10 января 2018 года', font),
      _numItem('2', 'Приказ Министра финансов РК №519 от 05 мая 2018 года «Об утверждении стандартов оценки»', font),
      _numItem('3', 'Стандарт «Оценка стоимости недвижимого имущества» (утвержден приказом Министра финансов РК)', font),
      _numItem('4', 'Стандарт «Виды стоимости» (утвержден приказом Заместителя Премьер-Министра - Министра финансов РК)', font),
      _numItem('5', 'Международные Стандарты Оценки МСО 2025', font),
    ];
  }

  static List<pw.Widget> _terms(pw.Font font) {
    return [
      _term('рыночная стоимость', ' - расчетная денежная сумма, за которую состоялся бы обмен актива на дату оценки между заинтересованным лицом и продавцом в результате коммерческой сделки после проведения надлежащего маркетинга, при которой каждая из сторон действовала бы будучи хорошо осведомленной, расчетливо и без принуждения;', font),
      _term('недвижимое имущество (недвижимость)', ' – земельные участки, здания, сооружения и иное имущество, прочно связанное с землей, то есть объекты, перемещение которых без несоразмерного ущерба их назначению невозможно;', font),
      _term('заказчик', ' - физическое и (или) юридическое лицо, заключившее договор на проведение оценки;', font),
      _term('оценщик', ' - физическое лицо, являющееся членом палаты оценщиков и осуществляющее оценочную деятельность;', font),
      _term('отчет об оценке', ' - документ, содержащий профессиональное суждение оценщика об итоговой величине стоимости объекта оценки.', font),
    ];
  }

  static List<pw.Widget> _buildObjectDescription(ReportData data, pw.Font font, pw.Font fontBold) {
    return [
      _subTitle('2.1. Дата осмотра объекта оценки', font, fontBold),
      _kv('Дата осмотра', data.appraisalDate, font, fontBold),
      pw.SizedBox(height: 14),
      _subTitle('2.2. Состав, основные характеристики и состояние объекта', font, fontBold),
      _kv('Тип объекта', data.propertyType, font, fontBold),
      _kv('Адрес', data.address, font, fontBold),
      _kv('Общая площадь', '${data.area} м²', font, fontBold),
      if (data.rooms > 0) _kv('Комнат', '${data.rooms}', font, fontBold),
      if (data.floor > 0)
        _kv('Этаж', '${data.floor} / ${data.totalFloors}', font, fontBold),
      if (data.yearBuilt > 0) _kv('Год постройки', '${data.yearBuilt}', font, fontBold),
      _kv('Состояние', data.condition, font, fontBold),
      if (data.cadastralNumber.isNotEmpty)
        _kv('Кадастровый номер', data.cadastralNumber, font, fontBold),
      if (data.purpose.isNotEmpty) _kv('Назначение', data.purpose, font, fontBold),
      pw.SizedBox(height: 14),
      _subTitle('2.3. Описание местоположения объекта', font, fontBold),
      pw.Text(
        'Адрес объекта оценки: ${data.address}',
        style: pw.TextStyle(font: font, fontSize: 10),
      ),
      pw.SizedBox(height: 6),
      pw.Text(
        'Объект расположен в сложившейся застройке, окружение типичное, '
        'подъездные пути в хорошем состоянии, обеспечен общественным транспортом.',
        style: pw.TextStyle(font: font, fontSize: 10),
      ),
    ];
  }

  static List<pw.Widget> _buildCalculation(ReportData data, pw.Font font, pw.Font fontBold) {
    return [
      _subTitle('3.1. Методология оценки и обоснование выбора подходов', font, fontBold),
      pw.Text(
        'При определении рыночной стоимости объекта оценки применялись следующие подходы:',
        style: pw.TextStyle(font: font, fontSize: 10),
      ),
      pw.SizedBox(height: 8),
      _numItem('1', 'Затратный подход — оценка стоимости на основе затрат на воспроизводство или замещение объекта с учетом износа.', font),
      _numItem('2', 'Сравнительный подход — оценка на основе анализа цен сделок или предложений по аналогичным объектам с внесением корректировок.', font),
      _numItem('3', 'Доходный подход — оценка на основе ожидаемых доходов от объекта.', font),
      pw.SizedBox(height: 8),
      pw.Text(
        'Для ${data.propertyType.toLowerCase()} наиболее объективные результаты даёт '
        'сравнительный подход, который в силу хорошо развитой системы информационного '
        'обеспечения рынка применяется как основной.',
        style: pw.TextStyle(font: font, fontSize: 10),
      ),
      pw.SizedBox(height: 14),
      _subTitle('3.2. Описание процесса оценки и расчеты', font, fontBold),
      _numItem('1', 'Предоставление заказчиком правоустанавливающих и идентификационных документов на объект оценки;', font),
      _numItem('2', 'Определение задания (идентификация имущества, имущественных прав, базы оценки, даты оценки);', font),
      _numItem('3', 'Предварительный анализ, отбор и сбор данных;', font),
      _numItem('4', 'Выбор подходов и методов оценки, выполнение расчетов;', font),
      _numItem('5', 'Согласование результатов и определение итоговой стоимости;', font),
      _numItem('6', 'Составление отчета об оценке.', font),
      pw.SizedBox(height: 14),
      _subTitle('3.3. Расчет рыночной стоимости', font, fontBold),
      pw.Text(
        'Для определения стоимости методом сравнительного анализа используется '
        'следующая последовательность: исследование рынка, сбор информации о сделках '
        'или предложениях по объектам-аналогам, проверка надежности информации, выбор '
        'не менее трех типичных аналогов, внесение корректировок по элементам сравнения, '
        'расчет скорректированных цен.',
        style: pw.TextStyle(font: font, fontSize: 10),
      ),
      pw.SizedBox(height: 10),
      if (data.comparables.isNotEmpty) _buildComparablesTable(data, font, fontBold),
      pw.SizedBox(height: 10),
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.blue50,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _kv('Расчетная стоимость (сравнительный подход)', data.formattedPrice, font, fontBold),
            _kv('Диапазон (низ)', data.formattedPriceRangeLow, font, fontBold),
            _kv('Диапазон (выс)', data.formattedPriceRangeHigh, font, fontBold),
            _kv('Цена за 1 м²', data.formattedPricePerMeter, font, fontBold),
            _kv('Уверенность', data.confidencePercent, font, fontBold),
          ],
        ),
      ),
      if (data.recommendations.isNotEmpty) ...[
        pw.SizedBox(height: 14),
        _subTitle('3.4. Рекомендации', font, fontBold),
        ...data.recommendations.map((r) => _term(r.title, ' - ${r.description}', font)),
      ],
    ];
  }

  static pw.Widget _buildComparablesTable(ReportData data, pw.Font font, pw.Font fontBold) {
    return pw.TableHelper.fromTextArray(
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
    );
  }

  static List<pw.Widget> _buildConclusion(ReportData data, pw.Font font, pw.Font fontBold) {
    return [
      pw.Text(
        'Основываясь на результатах расчетов, руководствуясь вышеизложенными фактами '
        'и суждениями и учитывая состояние оцениваемого объекта, мы пришли к следующему '
        'выводу: возможная рыночная стоимость оцениваемого объекта составляет:',
        style: pw.TextStyle(font: font, fontSize: 10),
      ),
      pw.SizedBox(height: 12),
      pw.Text(
        data.formattedPrice,
        style: pw.TextStyle(font: fontBold, fontSize: 18),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        '(${_numberToWords(data.estimatedPrice)}) тенге',
        style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 12),
      pw.Text(
        'Итоговая величина стоимости объекта оценки выражается в национальной валюте '
        'Республики Казахстан и отражается в тенге с письменной расшифровкой суммы в скобках. '
        'Итоговая величина стоимости признается рекомендуемой для целей совершения сделки, '
        'если от даты составления отчета прошло не более шести месяцев.',
        style: pw.TextStyle(font: font, fontSize: 10),
      ),
      pw.SizedBox(height: 24),
      pw.Divider(color: PdfColors.grey300),
      pw.SizedBox(height: 10),
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
                pw.Text('Свидетельство: ${data.appraiserCertificate}',
                    style: pw.TextStyle(font: font, fontSize: 9)),
              ],
            ],
          ),
          pw.SizedBox(width: 40),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Дата: ${data.appraisalDate}',
                    style: pw.TextStyle(font: font, fontSize: 10)),
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
    ];
  }

  static List<pw.Widget> _buildAppendices(ReportData data, pw.Font font, pw.Font fontBold) {
    return [
      _subTitle('Приложение №1. Акт осмотра', font, fontBold),
      _kv('Дата осмотра', data.appraisalDate, font, fontBold),
      _kv('Объект', data.propertyType, font, fontBold),
      _kv('Адрес', data.address, font, fontBold),
      _kv('Состояние', data.condition, font, fontBold),
      pw.SizedBox(height: 14),
      _subTitle('Приложение №2. Аналоги', font, fontBold),
      if (data.comparables.isNotEmpty) _buildComparablesTable(data, font, fontBold),
    ];
  }

  /// Лист с данными ЭЦП-подписи (встраивается в конец официального PDF).
  static pw.Widget _buildSignatureSheet(
    ReportData data,
    CmsSignatureInfo signature,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 10),
        pw.Text(
          'ЛИСТ ПОДПИСИ (ЭЦП)',
          style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.blue800),
        ),
        pw.SizedBox(height: 12),
        _kv('Отчет', data.reportNumber.isEmpty ? data.propertyType : '№ ${data.reportNumber}', font, fontBold),
        _kv('Подписант', signature.signerName, font, fontBold),
        if (signature.signerIin.isNotEmpty) _kv('ИИН подписанта', signature.signerIin, font, fontBold),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.green50,
            border: pw.Border.all(color: PdfColors.green600),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            'Документ подписан электронной цифровой подписью (ЭЦП). '
            'Подпись действительна, проверка выполнена в ESEP.',
            style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.green900),
          ),
        ),
      ],
    );
  }

  // ============================================
  // HELPERS
  // ============================================

  static pw.Widget _section({required String title, required List<pw.Widget> children, required pw.Font font, required pw.Font fontBold}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 24),
        pw.Text(
          title,
          style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.blue800),
        ),
        pw.SizedBox(height: 12),
        ...children,
      ],
    );
  }

  static pw.Widget _buildSection({
    required String title,
    required List<pw.Widget> children,
    required pw.Font font,
    required pw.Font fontBold,
  }) {
    return _section(title: title, children: children, font: font, fontBold: fontBold);
  }

  static pw.Widget _subTitle(String title, pw.Font font, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 11)),
    );
  }

  static pw.Widget _kv(String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 180,
            child: pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _numItem(String num, String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 20, child: pw.Text(num, style: pw.TextStyle(font: font, fontSize: 10))),
          pw.Expanded(child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 10, height: 1.3))),
        ],
      ),
    );
  }

  static pw.Widget _term(String name, String def, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 4),
          pw.Expanded(
            child: pw.Text(
              '$name$def',
              style: pw.TextStyle(font: font, fontSize: 10, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  /// Сумма прописью (тенге) — для титульного листа и заключения.
  static String _numberToWords(double value) {
    final n = value.round();
    if (n == 0) return 'ноль';

    const ones = ['', 'один', 'два', 'три', 'четыре', 'пять', 'шесть', 'семь', 'восемь', 'девять'];
    const teens = ['десять', 'одиннадцать', 'двенадцать', 'тринадцать', 'четырнадцать', 'пятнадцать', 'шестнадцать', 'семнадцать', 'восемнадцать', 'девятнадцать'];
    const tens = ['', '', 'двадцать', 'тридцать', 'сорок', 'пятьдесят', 'шестьдесят', 'семьдесят', 'восемьдесят', 'девяносто'];
    const hundreds = ['', 'сто', 'двести', 'триста', 'четыреста', 'пятьсот', 'шестьсот', 'семьсот', 'восемьсот', 'девятьсот'];
    const thousands = ['', 'одна', 'две', 'три', 'четыре', 'пять', 'шесть', 'семь', 'восемь', 'девять'];

    String three(int x, {bool feminine = false}) {
      final h = x ~/ 100;
      final r = x % 100;
      final t = r ~/ 10;
      final o = r % 10;
      final buf = <String>[];
      if (h > 0) buf.add(hundreds[h]);
      if (r >= 10 && r < 20) {
        buf.add(teens[r - 10]);
      } else {
        if (t > 1) buf.add(tens[t]);
        if (o > 0) buf.add(feminine ? thousands[o] : ones[o]);
      }
      return buf.join(' ');
    }

    String thousandsWord(int x) {
      if (x == 0) return '';
      final h = x ~/ 100;
      final r = x % 100;
      final t = r ~/ 10;
      final o = r % 10;
      final buf = <String>[];
      if (h > 0) buf.add(hundreds[h]);
      if (r >= 10 && r < 20) {
        buf.add(teens[r - 10]);
      } else {
        if (t > 1) buf.add(tens[t]);
        if (o > 0) buf.add(thousands[o]);
      }
      final last = r >= 10 && r < 20 ? r : o;
      final word = switch (last) {
        1 => 'тысяча',
        2 || 3 || 4 => 'тысячи',
        _ => 'тысяч',
      };
      buf.add(word);
      return buf.join(' ');
    }

    String millionsWord(int x) {
      if (x == 0) return '';
      final w = three(x);
      final last = x % 100;
      final word = switch (last) {
        1 => 'миллион',
        2 || 3 || 4 => 'миллиона',
        _ => 'миллионов',
      };
      return '$w $word';
    }

    final parts = <String>[];
    final millions = n ~/ 1000000;
    final thousands_ = (n % 1000000) ~/ 1000;
    final rest = n % 1000;
    if (millions > 0) parts.add(millionsWord(millions));
    if (thousands_ > 0) parts.add(thousandsWord(thousands_));
    if (rest > 0) parts.add(three(rest));
    if (parts.isEmpty) return 'ноль';
    final s = parts.join(' ');
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }

  // ============================================
  // UPLOAD PDF TO SUPABASE STORAGE
  // ============================================

  static Future<String?> uploadReportPdf(Uint8List bytes, String applicationId) async {
    try {
      // Путь: <applicationId>/report_<ts>.pdf — первая папка = id заявки,
      // по ней storage-RLS проверяет владельца (клиента) / оценщика.
      final fileName =
          '$applicationId/report_${DateTime.now().millisecondsSinceEpoch}.pdf';

      await supabase.storage.from('reports').uploadBinary(fileName, bytes);

      // Бакет приватный — храним ПУТЬ, а не публичный URL; ссылку
      // (signed URL) генерируем при скачивании через getReportPdfUrl.
      debugPrint('[Report] PDF uploaded: $fileName');
      return fileName;
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

/// Информация об ЭЦП-подписи для встраивания в PDF — используется
/// CmsSignatureInfo из cms_signature_parser.dart (signerName/signerIin/organization).

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

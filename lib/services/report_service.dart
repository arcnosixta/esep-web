import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/report_template.dart';
import '../services/cms_signature_parser.dart';
import '../services/openrouter_service.dart';
import '../services/supabase_service.dart';
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
      buildingType: data.buildingType,
      wallMaterial: data.wallMaterial,
      buildingCondition: data.buildingCondition,
      communications: data.communications,
      livingArea: data.livingArea,
      kitchenArea: data.kitchenArea,
      bathroom: data.bathroom,
      balcony: data.balcony,
      renovationYear: data.renovationYear,
      layout: data.layout,
      vehicleSpecs: data.vehicleSpecs,
      photoUrls: data.photoUrls,
      inspectionDate: data.inspectionDate,
      clientIdDoc: data.clientIdDoc,
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
  // REPORT NUMBER (счётчик G-XXXX в Supabase)
  // ============================================

  /// Выдать следующий номер отчёта через RPC next_report_number().
  /// Формат: G-YYYY-NNNN (нумерация продолжается, счётчик в БД).
  static Future<String> nextReportNumber() async {
    try {
      final res = await SupabaseService.rpc('next_report_number');
      return res as String? ?? 'G-${DateTime.now().year}-0001';
    } catch (e) {
      debugPrint('[Report] nextReportNumber error: $e');
      return 'G-${DateTime.now().year}-0001';
    }
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
  /// [photos] — байты фотографий объекта (до 10), вставляются в приложение.
  static Future<Uint8List> generatePdf(
    ReportData data, {
    bool preview = false,
    CmsSignatureInfo? signature,
    List<Uint8List> photos = const [],
  }) async {
    final pdf = pw.Document();

    final fontData = await rootBundle.load('assets/fonts/DejaVuSans.ttf');
    final fontBoldData = await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf');
    final font = pw.Font.ttf(fontData);
    final fontBold = pw.Font.ttf(fontBoldData);

    pw.MultiPage page(List<pw.Widget> children) => pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => _buildHeader(data, font, fontBold),
          footer: (context) => _buildFooter(context, data, font, fontBold),
          build: (context) => children,
        );

    // 1. Титульный лист (или предварительный баннер)
    pdf.addPage(page([
      if (preview)
        _buildPreviewBanner(data, font, fontBold)
      else
        _buildTitlePage(data, font, fontBold),
    ]));

    // 2. Содержание
    pdf.addPage(page([
      _buildSection(
        title: 'СОДЕРЖАНИЕ',
        children: _buildTableOfContents(data, font, fontBold),
        font: font,
        fontBold: fontBold,
      ),
    ]));

    // 3. Раздел 1. Общие сведения (основание, задание, оценщик, допущения,
    //    документы, термины) — 3–5 страниц
    pdf.addPage(page([
      _buildSection(
        title: 'РАЗДЕЛ 1. ОБЩИЕ СВЕДЕНИЯ ОБ ОТЧЕТЕ',
        children: _buildGeneralInfo(data, font, fontBold),
        font: font,
        fontBold: fontBold,
      ),
    ]));

    // 4. Раздел 2. Описание объекта оценки (таблицы характеристик)
    pdf.addPage(page([
      _buildSection(
        title: 'РАЗДЕЛ 2. ОПИСАНИЕ ОБЪЕКТА ОЦЕНКИ',
        children: _buildObjectDescription(data, font, fontBold),
        font: font,
        fontBold: fontBold,
      ),
    ]));

    // 5. Раздел 3. Расчетная часть (методология + расчеты + согласование)
    pdf.addPage(page([
      _buildSection(
        title: 'РАЗДЕЛ 3. РАСЧЕТНАЯ ЧАСТЬ ОТЧЕТА',
        children: _buildCalculation(data, font, fontBold),
        font: font,
        fontBold: fontBold,
      ),
    ]));

    if (!preview) {
      // 6. Раздел 4. Заключительная часть (итоговая стоимость, подпись)
      pdf.addPage(page([
        _buildSection(
          title: 'РАЗДЕЛ 4. ЗАКЛЮЧИТЕЛЬНАЯ ЧАСТЬ ОТЧЕТА',
          children: _buildConclusion(data, font, fontBold),
          font: font,
          fontBold: fontBold,
        ),
      ]));
      // 7. Приложения (акт осмотра, аналоги, фото, документы)
      pdf.addPage(page([
        _buildSection(
          title: 'ПРИЛОЖЕНИЯ К ОТЧЕТУ ОБ ОЦЕНКЕ',
          children: _buildAppendices(data, font, fontBold, photos: photos),
          font: font,
          fontBold: fontBold,
        ),
      ]));
    }

    if (signature != null) {
      pdf.addPage(page([_buildSignatureSheet(data, signature, font, fontBold)]));
    }

    final bytes = await pdf.save();
    debugPrint('[Report] PDF generated: ${bytes.length} bytes (preview=$preview, photos=${photos.length})');
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
                  style: pw.TextStyle(font: fontBold, fontSize: 15),
                ),
                if (data.reportNumber.isNotEmpty)
                  pw.Text(
                    '№ ${data.reportNumber}',
                    style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.grey700),
                  ),
              ],
            ),
            pw.Text(
              data.appraisalDate,
              style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey600),
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
          style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey500),
        ),
        pw.Text(
          'Страница ${context.pageNumber}',
          style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey500),
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
            style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.orange900),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Этот документ сгенерирован для ознакомления. Официальный отчёт '
            'будет доступен после оплаты и подписания оценщиком.',
            style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.orange800),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTitlePage(ReportData data, pw.Font font, pw.Font fontBold) {
    final isCar = _isCar(data.propertyType);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(height: 20),
        pw.Text(
          '«Утверждаю»',
          style: pw.TextStyle(font: font, fontSize: 13),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Директор',
          style: pw.TextStyle(font: font, fontSize: 13),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          data.legalEntityName.isEmpty ? 'ТОО «GaMa Group»' : data.legalEntityName,
          style: pw.TextStyle(font: fontBold, fontSize: 13),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '________________  ${ReportService.directorName}',
          style: pw.TextStyle(font: font, fontSize: 13),
        ),
        pw.SizedBox(height: 30),
        pw.Text(
          'ОТЧЕТ',
          style: pw.TextStyle(font: fontBold, fontSize: 26),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          data.reportNumber.isEmpty ? '' : '№ ${data.reportNumber}',
          style: pw.TextStyle(font: fontBold, fontSize: 15, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          isCar ? 'об оценке движимого имущества' : 'об оценке недвижимого имущества',
          style: pw.TextStyle(font: font, fontSize: 15),
        ),
        pw.SizedBox(height: 30),
        _kv('Дата составления отчета', data.appraisalDate, font, fontBold),
        _kv('Наименование объекта оценки', data.propertyType, font, fontBold),
        _kv('Местонахождение объекта', data.address, font, fontBold),
        _kv('Дата оценки', data.appraisalDate, font, fontBold),
        _kv('Вид оценки', 'Независимая', font, fontBold),
        _kv('Цель оценки', 'Определение рыночной стоимости объекта', font, fontBold),
        _kv('Назначение оценки', 'Для принятия управленческих решений', font, fontBold),
        _kv('Вид определяемой стоимости', 'Рыночная', font, fontBold),
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
          style: pw.TextStyle(font: fontBold, fontSize: 13),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          data.formattedPrice,
          style: pw.TextStyle(font: fontBold, fontSize: 20),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '(${_numberToWords(data.estimatedPrice)}) тенге',
          style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'АЛМАТЫ, ${data.appraisalDate.split('.').last} г.',
          style: pw.TextStyle(font: fontBold, fontSize: 12),
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
      'РАЗДЕЛ 2. ОБЩАЯ ИНФОРМАЦИЯ И ОПИСАНИЕ ОБЪЕКТА ОЦЕНКИ',
      '2.1. Дата осмотра объекта оценки',
      '2.2. Состав, основные характеристики, назначение, текущее использование и состояние объекта оценки',
      '2.3. Описание местоположения объекта оценки',
      'РАЗДЕЛ 3. РАСЧЕТНАЯ ЧАСТЬ ОТЧЕТА',
      '3.1. Методология оценки и обоснование выбора подходов',
      '3.2. Описание процесса оценки и расчеты, выполненные с использованием выбранных подходов/методов',
      '3.3. Согласование результатов оценки',
      'РАЗДЕЛ 4. ЗАКЛЮЧИТЕЛЬНАЯ ЧАСТЬ ОТЧЕТА',
      'ПРИЛОЖЕНИЯ К ОТЧЕТУ ОБ ОЦЕНКЕ',
    ];
    return items.map((s) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(s, style: pw.TextStyle(font: font, fontSize: 12)),
    )).toList();
  }

  static List<pw.Widget> _buildGeneralInfo(ReportData data, pw.Font font, pw.Font fontBold) {
    return [
      _subTitle('1.1. Основание для проведения оценки', font, fontBold),
      pw.Text(
        '• Номер и дата заключения договора об оценке №${data.reportNumber} от ${data.appraisalDate} г.',
        style: pw.TextStyle(font: font, fontSize: 12),
      ),
      pw.SizedBox(height: 14),
      _subTitle('1.2. Задание на оценку', font, fontBold),
      _kv('Объект оценки', data.propertyType, font, fontBold),
      _kv('Местонахождение объекта', data.address, font, fontBold),
      _kv('Оцениваемые права', 'Право собственности', font, fontBold),
      _kv('Цель оценки', 'Определение рыночной стоимости объекта оценки', font, fontBold),
      _kv('Назначение оценки', 'Для принятия управленческих решений', font, fontBold),
      _kv('Вид определяемой стоимости', 'Рыночная стоимость', font, fontBold),
      _kv('Вид оценки', 'Независимая', font, fontBold),
      _kv('Дата оценки', data.appraisalDate, font, fontBold),
      _kv('Дата осмотра', _or(data.inspectionDate, data.appraisalDate), font, fontBold),
      _kv('Дата составления отчета', data.appraisalDate, font, fontBold),
      _kv('Срок экспозиции', '1–3 месяца (типичный для сегмента)', font, fontBold),
      _kv('Предполагаемое использование результатов оценки', 'Для принятия управленческих решений Заказчиком', font, fontBold),
      _kv('Допущения и ограничения', 'В соответствии с разделом 1.4 настоящего отчета', font, fontBold),
      _kv('Исполнитель оценки', data.appraiserName, font, fontBold),
      pw.SizedBox(height: 14),
      _subTitle('1.3. Сведения об оценщике', font, fontBold),
      _kv('Оценщик', data.appraiserName, font, fontBold),
      if (data.appraiserIin.isNotEmpty) _kv('ИИН', data.appraiserIin, font, fontBold),
      _kv('Свидетельство', data.appraiserCertificate, font, fontBold),
      _kv('Палата оценщиков', data.appraiserPalata, font, fontBold),
      _kv('Образование', 'высшее профессиональное образование; профессиональная переподготовка в области оценочной деятельности', font, fontBold),
      _kv('Стаж работы в области оценки', 'свыше 5 лет', font, fontBold),
      _kv('Специализация', 'оценка недвижимого и движимого имущества', font, fontBold),
      if (data.appraiserInsurance.isNotEmpty)
        _kv('Страхование', data.appraiserInsurance, font, fontBold),
      _para('Оценщик является членом палаты оценщиков, регулярно повышает квалификацию в '
          'соответствии с требованиями законодательства Республики Казахстан об '
          'оценочной деятельности, гражданско-правовая ответственность оценщика '
          'застрахована в установленном порядке.', font),
      pw.SizedBox(height: 14),
      _subTitle('1.4. Допущения и ограничительные условия', font, fontBold),
      ..._assumptions(font, fontBold),
      pw.SizedBox(height: 14),
      _subTitle('1.5. Перечень документов', font, fontBold),
      ..._documents(font, fontBold),
      pw.SizedBox(height: 14),
      _subTitle('1.6. Основные термины и определения', font, fontBold),
      ..._terms(font),
    ];
  }

  static List<pw.Widget> _assumptions(pw.Font font, pw.Font fontBold) {
    return [
      pw.Text(
        'Исходя из нижеследующей трактовки и договоренности, настоящие условия подразумевают их '
        'полное и однозначное понимание заказчиком и оценщиком, а также факт того, что все '
        'положения, результаты переговоров и заявления, не оговоренные в тексте отчета, теряют '
        'силу. Настоящие условия не могут быть изменены или преобразованы иным образом, кроме '
        'как за подписью заказчика и оценщика. Заказчик должен и в дальнейшем соблюдать '
        'настоящие условия даже в случае, если право собственности на объект недвижимости '
        'полностью или частично перейдет к другому лицу.',
        style: pw.TextStyle(font: font, fontSize: 12, height: 1.5),
      ),
      pw.SizedBox(height: 10),
      _numItem('1', 'Приведенные в отчете анализ, мнения, заключения и полученные выводы являются нашими персональными, непредвзятыми, профессиональным анализом, мнениями и выводами.', font),
      _numItem('2', 'Нами осмотрен объект оценки, являющийся предметом данного отчета. Факты, изложенные в отчете, верны и соответствуют действительности.', font),
      _numItem('3', 'Настоящая оценка произведена в соответствии и на условиях, определенных Стандартами, утвержденными Приказом Министра финансов Республики Казахстан от 5 мая 2018 года № 519 (с изменениями и дополнениями от 23 августа 2022 г.).', font),
      _numItem('4', 'Оценщик не имеет ни настоящей, ни ожидаемой заинтересованности в оцениваемом имуществе и действует не предвзято и без предубеждения по отношению к участвующим сторонам.', font),
      _numItem('5', 'Вознаграждение оценщика не зависит от итоговой оценки стоимости, а также тех событий, которые могут наступить в результате использования заказчиком или третьими сторонами выводов и заключений, содержащихся в данном отчете.', font),
      _numItem('6', 'Предъявив выше сертификат оценки имущества в зависимости от выполнения исследующих условий, а также тех особых и ограничительных, которые были упомянуты оценщиком в настоящем отчете.', font),
      _numItem('7', 'Оценщик не принимает на себя ответственность по вопросам юридического характера, воздействующего на оцениваемое имущество или титул собственности на него, таким образом, оценщик не выносит никакого суждения относительно этого титула, который рассматривается как полноценный и свободный от каких-либо претензий, уступок или ограничений, помимо оговоренных выше.', font),
      _numItem('8', 'От оценщика не требуется давать свидетельство или появляться в суде вследствие проведенной оценки данной собственности, кроме как на основании отдельного Договора с Заказчиком и официального вызова суда.', font),
      _numItem('9', 'При проведении оценки Оценщик предполагает отсутствие каких-либо скрытых факторов, оказывающих влияние на собственность, порчу или сооружение.', font),
      _numItem('10', 'В своей работе Оценщик исходит из того, что представленная информация является точной и правдивой, и не проводил ее проверки. За основу в расчетах Оценщиками принимаются технические данные (площадь, объем, высота и т.д.), указанные в правоустанавливающих документах.', font),
      _numItem('11', 'Ни Заказчик, ни Оценщик не могут использовать Отчет иначе, чем это предусмотрено Договором об оценке.', font),
      _numItem('12', 'Отчет об оценке содержит профессиональное мнение оценщика относительно стоимости оцениваемого имущества и не является гарантией того, что это имущество будет реализовано по цене, указанной в Отчете.', font),
      _numItem('13', 'Мнение оценщика относительно рыночной стоимости объекта действительно только на дату оценки. Оценщик не принимает на себя никакой ответственности за изменение экономических, юридических и иных факторов, которые могут возникнуть после этой даты и повлиять на рыночную ситуацию, и, следовательно, на рыночную стоимость объекта.', font),
      _numItem('14', 'Публикация отчета об оценке целиком, частями или отдельных ссылок на отчет, данных, содержащихся в Отчете, имени и профессиональной принадлежности оценщика запрещается без его письменного согласия.', font),
      _numItem('15', 'Оценщик не проводил технической экспертизы объекта оценки и не несет ответственности за скрытые дефекты, которые невозможно обнаружить при визуальном осмотре либо выявить на основании предоставленной Заказчиком документации.', font),
      _numItem('16', 'Оценщик исходит из предположения об отсутствии экологических загрязнений объекта оценки, если иное не было установлено в ходе осмотра или не указано в предоставленных документах.', font),
      _numItem('17', 'Оценщик не проводил юридической экспертизы правоустанавливающих документов и не несет ответственности за юридические вопросы, связанные с титулом собственности на объект оценки.', font),
      _numItem('18', 'Сведения о площадях, этажности, инженерном обеспечении и иных технических характеристиках объекта приняты по данным, указанным в правоустанавливающих и технических документах, предоставленных Заказчиком, и не перепроверялись Оценщиком.', font),
      _numItem('19', 'Объект оценки считается свободным от каких-либо претензий и исков третьих лиц, за исключением случаев, прямо указанных в настоящем отчете.', font),
      _numItem('20', 'Оценка проведена при допущении, что объект оценки соответствует требованиям строительных, санитарных, противопожарных, экологических и иных норм и правил, действующих на территории Республики Казахстан.', font),
      _numItem('21', 'Оценщик не несет ответственности за достоверность информации, предоставленной Заказчиком, и исходит из того, что такая информация является полной, точной и достаточной для проведения оценки.', font),
      _numItem('22', 'Итоговая величина стоимости объекта оценки выражается в национальной валюте Республики Казахстан (тенге). Налог на добавленную стоимость (НДС) при определении стоимости не учитывается.', font),
      _numItem('23', 'Отчет об оценке действителен в течение шести месяцев с даты составления отчета, если иной срок не установлен договором об оценке.', font),
      _numItem('24', 'Использование отчета об оценке третьими лицами, не являющимися Заказчиком, допускается только с письменного согласия Оценщика и в соответствии с условиями договора об оценке.', font),
      pw.SizedBox(height: 10),
      _subTitle('Стандарты и сертификаты качества оценки', font, fontBold),
      _bullet('Факты, изложенные в Отчете об оценке, верны и соответствуют действительности;', font),
      _bullet('Содержащиеся в Отчете об оценке анализ, мнения и заключения принадлежат самим Оценщикам и действительны строго в пределах ограничительных условий и допущений, являющихся частью отчета;', font),
      _bullet('Ни Компания, ни Оценщики не имеют, ни настоящей, ни ожидаемой заинтересованности в оцениваемом имуществе и действуют непредвзято и без предубеждения по отношению к участвующим сторонам;', font),
      _bullet('Вознаграждение Оценщиков не зависит от итоговой величины стоимости, а также тех событий, которые могут наступить в результате использования Заказчиком или третьими сторонами выводов и заключений, содержащихся в Отчете;', font),
      _bullet('Оценка была проведена, а Отчет составлен в соответствии с Кодексом этики и Стандартами оценки, утвержденными в Республике Казахстан.', font),
    ];
  }

  static List<pw.Widget> _documents(pw.Font font, pw.Font fontBold) {
    return [
      _subTitle('1.5.1. Нормативные и правовые акты, используемые для оценки', font, fontBold),
      _numItem('1', 'Закон РК «Об оценочной деятельности в Республике Казахстан» от 10 января 2018 года №133-VI ЗРК.', font),
      _numItem('2', 'Приказ Министра финансов РК №519 от 05 мая 2018 года «Об утверждении стандартов оценки».', font),
      _numItem('3', '«Требования к форме и содержанию отчета об оценке», утвержденные приказом Министра финансов РК 3 мая 2018 года № 501 с изменениями и дополнениями в редакции приказа Заместителя Премьер-Министра - Министра финансов РК №772 от 01.08.2022.', font),
      _numItem('4', 'Приказ Заместителя Премьер-Министра финансов РК №876 от 23 августа 2022 года «Об утверждении стандартов оценки».', font),
      _numItem('5', 'Приказ Министра финансов РК №227 от 22 апреля 2024 года «О внесении изменений в приказ Министра финансов Республики Казахстан от 5 мая 2018 года № 519 «Об утверждении стандартов оценки».', font),
      _subTitle('1.5.2. Стандарты оценки и прочие нормативные акты', font, fontBold),
      _numItem('1', 'Приказ Министра финансов Республики Казахстан от 3 мая 2018 года № 501 «Требования к форме и содержанию отчета об оценке»; приказ заместителя Премьер-Министра - Министра финансов Республики Казахстан № 772 от 01.08.2022 г. «О внесении изменений».', font),
      _numItem('2', 'Приказ Министра финансов Республики Казахстан от 5 мая 2018 года № 519, зарегистрирован в Министерстве юстиции Республики Казахстан 31 мая 2018 года №16971; приказ Министра финансов Республики Казахстан № 227 от 22.04.2024 г. «О внесении изменений».', font),
      _numItem('3', 'Стандарт «Оценка стоимости движимого имущества» (утвержден приказом Министра финансов РК 5 мая 2018 года №519 Приложение 1, с изменениями в редакции приказа №876 от 23.08.2022 года и приказа №227 от 22.04.2024 года).', font),
      _numItem('4', 'Стандарт «Оценка стоимости недвижимого имущества» (утвержден приказом Министра финансов РК 5 мая 2018 года №519 Приложение 1, с изменениями в редакции приказа №876 от 23.08.2022 года и приказа №227 от 22.04.2024 года).', font),
      _numItem('5', 'Стандарт «Виды стоимости» (утвержден приказом Заместителя Премьер-Министра - Министра финансов РК №876 от 23.08.2022г).', font),
      _numItem('6', 'Стандарт «Оценка стоимости объектов интеллектуальной собственности и нематериальных активов» (утвержден приказом Министра финансов РК 5 мая 2018 года №519 Приложение 4, с изменениями в редакции приказа №227 от 22.04.2024 года).', font),
      _numItem('7', 'Международные Стандарты Оценки МСО 2025; Типовой кодекс деловой и профессиональной этики оценщиков, утвержденный приказом Министра финансов Республики Казахстан №487 от 26 апреля 2018 года.', font),
      _subTitle('1.5.3. Перечень документов, используемых оценщиком и устанавливающих количественные и качественные характеристики объекта оценки', font, fontBold),
      pw.Text(
        'Оценка была произведена на основании следующих правоустанавливающих, технических и иных документов (ксерокопий), предоставленных Заказчиком:',
        style: pw.TextStyle(font: font, fontSize: 12, height: 1.5),
      ),
      _bullet('Документ, удостоверяющий личность Заказчика;', font),
      _bullet('Правоустанавливающие документы на объект оценки (договор купли-продажи, акт приема-передачи);', font),
      _bullet('Технический паспорт / техническая документация на объект оценки;', font),
      _bullet('Справка о зарегистрированных правах (обременениях) на недвижимое имущество и его технических характеристиках.', font),
      _subTitle('1.5.4. Перечень данных, использованных при проведении оценки, с указанием источника их получения', font, fontBold),
      _bullet('Справочник оценщика / Под редакцией Шуленбаевой Г.Р., Яковлевой О.Н., Гузевой Е.Б. Алматы: ПО «Столичная палата профессиональных оценщиков»;', font),
      _bullet('Данные Агентства Республики Казахстан по статистике (www.stat.gov.kz);', font),
      _bullet('Данные сайтов: www.krisha.kz, www.olx.kz (анализ рынка предложений);', font),
      _bullet('Кодекс Этики оценщика;', font),
      _bullet('Справочная литература по оценке (Зимин А.И. «Оценка имущества», Иванова Е.Н. «Оценка стоимости недвижимости», Горемыкин В.А. «Экономика недвижимости» и др.).', font),
    ];
  }

  static List<pw.Widget> _terms(pw.Font font) {
    return [
      _term('оценка', ' - определение возможной рыночной или иной стоимости объекта оценки в соответствии с законодательством Республики Казахстан;', font),
      _term('подход к оценке', ' - способ определения возможной рыночной или иной стоимости объекта оценки с использованием одного или нескольких методов оценки;', font),
      _term('метод оценки', ' - совокупность действий юридического, финансово-экономического и организационно-технического характера, совершаемых при оценке;', font),
      _term('дата оценки', ' - день или период времени, на который определяется возможная рыночная или иная стоимость объекта оценки;', font),
      _term('стандарт оценки', ' - нормативный правовой акт, разрабатываемый и утверждаемый уполномоченным органом в области оценочной деятельности, в котором устанавливаются единые для субъектов оценочной деятельности требования к определению рыночной или иной стоимости объекта оценки;', font),
      _term('отчет об оценке', ' - письменный документ, составленный в соответствии с законодательством Республики Казахстан об оценочной деятельности по результатам проведенной оценки;', font),
      _term('оценщик', ' - физическое лицо, осуществляющее профессиональную деятельность на основании свидетельства о присвоении квалификации «оценщик», выданного палатой оценщиков, и являющееся членом одной из палат оценщиков;', font),
      _term('свидетельство о присвоении квалификации «оценщик»', ' - документ, подтверждающий соответствие лица требованиям к владению специальными теоретическими знаниями, практическими умениями, навыками и опытом работы;', font),
      _term('палата оценщиков', ' – саморегулируемая организация в сфере профессиональной деятельности, созданная в целях осуществления контроля качества оценочной деятельности ее членов, защиты прав и законных интересов оценщиков;', font),
      _term('рыночная стоимость', ' - расчетная денежная сумма, за которую состоялся бы обмен актива на дату оценки между заинтересованным лицом и продавцом в результате коммерческой сделки после проведения надлежащего маркетинга, при которой каждая из сторон действовала бы будучи хорошо осведомленной, расчетливо и без принуждения;', font),
      _term('иная стоимость', ' - иная, кроме рыночной, стоимость объекта оценки, виды которой устанавливаются стандартами оценки;', font),
      _term('заказчик', ' - физическое и (или) юридическое лицо, заключившее договор на проведение оценки;', font),
      _term('третьи лица', ' - лица, не входящие в число оценщиков, экспертов и заказчиков, имеющие определенное отношение к объекту оценки, оценочной деятельности;', font),
      _term('международные стандарты оценки', ' - стандарты оценки, принятые Международным советом по стандартам оценки;', font),
      _term('недвижимое имущество (недвижимость)', ' – земельные участки, здания, сооружения и иное имущество, прочно связанное с землей, то есть объекты, перемещение которых без несоразмерного ущерба их назначению невозможно;', font),
      _term('сопоставимые данные', ' – данные, используемые в оценочном анализе для получения расчетных величин стоимости, получаемые на основе анализа данных аналогов, оцениваемому объекту: цены продаж, арендная плата, доходы и расходы, ставки капитализации и дисконтирования, полученные из рыночных данных и другие;', font),
      _term('элементы сравнения', ' – конкретные характеристики объектов имущества и сделок, которые приводят к вариациям в ценах, уплачиваемых за недвижимость. Элементы сравнения включают виды передаваемых имущественных прав, условия продажи, условия рынка, физические и экономические характеристики, использование, компоненты продажи и другие.', font),
      _term('затратный подход', ' – совокупность методов оценки стоимости, основанных на определении затрат, необходимых для воспроизводства либо замещения объекта оценки с учетом его износа и устаревания;', font),
      _term('доходный подход', ' – совокупность методов оценки стоимости объекта оценки, основанных на определении ожидаемых доходов от использования объекта оценки;', font),
      _term('сравнительный подход', ' – совокупность методов оценки стоимости объекта оценки, основанных на сравнении объекта оценки с объектами-аналогами, в отношении которых имеется информация о ценах сделок или предложений;', font),
      _term('объект-аналог', ' – объект, сходный по основным экономическим, материальным, техническим и другим характеристикам с объектом оценки, цена которого известна из сделки, состоявшейся при сходных условиях, либо из публичного предложения;', font),
      _term('ставка капитализации', ' – коэффициент, связывающий чистый операционный доход, приносимый объектом, с его рыночной стоимостью; определяется на основе анализа рыночных данных о соотношениях дохода и цены для аналогичных объектов;', font),
      _term('чистый операционный доход', ' – потенциальный валовой доход за вычетом потерь от недозагрузки, недосбора арендной платы и операционных расходов;', font),
      _term('физический износ', ' – потеря стоимости объекта вследствие ухудшения его физического состояния в процессе эксплуатации и воздействия природных факторов;', font),
      _term('функциональное устаревание', ' – потеря стоимости объекта вследствие несоответствия его объемно-планировочных, конструктивных или инженерных решений современным требованиям рынка;', font),
      _term('внешнее (экономическое) устаревание', ' – потеря стоимости объекта, вызванная изменением внешних по отношению к объекту факторов: конъюнктуры рынка, экономической ситуации, административных ограничений;', font),
      _term('ликвидационная стоимость', ' – расчетная денежная сумма, за которую актив мог бы быть обменян на дату оценки между заинтересованным покупателем и продавцом в результате вынужденной продажи;', font),
      _term('инвестиционная стоимость', ' – стоимость актива для конкретного собственника или потенциального инвестора с учетом его индивидуальных инвестиционных требований и целей;', font),
      _term('рыночная стоимость', ' – расчетная денежная сумма, за которую имущество должно переходить из рук в руки на дату оценки в результате коммерческой сделки между добровольным покупателем и добровольным продавцом после надлежащего маркетинга, при этом полагается, что каждая из сторон действовала компетентно, расчетливо и без принуждения;', font),
      _term('срок экспозиции', ' – расчетное время, в течение которого объект оценки может находиться на рынке до момента его продажи по рыночной стоимости;', font),
      _term('ликвидность', ' – способность имущества быть быстро проданным на рынке по цене, адекватной рыночной стоимости, в условиях конкуренции среди продавцов и покупателей;', font),
      _term('объект оценки', ' – имущество, права на имущество, работы и услуги, информация, а также иные объекты гражданских прав, в отношении которых законодательством Республики Казахстан установлена возможность участия в гражданском обороте и в отношении которых производится оценка;', font),
      _term('оценщик', ' – физическое лицо, являющееся членом палаты оценщиков и осуществляющее оценочную деятельность в соответствии с законодательством Республики Казахстан об оценочной деятельности;', font),
      _term('кадастровая стоимость', ' – стоимость объекта недвижимости, определяемая в порядке, установленном законодательством Республики Казахстан, для целей налогообложения и иных предусмотренных законодательством целей;', font),
    ];
  }

  static List<pw.Widget> _buildObjectDescription(ReportData data, pw.Font font, pw.Font fontBold) {
    if (_isCar(data.propertyType)) return _buildCarDescription(data, font, fontBold);
    return [
      _subTitle('2.1. Дата осмотра объекта оценки', font, fontBold),
      _kv('Дата осмотра', _or(data.inspectionDate, data.appraisalDate), font, fontBold),
      pw.SizedBox(height: 14),
      _subTitle('2.2. Состав, основные характеристики, назначение, текущее использование и состояние объекта оценки', font, fontBold),
      pw.Text(
        '${_or(data.propertyType, 'Объект недвижимости')}, общей площадью ${_fmtArea(data.area)} кв.м., '
        'расположенный по адресу: ${data.address}.',
        style: pw.TextStyle(font: font, fontSize: 12, height: 1.5),
      ),
      pw.SizedBox(height: 12),
      _subTitle('Таблица 1. Техническая характеристика объекта оценки', font, fontBold),
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(font: fontBold, fontSize: 10),
        cellStyle: pw.TextStyle(font: font, fontSize: 12),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
        cellAlignment: pw.Alignment.centerLeft,
        cellPadding: const pw.EdgeInsets.all(4),
        headers: ['Характеристика', 'Значение'],
        data: [
          ['Тип объекта', _or(data.propertyType, '—')],
          ['Адрес', _or(data.address, '—')],
          ['Общая площадь, кв.м.', _fmtArea(data.area)],
          if (data.livingArea.isNotEmpty) ['Жилая площадь, кв.м.', data.livingArea],
          if (data.kitchenArea.isNotEmpty) ['Площадь кухни, кв.м.', data.kitchenArea],
          if (data.rooms > 0) ['Количество комнат', '${data.rooms}'],
          if (data.floor > 0) ['Этаж / этажность', '${data.floor} / ${data.totalFloors}'],
          if (data.yearBuilt > 0) ['Год постройки', '${data.yearBuilt}'],
          if (data.buildingType.isNotEmpty) ['Тип здания', data.buildingType],
          if (data.wallMaterial.isNotEmpty) ['Материал стен', data.wallMaterial],
          if (data.buildingCondition.isNotEmpty) ['Техническое состояние здания', data.buildingCondition],
          if (data.communications.isNotEmpty) ['Коммуникации', data.communications],
          if (data.bathroom.isNotEmpty) ['Санузел', data.bathroom],
          if (data.balcony.isNotEmpty) ['Балкон / лоджия', data.balcony],
          if (data.renovationYear.isNotEmpty) ['Год ремонта', data.renovationYear],
          if (data.layout.isNotEmpty) ['Планировка', data.layout],
          ['Состояние объекта', _or(data.condition, '—')],
          if (data.cadastralNumber.isNotEmpty) ['Кадастровый номер', data.cadastralNumber],
          if (data.purpose.isNotEmpty) ['Назначение', data.purpose],
        ],
      ),
      pw.SizedBox(height: 14),
      _subTitle('Таблица 2. Характеристика земельного участка', font, fontBold),
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(font: fontBold, fontSize: 10),
        cellStyle: pw.TextStyle(font: font, fontSize: 12),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
        cellAlignment: pw.Alignment.centerLeft,
        cellPadding: const pw.EdgeInsets.all(4),
        headers: ['Характеристика', 'Значение'],
        data: [
          ['Целевое назначение', _or(data.purpose, 'соответствует фактическому использованию')],
          ['Форма и рельеф', 'правильной формы, рельеф спокойный'],
          ['Инженерное обеспечение', 'электроснабжение, водоснабжение, канализация'],
          ['Подъездные пути', 'асфальтированные, в хорошем состоянии'],
          ['Благоустройство', 'удовлетворительное'],
        ],
      ),
      pw.SizedBox(height: 14),
      _subTitle('2.3. Описание местоположения объекта оценки', font, fontBold),
      _kv('Населенный пункт', 'г. Алматы', font, fontBold),
      _kv('Район', data.address.contains('Алмалин') ? 'Алмалинский район' : 'по адресу', font, fontBold),
      _kv('Транспортная доступность', 'хорошая; остановки общественного транспорта в пешей доступности', font, fontBold),
      _kv('Социальная инфраструктура', 'развитая (школы, медицинские организации, торговля)', font, fontBold),
      _kv('Экологическая обстановка', 'удовлетворительная', font, fontBold),
      pw.SizedBox(height: 8),
      _para('Местоположение объекта оценивается как благоприятное для эксплуатации по назначению. Подробные выводы по осмотру и описанию района отражены в акте осмотра (Приложение №1).', font),
    ];
  }

  /// Абзац основного текста (12pt, 1.5).
  static pw.Widget _para(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 12, height: 1.5)),
    );
  }

  /// Подзаголовок 3-го уровня (2.3.1, 2.3.2, ...).
  static pw.Widget _miniTitle(String title, pw.Font font, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 6, bottom: 6),
      child: pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 12)),
    );
  }

  /// 2.3. Анализ рынка объекта оценки — развёрнутый (недвижимость).
  static List<pw.Widget> _buildMarketAnalysis(ReportData data, pw.Font font, pw.Font fontBold) {
    if (_isCar(data.propertyType)) return _buildCarMarketAnalysis(data, font, fontBold);
    final range = 'от ${data.formattedPriceRangeLow} до ${data.formattedPriceRangeHigh} тенге';
    return [
      _miniTitle('2.3.1. Макроэкономическая ситуация в Республике Казахстан', font, fontBold),
      _para('Экономика Республики Казахстан в 2025–2026 годах характеризуется умеренным экономическим ростом, '
          'поддерживаемым добывающим сектором, расширением обрабатывающей промышленности, развитием '
          'транспортно-логистической инфраструктуры и реализацией государственных программ поддержки '
          'предпринимательства и жилищного строительства. По данным Национального банка Республики Казахстан, '
          'базовая ставка сохраняется на уровне, обеспечивающем сдерживание инфляционного давления при '
          'сохранении доступности кредитных ресурсов для конечных заемщиков.', font),
      _para('Потребительская инфляция в рассматриваемый период находилась в пределах целевого коридора '
          'Национального банка. Стабильность национальной валюты и умеренная динамика доходов населения '
          'формируют предпосылки для поддержания покупательской способности на рынке недвижимости. '
          'Сберегательная активность населения остается высокой, что традиционно направляет часть '
          'свободных средств в сегмент недвижимости как инструмент сохранения капитала.', font),
      _para('Продолжается реализация жилищных программ, направленных на повышение доступности жилья: '
          'субсидирование ипотечных займов, строительство арендного жилья, развитие рынка ипотечного '
          'кредитования. Указанные меры оказывают поддерживающее влияние на спрос, прежде всего в '
          'сегменте доступного жилья, и стимулируют активность на первичном рынке.', font),
      _para('Миграционные процессы и продолжающаяся урбанизация поддерживают спрос на недвижимость в '
          'крупнейших городах страны — Алматы, Астана, Шымкент, а также в областных центрах. Приток '
          'населения в города формирует устойчивый спрос как на жилую, так и на коммерческую недвижимость, '
          'однако темпы ввода нового жилья в отдельных сегментах превышают темпы роста спроса, что '
          'оказывает сдерживающее влияние на ценовую динамику.', font),
      _miniTitle('2.3.2. Обзор рынка недвижимости Республики Казахстан и региона', font, fontBold),
      _para('Рынок недвижимости Республики Казахстан по состоянию на дату оценки характеризуется как '
          'умеренно активный с признаками стабилизации цен после периода коррекции. Объем сделок с '
          'жилой недвижимостью сохраняется на устойчивом уровне; наибольшая активность отмечается в '
          'сегменте вторичного жилья, пользующегося спросом у покупателей, ориентированных на '
          'немедленное заселение и наличие развитой инфраструктуры.', font),
      _para('Предложение на рынке формируется как за счет вновь вводимых объектов (первичный рынок), так и '
          'за счет объектов, ранее находившихся в эксплуатации (вторичный рынок). На первичном рынке '
          'застройщики активно используют инструменты рассрочки платежа и совместного финансирования '
          'строительства, что расширяет доступность жилья. Вместе с тем, качество реализации и сроки '
          'сдачи объектов варьируются, что учитывается покупателями при формировании ценовых ожиданий.', font),
      _para('Ценовая ситуация в рассматриваемом регионе определяется соотношением спроса и предложения в '
          'конкретных локациях. Наблюдается дифференциация цен между районами с развитой инфраструктурой '
          'и территориями нового освоения. Цены предложения на сопоставимые объекты формируются с учетом '
          'местоположения, технического состояния, этажности, материалов стен и иных потребительских '
          'характеристик.', font),
      _para('Арендный сегмент рынка остается активным: доходность от сдачи в аренду жилой недвижимости в '
          'крупных городах обеспечивает привлекательность инвестиций в данный сегмент. Соотношение цены '
          'и арендной ставки (валовой рентный мультипликатор) находится в диапазоне, характерном для '
          'стабильных рынков, что свидетельствует об отсутствии выраженных ценовых перекосов.', font),
      _miniTitle('2.3.3. Анализ сегмента объекта оценки', font, fontBold),
      _para('Объект оценки относится к сегменту «${_or(data.propertyType, 'недвижимость')}». Данный сегмент '
          'характеризуется устойчивым спросом со стороны конечных пользователей, ориентированных на '
          '${_or(data.purpose, 'использование объекта по назначению')}. Ликвидность объектов данного сегмента '
          'оценивается как средняя: типичный срок экспозиции составляет от одного до трех месяцев.', font),
      _para('Ценовой диапазон предложений по объектам, сопоставимым с объектом оценки, по данным '
          'анализируемых объявлений составляет ${range}. Разброс цен обусловлен различиями в '
          'местоположении, площади, техническом состоянии и условиях продажи. Объект оценки по своим '
          'характеристикам занимает положение, соответствующее средним рыночным параметрам сегмента.', font),
      _para('Конкуренция в сегменте оценивается как умеренная: на каждое актуальное предложение приходится '
          'достаточное количество потенциальных покупателей, что обеспечивает реализацию объектов по '
          'ценам, близким к заявленным, при условии адекватного ценообразования. Дисконт между ценой '
          'предложения и фактической ценой сделки в текущих рыночных условиях составляет, по оценкам '
          'участников рынка, от 5 до 10 процентов.', font),
      _miniTitle('2.3.4. Факторы, влияющие на стоимость объекта', font, fontBold),
      _bullet('местоположение объекта и транспортная доступность;', font),
      _bullet('техническое состояние здания и год постройки;', font),
      _bullet('общая и жилая площадь, планировочные решения;', font),
      _bullet('этаж расположения и этажность здания, наличие лифта;', font),
      _bullet('развитость социальной и коммерческой инфраструктуры района;', font),
      _bullet('состояние инженерных коммуникаций и их соответствие нормативным требованиям;', font),
      _bullet('юридическая чистота объекта и отсутствие обременений;', font),
      _bullet('общая экономическая конъюнктура и уровень ставок ипотечного кредитования;', font),
      _bullet('перспективы развития района и градостроительные планы.', font),
      _miniTitle('2.3.5. Динамика цен и срок экспозиции', font, fontBold),
      _para('За последние двенадцать месяцев, предшествующих дате оценки, цены в рассматриваемом сегменте '
          'демонстрировали умеренную динамику без резких колебаний. Отмечается сезонность спроса: '
          'активизация наблюдается в весенне-осенний период, относительное затишье — в летние месяцы и '
          'в период новогодних праздников.', font),
      _para('Срок экспозиции типового объекта сегмента составляет от 30 до 90 дней. Объекты с '
          'конкурентной ценой и хорошим техническим состоянием реализуются в нижней границе указанного '
          'диапазона. Длительность экспозиции свыше трех месяцев, как правило, свидетельствует о '
          'завышенной цене предложения либо о наличии у объекта характеристик, ограничивающих спрос.', font),
      _miniTitle('2.3.6. Анализ цен предложения в сегменте', font, fontBold),
      _para('Для анализа ценового диапазона в сегменте объекта оценки Оценщиком '
          'сформирована выборка предложений по сопоставимым объектам, размещенных на '
          'открытых площадках объявлений. Удельные показатели стоимости по сегменту '
          'характеризуются следующими значениями:', font),
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(font: fontBold, fontSize: 10),
        cellStyle: pw.TextStyle(font: font, fontSize: 12),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
        cellAlignment: pw.Alignment.centerLeft,
        cellPadding: const pw.EdgeInsets.all(4),
        headers: ['Показатель', 'Минимум', 'Среднее', 'Максимум'],
        data: [
          ['Удельная цена, ₸/м²', 'по выборке', 'по выборке', 'по выборке'],
          ['Цена предложения, ₸', 'по выборке', 'по выборке', 'по выборке'],
          ['Срок экспозиции, мес.', '1', '1–2', '3'],
        ],
      ),
      pw.SizedBox(height: 8),
      _miniTitle('2.3.7. Анализ спроса и предложения', font, fontBold),
      _para('Спрос в сегменте объекта оценки формируется преимущественно конечными '
          'пользователями — физическими лицами, приобретающими объект для проживания '
          '(использования по назначению), а также инвесторами, рассматривающими '
          'приобретение объекта для последующей сдачи в аренду. Соотношение спроса и '
          'предложения в сегменте оценивается как сбалансированное с незначительным '
          'преобладанием предложения, что характерно для стабильных рынков.', font),
      _para('Предложение формируется собственниками объектов, реализующих имущество в '
          'связи с переездом, приобретением нового жилья либо изменением инвестиционной '
          'стратегии, а также профессиональными участниками рынка. Качество предложения '
          'неоднородно: значительная часть объектов требует ремонта либо представлена в '
          'состоянии «под ключ», что определяет широкий диапазон цен предложения.', font),
      _para('Покупательская активность подвержена сезонным колебаниям: традиционные пики '
          'приходятся на весенний и осенний периоды. При этом в рассматриваемом сегменте '
          'спрос отличается относительной стабильностью в течение года, что обусловлено '
          'потребительским характером приобретений. Средний срок экспозиции объектов с '
          'адекватной ценой составляет от одного до двух месяцев.', font),
      _miniTitle('2.3.8. Прогноз развития сегмента', font, fontBold),
      _para('В среднесрочной перспективе (12–24 месяца) ожидается сохранение текущего '
          'уровня цен с умеренной положительной динамикой в пределах уровня инфляции. '
          'Сдерживающее влияние на цены оказывают высокие объемы ввода нового жилья и '
          'конкуренция со стороны первичного рынка, стимулирующее — рост доходов '
          'населения и доступность ипотечных программ.', font),
      _para('Ключевыми рисками для сегмента являются: изменение макроэкономической '
          'ситуации, волатильность обменного курса, изменение условий ипотечного '
          'кредитования, а также административные меры регулирования рынка. Указанные '
          'риски учтены Оценщиком при определении итоговой величины стоимости и '
          'интерпретации рыночных данных на дату оценки.', font),
      _miniTitle('2.3.9. Выводы по анализу рынка', font, fontBold),
      _para('Проведенный анализ свидетельствует о достаточной информационной обеспеченности рынка '
          'сегмента объекта оценки: имеется представительная выборка предложений по сопоставимым '
          'объектам, что позволяет применить сравнительный подход к оценке. Рыночная ситуация '
          'характеризуется как стабильная, без признаков выраженной волатильности.', font),
      _para('На основании анализа рынка диапазон наиболее вероятной рыночной стоимости объекта оценки '
          'определен в пределах ${range}. Итоговая величина стоимости устанавливается в рамках '
          'указанного диапазона с учетом индивидуальных характеристик объекта оценки, выявленных в '
          'ходе осмотра и анализа.', font),
    ];
  }

  /// 2.3. Анализ рынка для движимого имущества (авто/мото/спецтехника).
  static List<pw.Widget> _buildCarMarketAnalysis(ReportData data, pw.Font font, pw.Font fontBold) {
    final s = data.vehicleSpecs;
    String v(String k) => s[k]?.trim().isNotEmpty == true ? s[k]!.trim() : '—';
    final range = 'от ${data.formattedPriceRangeLow} до ${data.formattedPriceRangeHigh} тенге';
    return [
      _miniTitle('2.3.1. Обзор рынка автомобилей Республики Казахстан', font, fontBold),
      _para('Рынок автомобилей Республики Казахстан характеризуется устойчивым спросом, формируемым '
          'как за счет новых автомобилей (включая отечественную сборку), так и за счет развитого '
          'сегмента автомобилей с пробегом. Доля импортируемых автомобилей остается значительной, '
          'при этом государственная политика направлена на развитие локального производства и '
          'стимулирование обновления парка.', font),
      _para('Ценообразование на рынке автомобилей с пробегом определяется совокупностью факторов: '
          'возраст и пробег транспортного средства, техническое состояние, комплектация, история '
          'обслуживания, количество владельцев, а также рыночная конъюнктура по конкретной марке и '
          'модели. Ликвидность автомобилей массовых марок существенно выше ликвидности редких и '
          'премиальных моделей.', font),
      _miniTitle('2.3.2. Анализ сегмента объекта оценки', font, fontBold),
      _para('Объект оценки относится к сегменту «${v('make')} ${v('model')}» ${v('year')} года выпуска. '
          'Данный сегмент характеризуется ${_or(data.condition, 'умеренным')} уровнем спроса; типичный '
          'срок экспозиции автомобилей данной категории составляет от 2 до 6 недель. Ценовой диапазон '
          'предложений по сопоставимым автомобилям составляет ${range}.', font),
      _para('При анализе рынка учитывались объявления о продаже аналогичных автомобилей, размещенные '
          'на специализированных площадках (kolesa.kz, olx.kz), с корректировкой на пробег, состояние, '
          'комплектацию и регион продажи.', font),
      _miniTitle('2.3.3. Факторы, влияющие на стоимость автомобиля', font, fontBold),
      _bullet('марка, модель и год выпуска;', font),
      _bullet('пробег и условия эксплуатации;', font),
      _bullet('техническое состояние кузова, салона и агрегатов;', font),
      _bullet('комплектация и дополнительное оборудование;', font),
      _bullet('количество владельцев и история обслуживания;', font),
      _bullet('юридическая чистота (отсутствие залогов, ограничений);', font),
      _bullet('рыночная конъюнктура по конкретной модели;', font),
      _bullet('сезонность спроса на вторичном рынке.', font),
      _miniTitle('2.3.4. Выводы по анализу рынка', font, fontBold),
      _para('Информационная обеспеченность рынка сегмента достаточна для применения сравнительного '
          'подхода. Наиболее вероятная рыночная стоимость объекта оценки находится в диапазоне '
          '${range}, итоговая величина устанавливается с учетом индивидуальных характеристик '
          'автомобиля.', font),
    ];
  }

  static List<pw.Widget> _buildCarDescription(ReportData data, pw.Font font, pw.Font fontBold) {
    final s = data.vehicleSpecs;
    String v(String k) => s[k]?.trim().isNotEmpty == true ? s[k]!.trim() : '—';
    return [
      _subTitle('2.1. Дата осмотра объекта оценки', font, fontBold),
      _kv('Дата осмотра', _or(data.inspectionDate, data.appraisalDate), font, fontBold),
      pw.SizedBox(height: 14),
      _subTitle('2.2. Состав, основные характеристики, назначение, текущее использование и состояние объекта оценки', font, fontBold),
      pw.Text(
        'Автомобиль ${v('make')} ${v('model')}, ${v('year')} года выпуска, '
        'идентификационный номер (VIN) ${v('vin')}.',
        style: pw.TextStyle(font: font, fontSize: 12, height: 1.5),
      ),
      pw.SizedBox(height: 12),
      _subTitle('Таблица 1. Техническая характеристика объекта оценки', font, fontBold),
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(font: fontBold, fontSize: 10),
        cellStyle: pw.TextStyle(font: font, fontSize: 12),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
        cellAlignment: pw.Alignment.centerLeft,
        cellPadding: const pw.EdgeInsets.all(4),
        headers: ['Характеристика', 'Значение'],
        data: [
          ['Марка', v('make')],
          ['Модель', v('model')],
          ['Год выпуска', v('year')],
          ['VIN', v('vin')],
          ['Государственный номер', v('plate')],
          ['Пробег, км', v('mileage')],
          ['Кузов', v('body')],
          ['Двигатель', v('engine')],
          ['Коробка передач', v('transmission')],
          ['Привод', v('drive')],
          ['Цвет', v('color')],
          ['Состояние', _or(data.condition, '—')],
        ],
      ),
      pw.SizedBox(height: 14),
      _subTitle('2.3. Описание объекта оценки', font, fontBold),
      pw.Text(
        'Транспортное средство находится в ${_or(data.condition, 'удовлетворительном')} '
        'техническом состоянии. Сведения о пробеге и комплектации указаны на основании '
        'предоставленной документации и визуального осмотра.',
        style: pw.TextStyle(font: font, fontSize: 12, height: 1.5),
      ),
    ];
  }

  static List<pw.Widget> _buildCalculation(ReportData data, pw.Font font, pw.Font fontBold) {
    return [
      _subTitle('3.1. Методология оценки и обоснование выбора подходов', font, fontBold),
      _para('Установление рыночной или иной стоимости производится путем применения методов '
          'оценки, сгруппированных в доходный, затратный и сравнительный подходы. Выбор '
          'подходов и методов осуществляется Оценщиком с учетом специфики объекта оценки, '
          'цели оценки, вида определяемой стоимости, полноты и достоверности исходной '
          'информации, а также требований стандартов оценки.', font),
      _miniTitle('Доходный подход', font, fontBold),
      _numItem('1', 'Доходный подход применяется при оценке объектов недвижимости, которые покупаются и продаются в связи с их способностью приносить доходы.', font),
      _bullet('метод дисконтирования денежных потоков (метод дисконтированного наличного потока) – определение стоимости исходя из условий изменения и неравномерного поступления денежных потоков в зависимости от степени риска, связанного с использованием объекта;', font),
      _bullet('метод прямой капитализации дохода – определение стоимости объекта путем деления соответствующего рынку годового чистого операционного дохода на коэффициент капитализации, полученный на основе анализа рыночных данных о соотношениях дохода к стоимости активов, аналогичных оцениваемому;', font),
      _para('При методе прямой капитализации стоимость определяется по формуле: '
          'С = ЧОД / R, где С — стоимость объекта, ЧОД — годовой чистый операционный доход, '
          'R — ставка капитализации. При методе дисконтирования денежных потоков стоимость '
          'определяется как сумма дисконтированных будущих денежных потоков: '
          'С = Σ CFt / (1 + r)ᵗ, где CFt — денежный поток периода t, r — ставка '
          'дисконтирования, отражающая риски, связанные с объектом.', font),
      _miniTitle('Затратный подход', font, fontBold),
      _numItem('2', 'Затратный подход применяется для проведения оценки недвижимого имущества, рынок купли-продажи или аренды которого является ограниченным.', font),
      _bullet('Применение затратного подхода состоит в определении остаточной стоимости воспроизводства (замещения) объекта оценки, которая состоит из остаточной стоимости воспроизводства (замещения) земельных улучшений и рыночной стоимости земельного участка;', font),
      _bullet('Стоимость полного воспроизводства, как правило, определяется при оценке объекта, замещение которого невозможно, а также в случае соответствия существующего использования объекта оценки его наиболее эффективному использованию;', font),
      _para('В общем виде стоимость объекта при затратном подходе определяется по формуле: '
          'СЗ = СВ(З) − И + СЗУ, где СЗ — стоимость объекта при затратном подходе, '
          'СВ(З) — стоимость воспроизводства (замещения) улучшений, И — совокупный износ '
          '(физический, функциональный, внешний), СЗУ — рыночная стоимость земельного '
          'участка. Затратный подход отражает затраты на создание объекта, но не учитывает '
          'в полной мере рыночную конъюнктуру и доходность объекта.', font),
      _miniTitle('Сравнительный подход', font, fontBold),
      _numItem('3', 'Сравнительный подход применяется для определения рыночной стоимости объекта оценки путем сравнения с объектами-аналогами, по которым имеется достаточная и достоверная информация о ценах сделок или предложений.', font),
      _bullet('Основой применения сравнительного подхода является тот факт, что стоимость объекта оценки напрямую связана с ценой продажи аналогичных объектов;', font),
      _bullet('При этом вносятся корректировки на различия между объектом оценки и аналогами (дата предложения, местоположение, площадь, состояние, этаж и другие характеристики);', font),
      _para('Для ${data.propertyType.toLowerCase()} наиболее объективные результаты даёт '
          'сравнительный подход, который в силу хорошо развитой системы информационного '
          'обеспечения рынка применяется как основной. Затратный подход применяется как '
          'дополнительный, доходный подход в данном случае не применяется ввиду отсутствия '
          'достоверной информации о доходах, приносимых объектом.', font),
      _para('Согласование результатов, полученных различными подходами, выполняется методом '
          'анализа иерархий с присвоением весовых коэффициентов каждому подходу исходя из '
          'надежности исходной информации, адекватности метода специфике объекта и '
          'соответствия результатов рыночным реалиям. Итоговая величина стоимости '
          'определяется как средневзвешенное значение результатов подходов.', font),
      _miniTitle('Затратный подход (справочный расчет)', font, fontBold),
      _para('В рамках затратного подхода стоимость объекта определяется как сумма затрат '
          'на воспроизводство (замещение) улучшений и стоимости прав на земельный '
          'участок с учетом накопленного износа:', font),
      _para('Сз = Сзв × (1 − И) + Сзу, где Сзв — затраты на воспроизводство (замещение) '
          'улучшений, И — накопленный износ (физический, функциональный, внешний), '
          'Сзу — стоимость прав на земельный участок.', font),
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(font: fontBold, fontSize: 10),
        cellStyle: pw.TextStyle(font: font, fontSize: 12),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
        cellAlignment: pw.Alignment.centerLeft,
        cellPadding: const pw.EdgeInsets.all(4),
        headers: ['Показатель', 'Значение'],
        data: [
          ['Затраты на воспроизводство (замещение), ₸', 'справочно'],
          ['Накопленный износ, %', 'справочно'],
          ['Стоимость прав на земельный участок, ₸', 'справочно'],
          ['Стоимость по затратному подходу, ₸', 'справочно'],
        ],
      ),
      pw.SizedBox(height: 8),
      _para('Расчет стоимости по затратному подходу носит справочный характер: результаты '
          'подхода используются как контрольный ориентир при согласовании итоговой '
          'величины стоимости, поскольку затратный подход не в полной мере отражает '
          'рыночную конъюнктуру и потребительские предпочтения в данном сегменте.', font),
      pw.SizedBox(height: 14),
      _subTitle('3.2. Описание процесса оценки и расчеты, выполненные с использованием выбранных подходов/методов', font, fontBold),
      _numItem('1', 'Предоставление заказчиком правоустанавливающих и идентификационных документов на объект оценки. На данном этапе формируется информационная база для проведения оценки: идентифицируются характеристики объекта, его правовой статус и физические параметры. Заказчиком предоставляются документы, удостоверяющие личность, правоустанавливающие документы на объект, техническая документация, сведения об отсутствии (наличии) обременений.', font),
      _numItem('2', 'Определение задания (идентификация имущества, имущественных прав, базы оценки, даты оценки). Уточняются цель оценки, вид определяемой стоимости, предполагаемое использование результатов оценки и связанные с этим ограничения. Результаты данного этапа фиксируются в задании на оценку (раздел 1.2 настоящего отчета).', font),
      _numItem('3', 'Предварительный анализ, отбор и сбор данных. Осуществляется сбор информации о рынке объекта оценки, подбор объектов-аналогов, анализ макроэкономических показателей и факторов, влияющих на стоимость. Проверяется достоверность собранной информации, источники данных документируются для последующего отражения в отчете.', font),
      _numItem('4', 'Выбор подходов и методов оценки, выполнение расчетов. На основании анализа полноты и достоверности информации выбираются подходы и методы, выполняются расчеты стоимости в рамках каждого примененного подхода. Обоснование выбора подходов приведено в разделе 3.1 настоящего отчета.', font),
      _numItem('5', 'Составление отчета об оценке. Результаты оценки оформляются в виде отчета, соответствующего требованиям законодательства Республики Казахстан об оценочной деятельности. Отчет подписывается Оценщиком, утверждается руководителем организации и передается Заказчиком в порядке, установленном договором об оценке.', font),
      pw.SizedBox(height: 14),
      _para('Для определения стоимости методом сравнительного анализа используется следующая '
          'последовательность: исследование рынка, сбор информации о сделках или предложениях '
          'по объектам-аналогам, проверка надежности информации, выбор не менее трех типичных '
          'аналогов, внесение корректировок по элементам сравнения, расчет скорректированных цен.', font),
      _para('Отбор объектов-аналогов производился по критериям сопоставимости: тип объекта, '
          'местоположение, площадь, техническое состояние, условия продажи. По каждому '
          'аналогу проанализирована достоверность информации об источнике предложения; '
          'использованы данные публичных объявлений на специализированных интернет-площадках.', font),
      _para('Корректировки вносились по элементам сравнения в процентном выражении. Величина '
          'каждой корректировки определялась экспертным путем на основе анализа рыночных '
          'данных о влиянии соответствующего фактора на стоимость аналогичных объектов. '
          'Итоговая скорректированная цена каждого аналога рассчитывалась последовательным '
          'применением корректировок к цене предложения.', font),
      if (data.comparables.isNotEmpty) _buildComparablesTable(data, font, fontBold),
      pw.SizedBox(height: 14),
      _subTitle('3.3. Согласование результатов оценки', font, fontBold),
      _para('Согласование результатов, полученных различными подходами, выполняется методом '
          'анализа иерархий с присвоением весовых коэффициентов каждому подходу исходя из '
          'надежности исходной информации, адекватности метода специфике объекта и '
          'соответствия результатов рыночным реалиям. Итоговая величина стоимости '
          'определяется как средневзвешенное значение результатов подходов.', font),
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(font: fontBold, fontSize: 10),
        cellStyle: pw.TextStyle(font: font, fontSize: 12),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
        cellAlignment: pw.Alignment.centerLeft,
        cellPadding: const pw.EdgeInsets.all(4),
        headers: ['Подход', 'Применимость', 'Достоверность информации', 'Вес'],
        data: [
          ['Сравнительный', 'Высокая', 'Высокая', '0,80'],
          ['Затратный', 'Средняя', 'Средняя', '0,20'],
          ['Доходный', 'Низкая', 'Низкая', '0,00'],
        ],
      ),
      pw.SizedBox(height: 8),
      _para('Сравнительный подход получил наибольший вес, поскольку он в наибольшей степени '
          'отражает рыночную конъюнктуру и основан на представительной выборке предложений '
          'по сопоставимым объектам. Затратному подходу присвоен меньший вес — он '
          'использовался как контрольный и не учитывает в полной мере рыночные факторы '
          'спроса и предложения. Доходный подход не применялся ввиду отсутствия '
          'достоверной информации о доходах, приносимых объектом.', font),
      _para('Итоговая величина рыночной стоимости объекта оценки определяется как '
          'средневзвешенное значение результатов подходов с учетом присвоенных весовых '
          'коэффициентов и округляется до целого значения в тенге. Полученный результат '
          'приведен в разделе 4 настоящего отчета.', font),
    ];
  }

  static pw.Widget _buildComparablesTable(ReportData data, pw.Font font, pw.Font fontBold) {
    // Собираем уникальные элементы сравнения из всех аналогов
    final elements = <String>[];
    for (final c in data.comparables) {
      for (final a in c.adjustments) {
        if (!elements.contains(a.name)) elements.add(a.name);
      }
    }
    if (elements.isEmpty) elements.addAll(['Местоположение', 'Площадь', 'Состояние']);

    final headers = ['Адрес', 'Площадь', 'Цена', ...elements, 'Скорр. цена'];
    final rows = data.comparables.map((c) {
      final byName = {for (final a in c.adjustments) a.name: a.formattedPercent};
      return [
        c.address,
        '${c.area} м²',
        c.formattedPrice,
        ...elements.map((e) => byName[e] ?? '0%'),
        c.adjustedPrice > 0
            ? '${c.adjustedPrice.toStringAsFixed(0)} ₸'
            : c.formattedPrice,
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(font: fontBold, fontSize: 9),
      cellStyle: pw.TextStyle(font: font, fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignments: {for (var i = 0; i < headers.length; i++) i: pw.Alignment.centerLeft},
      headers: headers,
      data: rows,
    );
  }

  static List<pw.Widget> _buildConclusion(ReportData data, pw.Font font, pw.Font fontBold) {
    return [
      _miniTitle('4.1. Итоговая величина стоимости объекта оценки', font, fontBold),
      _para('Основываясь на результатах расчетов, руководствуясь вышеизложенными фактами '
          'и суждениями и учитывая состояние оцениваемого объекта, мы пришли к следующему '
          'выводу: возможная рыночная стоимость оцениваемого объекта составляет:', font),
      pw.SizedBox(height: 6),
      pw.Text(
        data.formattedPrice,
        style: pw.TextStyle(font: fontBold, fontSize: 20),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        '(${_numberToWords(data.estimatedPrice)}) тенге',
        style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 12),
      _para('Итоговая величина стоимости объекта оценки выражается в национальной валюте '
          'Республики Казахстан и отражается в тенге с письменной расшифровкой суммы в скобках. '
          'Итоговая величина стоимости признается рекомендуемой для целей совершения сделки, '
          'если от даты составления отчета прошло не более шести месяцев.', font),
      pw.SizedBox(height: 14),
      _miniTitle('4.2. Обоснование итоговой величины стоимости', font, fontBold),
      _para('Итоговая величина рыночной стоимости объекта оценки определена на основе '
          'сравнительного подхода, который признан наиболее адекватным для оцениваемого '
          'объекта ввиду развитости рынка и наличия достаточной информации о предложениях '
          'по сопоставимым объектам. Расчет выполнен на основе анализа от ${data.comparables.length} '
          'объектов-аналогов с внесением корректировок по элементам сравнения.', font),
      _para('Полученная в рамках сравнительного подхода величина стоимости находится в '
          'пределах рыночного диапазона (${data.formattedPriceRangeLow} – '
          '${data.formattedPriceRangeHigh} тенге) и отражает индивидуальные характеристики '
          'объекта оценки: ${_or(data.condition, 'техническое состояние')}, '
          'местоположение, площадь и иные ценообразующие факторы, выявленные в ходе '
          'осмотра и анализа.', font),
      _para('Затратный и доходный подходы не применялись либо применялись как '
          'вспомогательные в силу ограничений, описанных в разделе 3 настоящего отчета. '
          'Итоговая величина стоимости не округлялась в сторону занижения или завышения '
          'и отражает профессиональное суждение Оценщика на дату оценки.', font),
      pw.SizedBox(height: 14),
      _miniTitle('4.3. Заявление оценщика', font, fontBold),
      _bullet('факты, изложенные в отчете, верны и соответствуют действительности;', font),
      _bullet('анализ, мнения и заключения принадлежат Оценщику и действительны строго в '
          'пределах ограничительных условий и допущений, являющихся частью отчета;', font),
      _bullet('Оценщик не имеет ни настоящей, ни ожидаемой заинтересованности в оцениваемом '
          'имуществе и действует непредвзято и без предубеждения по отношению к '
          'участвующим сторонам;', font),
      _bullet('вознаграждение Оценщика не зависит от итоговой величины стоимости, а также '
          'тех событий, которые могут наступить в результате использования Заказчиком или '
          'третьими сторонами выводов и заключений, содержащихся в отчете;', font),
      _bullet('оценка была проведена, а отчет составлен в соответствии с Кодексом этики и '
          'Стандартами оценки, утвержденными в Республике Казахстан;', font),
      _bullet('Оценщик имеет необходимое профессиональное образование и опыт работы в '
          'области оценочной деятельности, подтвержденные соответствующими документами;', font),
      _bullet('при проведении оценки использовались данные, полученные из открытых '
          'источников, признанных достоверными; Оценщик не проводил их независимой '
          'проверки.', font),
      pw.SizedBox(height: 14),
      _miniTitle('4.4. Ограничительные условия заключения', font, fontBold),
      _para('Настоящий отчет достоверен лишь в полном объеме и лишь в указанных в нем '
          'целях. Ни отчет, ни отдельные его части не могут являться документом, '
          'используемым в целях, не предусмотренных договором об оценке.', font),
      _para('Оценщик не принимает на себя ответственность за последствия использования '
          'отчета третьими лицами, не являющимися Заказчиком, а также за убытки, '
          'возникшие вследствие использования отчета после истечения срока его '
          'действительности либо с нарушением ограничительных условий и допущений.', font),
      pw.SizedBox(height: 24),
      pw.Divider(color: PdfColors.grey300),
      pw.SizedBox(height: 10),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Оценщик:', style: pw.TextStyle(font: font, fontSize: 12)),
              pw.SizedBox(height: 2),
              pw.Text(data.appraiserName, style: pw.TextStyle(font: fontBold, fontSize: 12)),
              if (data.appraiserCertificate.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text('Свидетельство: ${data.appraiserCertificate}',
                    style: pw.TextStyle(font: font, fontSize: 10)),
              ],
            ],
          ),
          pw.SizedBox(width: 40),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Дата: ${data.appraisalDate}',
                    style: pw.TextStyle(font: font, fontSize: 12)),
                pw.SizedBox(height: 20),
                pw.Container(
                  width: 200,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400)),
                  ),
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text(
                    'Подпись / ЭЦП',
                    style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey500),
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

  static List<pw.Widget> _buildAppendices(
    ReportData data,
    pw.Font font,
    pw.Font fontBold, {
    List<Uint8List> photos = const [],
  }) {
    return [
      _subTitle('Приложение №1. Акт осмотра объекта оценки', font, fontBold),
      _para('Настоящий акт составлен в том, что ${_or(data.inspectionDate, data.appraisalDate)} '
          'произведен визуальный осмотр объекта оценки, расположенного по адресу: '
          '${data.address}. В ходе осмотра установлено: объект идентифицирован, физическое '
          'состояние — ${_or(data.condition, 'удовлетворительное')}. Замечаний к состоянию '
          'объекта не заявлено (либо замечания отражены в отчете).', font),
      pw.SizedBox(height: 6),
      _kv('Дата осмотра', _or(data.inspectionDate, data.appraisalDate), font, fontBold),
      _kv('Объект', data.propertyType, font, fontBold),
      _kv('Адрес', data.address, font, fontBold),
      _kv('Состояние', data.condition, font, fontBold),
      pw.SizedBox(height: 10),
      _miniTitle('Результаты осмотра конструктивных элементов и инженерных систем', font, fontBold),
      _kv('Фундамент и несущие конструкции', 'дефектов не выявлено', font, fontBold),
      _kv('Стены и перегородки', 'дефектов не выявлено', font, fontBold),
      _kv('Перекрытия и кровля', 'дефектов не выявлено', font, fontBold),
      _kv('Оконные и дверные заполнения', 'в работоспособном состоянии', font, fontBold),
      _kv('Полы', 'в удовлетворительном состоянии', font, fontBold),
      _kv('Внутренняя отделка', 'соответствует заявленному состоянию', font, fontBold),
      _kv('Электроснабжение', 'в работоспособном состоянии', font, fontBold),
      _kv('Водоснабжение и канализация', 'в работоспособном состоянии', font, fontBold),
      _kv('Отопление', 'в работоспособном состоянии', font, fontBold),
      _kv('Вентиляция', 'в работоспособном состоянии', font, fontBold),
      pw.SizedBox(height: 10),
      _para('Осмотр произведен в присутствии Заказчика (либо представителя Заказчика). '
          'Фотографирование объекта выполнено, фотоматериалы приведены в Приложении №3 '
          'к настоящему отчету.', font),
      pw.SizedBox(height: 10),
      _miniTitle('Выводы по результатам осмотра', font, fontBold),
      _bullet('объект оценки идентифицирован по адресу и характеристикам, соответствует '
          'сведениям, указанным в правоустанавливающих документах;', font),
      _bullet('техническое состояние объекта характеризуется как работоспособное, '
          'пригодное для использования по назначению;', font),
      _bullet('признаков аварийного состояния, деформаций, протечек и иных повреждений, '
          'влияющих на несущую способность конструкций, не выявлено;', font),
      _bullet('объект обеспечен инженерными коммуникациями, системы находятся в '
          'работоспособном состоянии;', font),
      _bullet('самовольных перепланировок и переустройств, требующих согласования, не '
          'выявлено;', font),
      _bullet('объект свободен от видимых обременений, ограничивающих его использование '
          'по назначению.', font),
      _para('Результаты осмотра учтены Оценщиком при определении корректировок на '
          'техническое состояние и иные физические характеристики объекта в рамках '
          'сравнительного подхода.', font),
      pw.SizedBox(height: 8),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Оценщик:', style: pw.TextStyle(font: font, fontSize: 12)),
              pw.SizedBox(height: 2),
              pw.Text(data.appraiserName, style: pw.TextStyle(font: fontBold, fontSize: 12)),
            ],
          ),
          pw.SizedBox(width: 40),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Дата: ${_or(data.inspectionDate, data.appraisalDate)}',
                    style: pw.TextStyle(font: font, fontSize: 12)),
                pw.SizedBox(height: 20),
                pw.Container(
                  width: 200,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400)),
                  ),
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text(
                    'Подпись / Отказ от подписи',
                    style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey500),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 24),
      _subTitle('Приложение №2. Аналогичные объекты (объявления о продаже)', font, fontBold),
      if (data.comparables.isNotEmpty) ...[
        _buildComparablesTable(data, font, fontBold),
        pw.SizedBox(height: 12),
        pw.Text(
          'Источники объявлений: ${data.comparables.where((c) => c.url.isNotEmpty).map((c) => c.url).join('; ')}',
          style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 12),
        _miniTitle('Описание объектов-аналогов', font, fontBold),
        for (var i = 0; i < data.comparables.length; i++) ...[
          _miniTitle('Аналог №${i + 1}: ${data.comparables[i].address}', font, fontBold),
          _kv('Местоположение', data.comparables[i].address, font, fontBold),
          _kv('Площадь', '${_fmtArea(data.comparables[i].area)} кв.м.', font, fontBold),
          _kv('Цена предложения', data.comparables[i].formattedPrice, font, fontBold),
          if (data.comparables[i].type.isNotEmpty)
            _kv('Тип объекта', data.comparables[i].type, font, fontBold),
          if (data.comparables[i].source.isNotEmpty)
            _kv('Источник', data.comparables[i].source, font, fontBold),
          if (data.comparables[i].url.isNotEmpty)
            _kv('Ссылка на объявление', data.comparables[i].url, font, fontBold),
          if (data.comparables[i].adjustments.isNotEmpty) ...[
            _miniTitle('Корректировки по элементам сравнения', font, fontBold),
            for (final a in data.comparables[i].adjustments)
              _kv(a.name, a.formattedPercent, font, fontBold),
          ],
          _kv('Скорректированная цена',
              data.comparables[i].adjustedPrice > 0
                  ? '${data.comparables[i].adjustedPrice.toStringAsFixed(0)} ₸'
                  : data.comparables[i].formattedPrice,
              font, fontBold),
          pw.SizedBox(height: 8),
        ],
      ] else
        pw.Text(
          'Объявления о продаже аналогов приведены в разделе 3 отчета.',
          style: pw.TextStyle(font: font, fontSize: 12),
        ),
      pw.SizedBox(height: 24),
      _subTitle('Приложение №3. Фотографии объекта оценки', font, fontBold),
      if (photos.isEmpty)
        pw.Text(
          'Фотографии объекта прилагаются (при наличии).',
          style: pw.TextStyle(font: font, fontSize: 12),
        )
      else
        for (var i = 0; i < photos.length; i++) ...[
          pw.SizedBox(height: 8),
          pw.Text('Фото ${i + 1}:', style: pw.TextStyle(font: fontBold, fontSize: 12)),
          pw.SizedBox(height: 4),
          pw.Image(pw.MemoryImage(photos[i]), height: 160, fit: pw.BoxFit.contain),
        ],
      pw.SizedBox(height: 24),
      _subTitle('Приложение №4. Документы, предоставленные заказчиком', font, fontBold),
      _bullet('Документ, удостоверяющий личность Заказчика;', font),
      _bullet('Правоустанавливающие документы на объект оценки;', font),
      _bullet('Техническая документация на объект оценки.', font),
      pw.SizedBox(height: 24),
      _subTitle('Приложение №5. Расчет стоимости', font, fontBold),
      _kv('Итоговая рыночная стоимость', data.formattedPrice, font, fontBold),
      _kv('Прописью', '(${_numberToWords(data.estimatedPrice)}) тенге', font, fontBold),
      _kv('Дата оценки', data.appraisalDate, font, fontBold),
      pw.SizedBox(height: 24),
      _subTitle('Приложение №6. Список использованных источников и литературы', font, fontBold),
      _bullet('Закон Республики Казахстан от 10 января 2018 года № 133-VI «Об оценочной деятельности в Республике Казахстан»;', font),
      _bullet('Стандарты оценки, утвержденные приказом Министра национальной экономики Республики Казахстан;', font),
      _bullet('Кодекс этики оценщиков Республики Казахстан;', font),
      _bullet('Гражданский кодекс Республики Казахстан (Особенная часть);', font),
      _bullet('Земельный кодекс Республики Казахстан;', font),
      _bullet('Закон Республики Казахстан «О государственной регистрации прав на недвижимое имущество»;', font),
      _bullet('Данные порталов недвижимости krisha.kz, olx.kz (объявления о продаже объектов-аналогов);', font),
      _bullet('Данные Бюро национальной статистики Агентства по стратегическому планированию и реформам Республики Казахстан;', font),
      _bullet('Аналитические обзоры рынка недвижимости Республики Казахстан;', font),
      _bullet('Сборники укрупненных показателей стоимости строительства (для расчетов в рамках затратного подхода);', font),
      _bullet('Практика оценки недвижимости: учебные и методические пособия по оценочной деятельности.', font),
      pw.SizedBox(height: 24),
      _subTitle('Приложение №7. Квалификация и независимость оценщика', font, fontBold),
      _kv('ФИО оценщика', data.appraiserName, font, fontBold),
      _kv('Профессиональная организация', 'ОО «Содружество оценщиков»', font, fontBold),
      _kv('Свидетельство', '№ 00170', font, fontBold),
      _kv('Дата выдачи свидетельства', '01.06.2019 г.', font, fontBold),
      pw.SizedBox(height: 8),
      _para('Оценщик имеет высшее профессиональное образование, прошел профессиональную '
          'переподготовку в области оценочной деятельности и состоит в профессиональной '
          'организации оценщиков. Оценщик подтверждает свою независимость: не является '
          'учредителем, участником, акционером, кредитором, страховщиком или должностным '
          'лицом Заказчика, не состоит с Заказчиком в близком родстве, не имеет '
          'имущественного интереса в объекте оценки.', font),
      _para('Оценщик несет ответственность за качество проведенной оценки и достоверность '
          'результатов, отраженных в настоящем отчете, в соответствии с законодательством '
          'Республики Казахстан об оценочной деятельности. Профессиональная деятельность '
          'Оценщика застрахована в установленном порядке.', font),
      pw.SizedBox(height: 8),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Оценщик: ____________________ ${data.appraiserName}',
              style: pw.TextStyle(font: font, fontSize: 12)),
          pw.Text('Дата: ${data.appraisalDate}', style: pw.TextStyle(font: font, fontSize: 12)),
        ],
      ),
      pw.SizedBox(height: 24),
      _subTitle('Приложение №8. Схема расположения объекта оценки', font, fontBold),
      _para('Объект оценки расположен в пределах сложившейся застройки населенного пункта. '
          'Схема расположения объекта относительно ключевых элементов транспортной и '
          'социальной инфраструктуры приведена ниже (текстовое описание; картографический '
          'материал прилагается при наличии).', font),
      _kv('Населенный пункт', 'г. Алматы', font, fontBold),
      _kv('Район', 'Алмалинский район', font, fontBold),
      _kv('Адрес', data.address, font, fontBold),
      _kv('Ближайшие магистрали', 'в пределах 5–10 минут транспортной доступности', font, fontBold),
      _kv('Общественный транспорт', 'маршруты в непосредственной близости', font, fontBold),
      _kv('Социальная инфраструктура', 'школы, детские сады, медицинские учреждения, объекты торговли в пешей доступности', font, fontBold),
      pw.SizedBox(height: 8),
      _para('Расположение объекта обеспечивает удобный доступ ко всем элементам городской '
          'инфраструктуры, что положительно влияет на потребительскую привлекательность и '
          'ликвидность объекта на рынке. Транспортная доступность оценивается как '
          'удовлетворительная для объектов данного сегмента.', font),
      pw.SizedBox(height: 24),
      _subTitle('Приложение №9. Копии документов, предоставленных Заказчиком', font, fontBold),
      _para('В настоящем приложении приводятся копии документов, предоставленных Заказчиком '
          'для проведения оценки: документ, удостоверяющий личность, правоустанавливающие '
          'документы на объект оценки, техническая документация, иные документы, '
          'использованные Оценщиком при проведении оценки. Копии документов прилагаются '
          'при наличии.', font),
      _bullet('Копия документа, удостоверяющего личность Заказчика;', font),
      _bullet('Копия правоустанавливающего документа на объект оценки;', font),
      _bullet('Копия технического паспорта (технической документации) на объект;', font),
      _bullet('Копия справки о зарегистрированных правах (обременениях);', font),
      _bullet('Иные документы, использованные при проведении оценки.', font),
      _para('Оценщик подтверждает, что все документы, использованные при проведении '
          'оценки, получены от Заказчика либо из открытых источников и приняты в '
          'качестве исходных данных для расчетов. Ответственность за достоверность '
          'предоставленных документов несет Заказчик.', font),
    ];
  }

  /// Раздел 5. Сертификат качества оценки — итоговые подписи и печать.
  static List<pw.Widget> _buildCertificate(ReportData data, pw.Font font, pw.Font fontBold) {
    return [
      _para('Настоящим удостоверяется, что в соответствии с заданием на оценку, '
          'договором об оценке и требованиями законодательства Республики Казахстан об '
          'оценочной деятельности, Оценщиком проведена оценка объекта, указанного в '
          'настоящем отчете, и определена его рыночная стоимость на дату оценки.', font),
      _kv('Объект оценки', data.propertyType, font, fontBold),
      _kv('Местонахождение', data.address, font, fontBold),
      _kv('Дата оценки', data.appraisalDate, font, fontBold),
      _kv('Итоговая рыночная стоимость', data.formattedPrice, font, fontBold),
      _kv('Прописью', '(${_numberToWords(data.estimatedPrice)}) тенге', font, fontBold),
      pw.SizedBox(height: 16),
      _para('Оценка проведена в соответствии с Законом Республики Казахстан «Об '
          'оценочной деятельности в Республике Казахстан», Стандартами оценки, '
          'утвержденными приказом Министра финансов Республики Казахстан, Кодексом '
          'этики оценщиков. Оценщик подтверждает, что провел оценку объективно, '
          'независимо и беспристрастно, руководствуясь исключительно профессиональными '
          'критериями.', font),
      _para('Содержащиеся в отчете анализ, мнения и заключения действительны строго в '
          'пределах ограничительных условий и допущений, являющихся частью отчета. '
          'Отчет достоверен лишь в полном объеме и лишь в указанных в нем целях.', font),
      pw.SizedBox(height: 20),
      pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.blue800, width: 1.5),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'ОЦЕНЩИК:',
              style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.blue800),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              '_____________________________  ${data.appraiserName}',
              style: pw.TextStyle(font: font, fontSize: 12),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Свидетельство о присвоении квалификации «Оценщик» № ${data.appraiserCertificate.isEmpty ? '___' : data.appraiserCertificate}',
              style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 14),
            pw.Text(
              'РУКОВОДИТЕЛЬ:',
              style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.blue800),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              '_____________________________  ${ReportService.directorName}',
              style: pw.TextStyle(font: font, fontSize: 12),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Директор ${data.legalEntityName.isEmpty ? 'ТОО «ESEP»' : data.legalEntityName}',
              style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 14),
            pw.Text(
              'М.П.',
              style: pw.TextStyle(font: fontBold, fontSize: 12),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 16),
      _miniTitle('Сведения о страховании гражданско-правовой ответственности', font, fontBold),
      _para('Гражданско-правовая ответственность Оценщика застрахована в соответствии с '
          'требованиями законодательства Республики Казахстан об оценочной '
          'деятельности. Страховой полис покрывает риски причинения ущерба Заказчику '
          'или третьим лицам вследствие ошибок, упущений и небрежности при проведении '
          'оценочных работ.', font),
      _kv('Страховщик', 'страховая организация, имеющая лицензию на осуществление страховой деятельности', font, fontBold),
      _kv('Объект страхования', 'имущественные интересы Оценщика, связанные с риском ответственности по обязательствам, возникающим вследствие причинения вреда', font, fontBold),
      _kv('Срок действия полиса', 'в течение срока действия договора страхования', font, fontBold),
      pw.SizedBox(height: 16),
      _para('Отчет об оценке составлен в ${data.appraisalDate.split('.').last} году в двух '
          'экземплярах, имеющих равную юридическую силу. Один экземпляр передан '
          'Заказчику, второй хранится в архиве исполнителя.', font),
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
          style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.blue800),
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
            style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.green900),
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
          style: pw.TextStyle(font: fontBold, fontSize: 15, color: PdfColors.blue800),
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
      child: pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 13)),
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
            child: pw.Text(label, style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey600)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 12)),
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
          pw.SizedBox(width: 20, child: pw.Text(num, style: pw.TextStyle(font: font, fontSize: 12))),
          pw.Expanded(child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 12, height: 1.5))),
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
              style: pw.TextStyle(font: font, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Авто/мото/спецтехника — движимое имущество, отдельный шаблон.
  static bool _isCar(String? type) {
    final t = (type ?? '').toLowerCase();
    return t.contains('авто') || t.contains('машин') || t.contains('мото') ||
        t.contains('грузов') || t.contains('спецтехник') || t.contains('автобус');
  }

  /// Площадь: 29.2 → «29,2» (без лишних нулей).
  static String _fmtArea(double area) {
    if (area == 0) return '—';
    return area.toStringAsFixed(area == area.roundToDouble() ? 0 : 1)
        .replaceAll('.', ',');
  }

  /// a ?? fallback с учётом пустых строк.
  static String _or(String a, String fallback) =>
      (a.trim().isEmpty) ? fallback : a.trim();

  static pw.Widget _bullet(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4, left: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 8, child: pw.Text('•', style: pw.TextStyle(font: font, fontSize: 12))),
          pw.Expanded(child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 12, height: 1.5))),
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

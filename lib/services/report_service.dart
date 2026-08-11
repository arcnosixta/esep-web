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

    // 5. Раздел 3. Расчетная часть (методология + аналоги + расчет)
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
    final isCar = _isCar(data.propertyType);
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
          isCar ? 'об оценке движимого имущества' : 'об оценке недвижимого имущества',
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
        if (data.clientIdDoc.isNotEmpty) _kv('Удостоверение', data.clientIdDoc, font, fontBold),
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
        style: pw.TextStyle(font: font, fontSize: 11, height: 1.45),
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
        style: pw.TextStyle(font: font, fontSize: 11, height: 1.45),
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
        style: pw.TextStyle(font: font, fontSize: 11, height: 1.45),
      ),
      pw.SizedBox(height: 12),
      _subTitle('Таблица 1. Техническая характеристика объекта оценки', font, fontBold),
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(font: fontBold, fontSize: 9),
        cellStyle: pw.TextStyle(font: font, fontSize: 10),
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
      _subTitle('2.3. Анализ рынка объекта оценки', font, fontBold),
      pw.Text(
        'Анализ рынка выполнен на основании данных открытых источников: порталов '
        'недвижимости (krisha.kz, olx.kz), данных Агентства РК по статистике и '
        'аналитических обзоров рынка недвижимости. Рынок ${data.propertyType.toLowerCase()} '
        'в г. Алматы характеризуется устойчивым спросом, ликвидность объекта '
        'оценивается как средняя. Ценовой диапазон предложений по аналогичным объектам '
        'составляет от ${data.formattedPriceRangeLow} до ${data.formattedPriceRangeHigh} тенге. '
        'Срок экспозиции типового объекта данного сегмента — от 1 до 3 месяцев.',
        style: pw.TextStyle(font: font, fontSize: 11, height: 1.45),
      ),
      pw.SizedBox(height: 10),
      _subTitle('2.4. Анализ наиболее эффективного использования', font, fontBold),
      pw.Text(
        'Наиболее эффективным использованием объекта оценки является его текущее '
        'использование по назначению — ${_or(data.purpose, 'проживание')}. Данный вариант '
        'использования соответствует сложившейся застройке района, обеспечивает '
        'максимальную доходность при минимальных затратах на адаптацию и не '
        'противоречит градостроительным регламентам.',
        style: pw.TextStyle(font: font, fontSize: 11, height: 1.45),
      ),
      pw.SizedBox(height: 14),
      _subTitle('2.5. Имущественные права, обременения и физические характеристики', font, fontBold),
      pw.Text(
        'Адрес объекта оценки: ${data.address}.',
        style: pw.TextStyle(font: font, fontSize: 11, height: 1.45),
      ),
      pw.SizedBox(height: 6),
      pw.Text(
        'Объект расположен в сложившейся застройке, окружение типичное, подъездные пути в '
        'хорошем состоянии, обеспечен общественным транспортом. Развитие инфраструктуры '
        'района соответствует уровню застройки; в непосредственной близости расположены '
        'объекты социальной и коммерческой инфраструктуры.',
        style: pw.TextStyle(font: font, fontSize: 11, height: 1.45),
      ),
      pw.SizedBox(height: 14),
      _subTitle('2.4. Имущественные права, обременения и физические характеристики', font, fontBold),
      pw.Text(
        'Оцениваемое право — право собственности. Объект оценки свободен от каких-либо '
        'обременений и ограничений, что подтверждено документально (при наличии '
        'предоставленных документов). Физическое состояние объекта оценено на основании '
        'визуального осмотра и предоставленной документации.',
        style: pw.TextStyle(font: font, fontSize: 11, height: 1.45),
      ),
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
        style: pw.TextStyle(font: font, fontSize: 11, height: 1.45),
      ),
      pw.SizedBox(height: 12),
      _subTitle('Таблица 1. Техническая характеристика объекта оценки', font, fontBold),
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(font: fontBold, fontSize: 9),
        cellStyle: pw.TextStyle(font: font, fontSize: 10),
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
        style: pw.TextStyle(font: font, fontSize: 11, height: 1.45),
      ),
    ];
  }

  static List<pw.Widget> _buildCalculation(ReportData data, pw.Font font, pw.Font fontBold) {
    return [
      _subTitle('3.1. Методология оценки и обоснование выбора подходов и методов, примененных в данном отчете', font, fontBold),
      pw.Text(
        'Установление рыночной или иной стоимости производится путем применения методов '
        'оценки, сгруппированных в доходный, затратный и сравнительный подходы.',
        style: pw.TextStyle(font: font, fontSize: 11, height: 1.45),
      ),
      pw.SizedBox(height: 8),
      _numItem('1', 'Доходный подход применяется при оценке объектов недвижимости, которые покупаются и продаются в связи с их способностью приносить доходы.', font),
      _bullet('метод дисконтирования денежных потоков (метод дисконтированного наличного потока) – определение стоимости исходя из условий изменения и неравномерного поступления денежных потоков в зависимости от степени риска, связанного с использованием объекта;', font),
      _bullet('метод прямой капитализации дохода – определение стоимости объекта путем деления соответствующего рынку годового чистого операционного дохода на коэффициент капитализации, полученный на основе анализа рыночных данных о соотношениях дохода к стоимости активов, аналогичных оцениваемому;', font),
      _numItem('2', 'Затратный подход применяется для проведения оценки недвижимого имущества, рынок купли-продажи или аренды которого является ограниченным.', font),
      _bullet('Применение затратного подхода состоит в определении остаточной стоимости воспроизводства (замещения) объекта оценки, которая состоит из остаточной стоимости воспроизводства (замещения) земельных улучшений и рыночной стоимости земельного участка;', font),
      _bullet('Стоимость полного воспроизводства, как правило, определяется при оценке объекта, замещение которого невозможно, а также в случае соответствия существующего использования объекта оценки его наиболее эффективному использованию;', font),
      _numItem('3', 'Сравнительный подход применяется для определения рыночной стоимости объекта оценки путем сравнения с объектами-аналогами, по которым имеется достаточная и достоверная информация о ценах сделок или предложений.', font),
      _bullet('Основой применения сравнительного подхода является тот факт, что стоимость объекта оценки напрямую связана с ценой продажи аналогичных объектов;', font),
      _bullet('При этом вносятся корректировки на различия между объектом оценки и аналогами (дата предложения, местоположение, площадь, состояние, этаж и другие характеристики);', font),
      pw.SizedBox(height: 8),
      pw.Text(
        'Для ${data.propertyType.toLowerCase()} наиболее объективные результаты даёт '
        'сравнительный подход, который в силу хорошо развитой системы информационного '
        'обеспечения рынка применяется как основной. Затратный подход применяется как '
        'дополнительный, доходный подход в данном случае не применяется ввиду отсутствия '
        'достоверной информации о доходах, приносимых объектом.',
        style: pw.TextStyle(font: font, fontSize: 11, height: 1.45),
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
        'Для определения стоимости методом сравнительного анализа используется следующая '
        'последовательность: исследование рынка, сбор информации о сделках или предложениях '
        'по объектам-аналогам, проверка надежности информации, выбор не менее трех типичных '
        'аналогов, внесение корректировок по элементам сравнения, расчет скорректированных цен.',
        style: pw.TextStyle(font: font, fontSize: 11, height: 1.45),
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
      headerStyle: pw.TextStyle(font: fontBold, fontSize: 8),
      cellStyle: pw.TextStyle(font: font, fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignments: {for (var i = 0; i < headers.length; i++) i: pw.Alignment.centerLeft},
      headers: headers,
      data: rows,
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

  static List<pw.Widget> _buildAppendices(
    ReportData data,
    pw.Font font,
    pw.Font fontBold, {
    List<Uint8List> photos = const [],
  }) {
    return [
      _subTitle('Приложение №1. Акт осмотра объекта оценки', font, fontBold),
      pw.Text(
        'Настоящий акт составлен в том, что ${_or(data.inspectionDate, data.appraisalDate)} '
        'произведен визуальный осмотр объекта оценки, расположенного по адресу: '
        '${data.address}. В ходе осмотра установлено: объект идентифицирован, физическое '
        'состояние — ${_or(data.condition, 'удовлетворительное')}. Замечаний к состоянию '
        'объекта не заявлено (либо замечания отражены в отчете).',
        style: pw.TextStyle(font: font, fontSize: 11, height: 1.45),
      ),
      pw.SizedBox(height: 12),
      _kv('Дата осмотра', _or(data.inspectionDate, data.appraisalDate), font, fontBold),
      _kv('Объект', data.propertyType, font, fontBold),
      _kv('Адрес', data.address, font, fontBold),
      _kv('Состояние', data.condition, font, fontBold),
      pw.SizedBox(height: 10),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Оценщик: ${data.appraiserName}', style: pw.TextStyle(font: font, fontSize: 10)),
          pw.Text('Заказчик: ${data.clientName}', style: pw.TextStyle(font: font, fontSize: 10)),
        ],
      ),
      pw.SizedBox(height: 24),
      _subTitle('Приложение №2. Аналогичные объекты (объявления о продаже)', font, fontBold),
      if (data.comparables.isNotEmpty) ...[
        _buildComparablesTable(data, font, fontBold),
        pw.SizedBox(height: 12),
        pw.Text(
          'Источники объявлений: ${data.comparables.where((c) => c.url.isNotEmpty).map((c) => c.url).join('; ')}',
          style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700),
        ),
      ] else
        pw.Text(
          'Объявления о продаже аналогов приведены в разделе 3 отчета.',
          style: pw.TextStyle(font: font, fontSize: 10),
        ),
      pw.SizedBox(height: 24),
      _subTitle('Приложение №3. Фотографии объекта оценки', font, fontBold),
      if (photos.isEmpty)
        pw.Text(
          'Фотографии объекта прилагаются (при наличии).',
          style: pw.TextStyle(font: font, fontSize: 10),
        )
      else
        for (var i = 0; i < photos.length; i++) ...[
          pw.SizedBox(height: 8),
          pw.Text('Фото ${i + 1}:', style: pw.TextStyle(font: fontBold, fontSize: 10)),
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
          pw.SizedBox(width: 8, child: pw.Text('•', style: pw.TextStyle(font: font, fontSize: 11))),
          pw.Expanded(child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 11, height: 1.45))),
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

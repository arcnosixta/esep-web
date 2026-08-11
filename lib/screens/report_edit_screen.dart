import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/report_template.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../widgets/option_button.dart';

/// Экран редактирования отчёта оценщиком перед подписанием.
///
/// Оценщик может поправить ключевые данные отчёта (заказчик, объект,
/// итоговая стоимость, дата, номер), характеристики, аналоги со ссылками
/// и фото объекта (до 10, добавление/удаление), сгенерированные ИИ, —
/// после чего отчёт перегенерируется с учётом правок.
class ReportEditScreen extends StatefulWidget {
  final ReportData data;
  final String? applicationId;

  /// Пути фото в storage (user-docs/report_photos/...) из заявки.
  final List<String> initialPhotoUrls;

  const ReportEditScreen({
    super.key,
    required this.data,
    this.applicationId,
    this.initialPhotoUrls = const [],
  });

  @override
  State<ReportEditScreen> createState() => _ReportEditScreenState();
}

class _ReportEditScreenState extends State<ReportEditScreen> {
  static const _propertyTypes = <String>[
    'Квартира',
    'Дом',
    'Земельный участок',
    'Коммерческое помещение',
    'Авто',
  ];

  late final TextEditingController _clientName;
  late final TextEditingController _clientIin;
  late final TextEditingController _address;
  late final TextEditingController _area;
  late final TextEditingController _rooms;
  late final TextEditingController _floor;
  late final TextEditingController _totalFloors;
  late final TextEditingController _condition;
  late final TextEditingController _yearBuilt;
  late final TextEditingController _cadastralNumber;
  late final TextEditingController _purpose;
  late final TextEditingController _estimatedPrice;
  late final TextEditingController _priceRangeLow;
  late final TextEditingController _priceRangeHigh;
  late final TextEditingController _reportNumber;
  late final TextEditingController _appraisalDateController;
  late final TextEditingController _inspectionDate;
  late final TextEditingController _clientIdDoc;

  // Характеристики объекта (недвижимость).
  late final TextEditingController _buildingType;
  late final TextEditingController _wallMaterial;
  late final TextEditingController _buildingCondition;
  late final TextEditingController _communications;
  late final TextEditingController _livingArea;
  late final TextEditingController _kitchenArea;
  late final TextEditingController _bathroom;
  late final TextEditingController _balcony;
  late final TextEditingController _renovationYear;
  late final TextEditingController _layout;

  // Авто (заполняется для «Авто»).
  late final Map<String, TextEditingController> _car = {
    for (final k in _carKeys) k: TextEditingController(),
  };
  static const _carKeys = [
    'make', 'model', 'year', 'vin', 'plate', 'mileage',
    'body', 'engine', 'transmission', 'drive', 'color',
  ];
  static const _carLabels = {
    'make': 'Марка',
    'model': 'Модель',
    'year': 'Год выпуска',
    'vin': 'VIN',
    'plate': 'Гос. номер',
    'mileage': 'Пробег, км',
    'body': 'Кузов',
    'engine': 'Двигатель',
    'transmission': 'Коробка',
    'drive': 'Привод',
    'color': 'Цвет',
  };

  late String _propertyType;
  late DateTime _appraisalDate;

  final ImagePicker _picker = ImagePicker();

  /// Пути фото в storage + закешированные signed-URL для миниатюр.
  late List<String> _photoUrls;
  final Map<String, String> _photoSignedUrls = {};

  /// Редактируемые аналоги (адрес, площадь, цена, источник, ссылка).
  final List<_ComparableEdit> _comparables = [];

  bool _isCar(String t) {
    final v = t.toLowerCase();
    return v.contains('авто') || v.contains('автомобил') || v.contains('транспорт') || v.contains('машин');
  }

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _clientName = TextEditingController(text: d.clientName);
    _clientIin = TextEditingController(text: d.clientIin);
    _address = TextEditingController(text: d.address);
    _area = TextEditingController(text: _fmtNum(d.area));
    _rooms = TextEditingController(text: d.rooms > 0 ? '${d.rooms}' : '');
    _floor = TextEditingController(text: d.floor > 0 ? '${d.floor}' : '');
    _totalFloors =
        TextEditingController(text: d.totalFloors > 0 ? '${d.totalFloors}' : '');
    _condition = TextEditingController(text: d.condition);
    _yearBuilt =
        TextEditingController(text: d.yearBuilt > 0 ? '${d.yearBuilt}' : '');
    _cadastralNumber = TextEditingController(text: d.cadastralNumber);
    _purpose = TextEditingController(text: d.purpose);
    _estimatedPrice =
        TextEditingController(text: d.estimatedPrice > 0 ? '${d.estimatedPrice.round()}' : '');
    _priceRangeLow =
        TextEditingController(text: d.priceRangeLow > 0 ? '${d.priceRangeLow.round()}' : '');
    _priceRangeHigh =
        TextEditingController(text: d.priceRangeHigh > 0 ? '${d.priceRangeHigh.round()}' : '');
    _reportNumber = TextEditingController(text: d.reportNumber);
    _appraisalDateController = TextEditingController(
      text: _fmtDate(_parseDate(d.appraisalDate) ?? DateTime.now()),
    );
    _inspectionDate = TextEditingController(
      text: d.inspectionDate.isEmpty ? d.appraisalDate : d.inspectionDate,
    );
    _clientIdDoc = TextEditingController(text: d.clientIdDoc);

    _buildingType = TextEditingController(text: d.buildingType);
    _wallMaterial = TextEditingController(text: d.wallMaterial);
    _buildingCondition = TextEditingController(text: d.buildingCondition);
    _communications = TextEditingController(text: d.communications);
    _livingArea = TextEditingController(text: d.livingArea);
    _kitchenArea = TextEditingController(text: d.kitchenArea);
    _bathroom = TextEditingController(text: d.bathroom);
    _balcony = TextEditingController(text: d.balcony);
    _renovationYear = TextEditingController(text: d.renovationYear);
    _layout = TextEditingController(text: d.layout);

    for (final k in _carKeys) {
      _car[k]!.text = d.vehicleSpecs[k] ?? '';
    }

    _propertyType = _propertyTypes.contains(d.propertyType)
        ? d.propertyType
        : (d.propertyType.isNotEmpty ? d.propertyType : 'Квартира');
    _appraisalDate = _parseDate(d.appraisalDate) ?? DateTime.now();

    _photoUrls = List.from(widget.initialPhotoUrls);
    for (final c in d.comparables) {
      _comparables.add(_ComparableEdit.from(c));
    }

    // Закешировать signed-URL для миниатюр фото.
    for (final p in _photoUrls) {
      _loadPhotoUrl(p);
    }
  }

  Future<void> _loadPhotoUrl(String path) async {
    try {
      final url = await SupabaseService.getDocumentUrl(path);
      if (mounted) {
        setState(() => _photoSignedUrls[path] = url);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _clientName.dispose();
    _clientIin.dispose();
    _address.dispose();
    _area.dispose();
    _rooms.dispose();
    _floor.dispose();
    _totalFloors.dispose();
    _condition.dispose();
    _yearBuilt.dispose();
    _cadastralNumber.dispose();
    _purpose.dispose();
    _estimatedPrice.dispose();
    _priceRangeLow.dispose();
    _priceRangeHigh.dispose();
    _reportNumber.dispose();
    _appraisalDateController.dispose();
    _inspectionDate.dispose();
    _clientIdDoc.dispose();
    _buildingType.dispose();
    _wallMaterial.dispose();
    _buildingCondition.dispose();
    _communications.dispose();
    _livingArea.dispose();
    _kitchenArea.dispose();
    _bathroom.dispose();
    _balcony.dispose();
    _renovationYear.dispose();
    _layout.dispose();
    for (final c in _car.values) {
      c.dispose();
    }
    for (final c in _comparables) {
      c.dispose();
    }
    super.dispose();
  }

  static String _fmtNum(double v) =>
      v == v.roundToDouble() ? '${v.round()}' : '$v';

  static String _fmtDate(DateTime d) => DateFormat('dd.MM.yyyy').format(d);

  static DateTime? _parseDate(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    return DateFormat('dd.MM.yyyy').tryParse(t) ??
        DateTime.tryParse(t);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _appraisalDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _appraisalDate = picked;
        _appraisalDateController.text = _fmtDate(picked);
      });
    }
  }

  Future<void> _save() async {
    final c = AppColors.of(context);
    String? err;

    final clientName = _clientName.text.trim();
    final clientIin = _clientIin.text.trim();
    final address = _address.text.trim();
    final area = _parseDouble(_area.text);
    final rooms = int.tryParse(_rooms.text.trim());
    final floor = int.tryParse(_floor.text.trim());
    final totalFloors = int.tryParse(_totalFloors.text.trim());
    final condition = _condition.text.trim();
    final yearBuilt = int.tryParse(_yearBuilt.text.trim());
    final estimatedPrice = int.tryParse(_estimatedPrice.text.replaceAll(' ', '').trim());
    final priceRangeLow = int.tryParse(_priceRangeLow.text.replaceAll(' ', '').trim());
    final priceRangeHigh = int.tryParse(_priceRangeHigh.text.replaceAll(' ', '').trim());
    final reportNumber = _reportNumber.text.trim();

    if (clientName.isEmpty) err = 'Укажите заказчика (ФИО)';
    if (err == null && address.isEmpty) err = 'Укажите адрес объекта';
    if (err == null && (area == null || area <= 0)) err = 'Укажите площадь (м²)';
    if (err == null && estimatedPrice == null) {
      err = 'Укажите итоговую стоимость';
    } else if (err == null && estimatedPrice != null && estimatedPrice <= 0) {
      err = 'Итоговая стоимость должна быть больше нуля';
    }
    if (err == null && (priceRangeLow == null || priceRangeHigh == null)) {
      err = 'Укажите диапазон стоимости (нижнюю и верхнюю границу)';
    }
    if (err == null && priceRangeLow != null && priceRangeHigh != null) {
      if (priceRangeLow > priceRangeHigh) {
        err = 'Нижняя граница диапазона больше верхней';
      }
    }

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err, style: const TextStyle(color: Colors.white)),
          backgroundColor: c.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final d = widget.data;

    // Аналоги из редактора (со ссылками).
    final comparables = <ComparableProperty>[];
    for (final c in _comparables) {
      final area = _parseDouble(c.area.text);
      final price = _parseDouble(c.price.text);
      if (area == null || price == null || c.address.text.trim().isEmpty) continue;
      comparables.add(ComparableProperty(
        address: c.address.text.trim(),
        area: area,
        price: price,
        type: _propertyType,
        source: c.source.text.trim().isEmpty ? 'krisha.kz' : c.source.text.trim(),
        url: c.url.text.trim(),
      ));
    }

    // Авто-характеристики.
    final vehicleSpecs = <String, String>{};
    if (_isCar(_propertyType)) {
      for (final k in _carKeys) {
        final v = _car[k]!.text.trim();
        if (v.isNotEmpty) vehicleSpecs[k] = v;
      }
    }

    final edited = ReportData(
      clientName: clientName,
      clientIin: clientIin,
      clientIsOrg: d.clientIsOrg,
      clientAddress: d.clientAddress,
      propertyType: _propertyType,
      address: address,
      area: area!,
      rooms: rooms ?? 0,
      floor: floor ?? 0,
      totalFloors: totalFloors ?? 0,
      condition: condition.isEmpty ? 'Не указано' : condition,
      yearBuilt: yearBuilt ?? 0,
      cadastralNumber: _cadastralNumber.text.trim(),
      purpose: _purpose.text.trim().isEmpty ? 'Проживание' : _purpose.text.trim(),
      buildingType: _buildingType.text.trim(),
      wallMaterial: _wallMaterial.text.trim(),
      buildingCondition: _buildingCondition.text.trim(),
      communications: _communications.text.trim(),
      livingArea: _livingArea.text.trim(),
      kitchenArea: _kitchenArea.text.trim(),
      bathroom: _bathroom.text.trim(),
      balcony: _balcony.text.trim(),
      renovationYear: _renovationYear.text.trim(),
      layout: _layout.text.trim(),
      vehicleSpecs: vehicleSpecs,
      photoUrls: List.from(_photoUrls),
      inspectionDate: _inspectionDate.text.trim(),
      clientIdDoc: _clientIdDoc.text.trim(),
      estimatedPrice: estimatedPrice!.toDouble(),
      priceRangeLow: priceRangeLow!.toDouble(),
      priceRangeHigh: priceRangeHigh!.toDouble(),
      pricePerMeter: area > 0 ? estimatedPrice / area : d.pricePerMeter,
      confidence: d.confidence,
      comparables: comparables,
      recommendations: d.recommendations,
      appraisalDate: DateFormat('dd.MM.yyyy').format(_appraisalDate),
      reportNumber: reportNumber,
      appraiserName: d.appraiserName,
      appraiserIin: d.appraiserIin,
      appraiserCertificate: d.appraiserCertificate,
      appraiserPalata: d.appraiserPalata,
      appraiserInsurance: d.appraiserInsurance,
      legalEntityName: d.legalEntityName,
      legalEntityAddress: d.legalEntityAddress,
      legalEntityBin: d.legalEntityBin,
      legalEntityIik: d.legalEntityIik,
      legalEntityBik: d.legalEntityBik,
      legalEntityBank: d.legalEntityBank,
      legalEntityKbe: d.legalEntityKbe,
      legalEntityPhone: d.legalEntityPhone,
    );
    Navigator.pop(context, edited);

    // Сохранить список фото в заявке (пути обновляются в БД).
    final appId = widget.applicationId;
    if (appId != null && appId.isNotEmpty && _photoUrls.isNotEmpty) {
      try {
        await SupabaseService.updateApplicationPhotos(appId, _photoUrls);
      } catch (e) {
        debugPrint('[Edit] updateApplicationPhotos error: $e');
      }
    }
  }

  // ============================================
  // ФОТО (до 10): добавить / удалить
  // ============================================

  Future<void> _addPhoto() async {
    if (_photoUrls.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Максимум 10 фотографий')),
      );
      return;
    }
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    try {
      final path = await SupabaseService.uploadReportPhoto(
        bytes: bytes,
        applicationId: widget.applicationId ?? 'draft',
        index: _photoUrls.length,
      );
      if (!mounted) return;
      setState(() {
        _photoUrls.add(path);
        _photoSignedUrls[path] = 'loading';
      });
      _loadPhotoUrl(path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось загрузить фото: $e')),
      );
    }
  }

  void _removePhoto(String path) {
    setState(() {
      _photoUrls.remove(path);
      _photoSignedUrls.remove(path);
    });
    // Физически удалить файл из storage (не критично при ошибке).
    try {
      SupabaseService.deleteStorageFile(path);
    } catch (_) {}
  }

  // ============================================
  // АНАЛОГИ
  // ============================================

  void _addComparable() {
    setState(() => _comparables.add(_ComparableEdit.empty()));
  }

  void _removeComparable(int index) {
    setState(() {
      _comparables.removeAt(index).dispose();
    });
  }

  static double? _parseDouble(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Редактирование отчёта',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                children: [
                  _sectionTitle(c, 'ЗАКАЗЧИК'),
                  const SizedBox(height: 10),
                  _buildField(
                    controller: _clientName,
                    label: 'Заказчик (ФИО)',
                    icon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _clientIin,
                    label: 'ИИН / БИН',
                    icon: Icons.badge_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle(c, 'ОБЪЕКТ ОЦЕНКИ'),
                  const SizedBox(height: 10),
                  _buildDropdown(c),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _address,
                    label: 'Адрес объекта',
                    icon: Icons.location_on_rounded,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          controller: _area,
                          label: 'Площадь (м²)',
                          icon: Icons.square_foot_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(
                          controller: _rooms,
                          label: 'Комнаты',
                          icon: Icons.meeting_room_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          controller: _floor,
                          label: 'Этаж',
                          icon: Icons.layers_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(
                          controller: _totalFloors,
                          label: 'Этажей',
                          icon: Icons.apartment_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _condition,
                    label: 'Состояние / отделка',
                    icon: Icons.home_repair_service_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _yearBuilt,
                    label: 'Год постройки',
                    icon: Icons.calendar_month_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _cadastralNumber,
                    label: 'Кадастровый номер',
                    icon: Icons.tag_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _purpose,
                    label: 'Назначение',
                    icon: Icons.home_work_rounded,
                  ),
                  if (!_isCar(_propertyType)) ...[
                    const SizedBox(height: 20),
                    _sectionTitle(c, 'ХАРАКТЕРИСТИКИ'),
                    const SizedBox(height: 10),
                    _buildField(
                      controller: _buildingType,
                      label: 'Тип здания',
                      icon: Icons.apartment_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _wallMaterial,
                      label: 'Материал стен',
                      icon: Icons.architecture_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _buildingCondition,
                      label: 'Тех. состояние здания',
                      icon: Icons.handyman_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _communications,
                      label: 'Коммуникации',
                      icon: Icons.electrical_services_rounded,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            controller: _livingArea,
                            label: 'Жилая площадь',
                            icon: Icons.bed_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            controller: _kitchenArea,
                            label: 'Кухня',
                            icon: Icons.kitchen_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            controller: _bathroom,
                            label: 'Санузел',
                            icon: Icons.shower_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            controller: _balcony,
                            label: 'Балкон',
                            icon: Icons.window_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            controller: _renovationYear,
                            label: 'Год ремонта',
                            icon: Icons.construction_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            controller: _layout,
                            label: 'Планировка',
                            icon: Icons.dashboard_customize_rounded,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 20),
                    _sectionTitle(c, 'АВТОМОБИЛЬ'),
                    const SizedBox(height: 10),
                    for (final k in _carKeys) ...[
                      _buildField(
                        controller: _car[k]!,
                        label: _carLabels[k]!,
                        icon: Icons.directions_car_rounded,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                  const SizedBox(height: 20),
                  _sectionTitle(c, 'ОСМОТР И ДОКУМЕНТЫ'),
                  const SizedBox(height: 10),
                  _buildField(
                    controller: _inspectionDate,
                    label: 'Дата осмотра',
                    icon: Icons.visibility_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _clientIdDoc,
                    label: 'Удостоверение заказчика',
                    icon: Icons.badge_rounded,
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle(c, 'ФОТО ОБЪЕКТА (до 10)'),
                  const SizedBox(height: 10),
                  _buildPhotosGrid(c),
                  const SizedBox(height: 20),
                  _sectionTitle(c, 'АНАЛОГИ (ссылки на объявления)'),
                  const SizedBox(height: 10),
                  for (var i = 0; i < _comparables.length; i++) ...[
                    _buildComparableCard(c, i),
                    const SizedBox(height: 12),
                  ],
                  if (_comparables.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Аналоги пока не добавлены — добавьте минимум 3',
                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                      ),
                    ),
                  OptionButton(
                    text: 'Добавить аналог',
                    icon: Icons.add_rounded,
                    onTap: _addComparable,
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle(c, 'СТОИМОСТЬ'),
                  const SizedBox(height: 10),
                  _buildField(
                    controller: _estimatedPrice,
                    label: 'Итоговая стоимость, ₸',
                    icon: Icons.payments_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          controller: _priceRangeLow,
                          label: 'Мин., ₸',
                          icon: Icons.trending_down_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(
                          controller: _priceRangeHigh,
                          label: 'Макс., ₸',
                          icon: Icons.trending_up_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle(c, 'ОФОРМЛЕНИЕ'),
                  const SizedBox(height: 10),
                  _buildDateField(c),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _reportNumber,
                    label: 'Номер отчёта',
                    icon: Icons.numbers_rounded,
                  ),
                  const SizedBox(height: 24),
                  OptionButton(
                    text: 'Сохранить изменения',
                    icon: Icons.check_rounded,
                    onTap: _save,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'После сохранения отчёт перегенерируется с этими данными. '
                    'Аналоги и рекомендации ИИ сохранятся.',
                    style: TextStyle(fontSize: 12, color: c.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosGrid(AppColors c) {
    if (_photoUrls.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          'Фото из заявки появятся здесь автоматически. Можно добавить свои.',
          style: TextStyle(fontSize: 12, color: c.textSecondary),
        ),
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final path in _photoUrls)
          _photoThumb(c, path),
        if (_photoUrls.length < 10)
          InkWell(
            onTap: _addPhoto,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.border, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.add_a_photo_rounded, color: c.textSecondary),
            ),
          ),
      ],
    );
  }

  Widget _photoThumb(AppColors c, String path) {
    final url = _photoSignedUrls[path];
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: url == null || url == 'loading'
              ? Container(
                  width: 92,
                  height: 92,
                  color: c.surfaceLight,
                  child: const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : Image.network(
                  url,
                  width: 92,
                  height: 92,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 92,
                    height: 92,
                    color: c.surfaceLight,
                    child: Icon(Icons.broken_image_rounded, color: c.textSecondary),
                  ),
                ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removePhoto(path),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComparableCard(AppColors c, int index) {
    final item = _comparables[index];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Аналог ${index + 1}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _removeComparable(index),
                child: Icon(Icons.delete_outline_rounded,
                    size: 20, color: c.error),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: item.address,
            style: TextStyle(fontSize: 14, color: c.textPrimary),
            decoration: _decoration(c, 'Адрес аналога', Icons.location_on_rounded),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: item.area,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: 14, color: c.textPrimary),
                  decoration: _decoration(c, 'Площадь, м²', Icons.square_foot_rounded),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: item.price,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: 14, color: c.textPrimary),
                  decoration: _decoration(c, 'Цена, ₸', Icons.payments_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: item.source,
            style: TextStyle(fontSize: 14, color: c.textPrimary),
            decoration: _decoration(c, 'Источник', Icons.storefront_rounded),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: item.url,
            keyboardType: TextInputType.url,
            style: TextStyle(fontSize: 14, color: c.textPrimary),
            decoration: _decoration(c, 'Ссылка на объявление', Icons.link_rounded),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(AppColors c, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: c.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildDropdown(AppColors c) {
    final options = _propertyTypes.contains(_propertyType)
        ? _propertyTypes
        : [_propertyType, ..._propertyTypes];
    return DropdownButtonFormField<String>(
      initialValue: _propertyType,
      decoration: _decoration(c, 'Тип объекта', Icons.home_rounded),
      dropdownColor: c.surface,
      style: TextStyle(fontSize: 15, color: c.textPrimary),
      items: [
        for (final t in options)
          DropdownMenuItem(value: t, child: Text(t)),
      ],
      onChanged: (v) {
        if (v != null) setState(() => _propertyType = v);
      },
    );
  }

  Widget _buildDateField(AppColors c) {
    return GestureDetector(
      onTap: _pickDate,
      child: AbsorbPointer(
        child: TextField(
          controller: _appraisalDateController,
          decoration: _decoration(c, 'Дата оценки', Icons.event_rounded),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    final c = AppColors.of(context);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      style: TextStyle(fontSize: 15, color: c.textPrimary),
      decoration: _decoration(c, label, icon),
    );
  }

  InputDecoration _decoration(AppColors c, String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 14, color: c.textSecondary),
      prefixIcon: Icon(icon, size: 20, color: c.textSecondary),
      filled: true,
      fillColor: c.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.accent, width: 1.5),
      ),
    );
  }
}

/// Редактируемая карточка аналога (адрес, площадь, цена, источник, ссылка).
class _ComparableEdit {
  final TextEditingController address;
  final TextEditingController area;
  final TextEditingController price;
  final TextEditingController source;
  final TextEditingController url;

  _ComparableEdit({
    required this.address,
    required this.area,
    required this.price,
    required this.source,
    required this.url,
  });

  factory _ComparableEdit.from(ComparableProperty c) => _ComparableEdit(
        address: TextEditingController(text: c.address),
        area: TextEditingController(text: '${c.area}'),
        price: TextEditingController(text: '${c.price.round()}'),
        source: TextEditingController(text: c.source),
        url: TextEditingController(text: c.url),
      );

  factory _ComparableEdit.empty() => _ComparableEdit(
        address: TextEditingController(),
        area: TextEditingController(),
        price: TextEditingController(),
        source: TextEditingController(text: 'krisha.kz'),
        url: TextEditingController(),
      );

  void dispose() {
    address.dispose();
    area.dispose();
    price.dispose();
    source.dispose();
    url.dispose();
  }
}

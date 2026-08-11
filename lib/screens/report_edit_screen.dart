import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/report_template.dart';
import '../theme/app_colors.dart';
import '../widgets/option_button.dart';

/// Экран редактирования отчёта оценщиком перед подписанием.
///
/// Оценщик может поправить ключевые данные отчёта (заказчик, объект,
/// итоговая стоимость, дата, номер), сгенерированные ИИ, — после чего
/// отчёт перегенерируется с учётом правок.
class ReportEditScreen extends StatefulWidget {
  final ReportData data;

  const ReportEditScreen({super.key, required this.data});

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

  late String _propertyType;
  late DateTime _appraisalDate;

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
    _propertyType = _propertyTypes.contains(d.propertyType)
        ? d.propertyType
        : (d.propertyType.isNotEmpty ? d.propertyType : 'Квартира');
    _appraisalDate = _parseDate(d.appraisalDate) ?? DateTime.now();
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

  void _save() {
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
      estimatedPrice: estimatedPrice!.toDouble(),
      priceRangeLow: priceRangeLow!.toDouble(),
      priceRangeHigh: priceRangeHigh!.toDouble(),
      pricePerMeter: area > 0 ? estimatedPrice / area : d.pricePerMeter,
      confidence: d.confidence,
      comparables: d.comparables,
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

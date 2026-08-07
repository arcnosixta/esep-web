import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../navigation/app_navigator.dart';
import 'ai_chat_screen.dart';

class NewApplicationScreen extends StatefulWidget {
  const NewApplicationScreen({super.key});

  @override
  State<NewApplicationScreen> createState() => _NewApplicationScreenState();
}

class _NewApplicationScreenState extends State<NewApplicationScreen> {
  int _selectedType = 0;
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _roomsController = TextEditingController();
  final _floorController = TextEditingController();
  final _totalFloorsController = TextEditingController();
  String _selectedCondition = 'Косметический ремонт';

  @override
  void dispose() {
    _addressController.dispose();
    _areaController.dispose();
    _roomsController.dispose();
    _floorController.dispose();
    _totalFloorsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final address = _addressController.text.trim();
    final areaText = _areaController.text.trim();

    if (address.isEmpty) {
      _showError('Введите адрес объекта');
      return;
    }
    if (areaText.isEmpty) {
      _showError('Введите площадь');
      return;
    }

    final area = double.tryParse(areaText);
    if (area == null || area <= 0) {
      _showError('Введите корректную площадь');
      return;
    }

    // Заявка не создаётся: это предварительный расчёт. Официальный
    // документ пользователь получает через ИИ-анализ (вкладка ИИ).
    _showEstimate(area: area);
  }

  /// Базовая цена за м² по типу недвижимости (тенге, ориентир рынка РК).
  int _basePricePerM2() {
    return switch (PropertyType.values[_selectedType]) {
      PropertyType.apartment => 480000,
      PropertyType.house => 380000,
      PropertyType.land => 60000,
      PropertyType.commercial => 620000,
    };
  }

  /// Коэффициент состояния/ремонта.
  double _conditionFactor() {
    return switch (_selectedCondition) {
      'Без ремонта' => 0.85,
      'Косметический ремонт' => 1.0,
      'Капитальный ремонт' => 1.12,
      'Дизайнерский ремонт' => 1.25,
      'Евро ремонт' => 1.15,
      _ => 1.0,
    };
  }

  /// Примеры рыночных цен по типу (ориентир, из открытых источников).
  List<String> _marketExamples() {
    return switch (PropertyType.values[_selectedType]) {
      PropertyType.apartment => [
          '1-комн. квартира 40 м², Алматы — 16–20 млн ₸',
          '3-комн. квартира 80 м², Астана — 28–38 млн ₸',
          '2-комн. квартира 55 м², Алматы — 24–30 млн ₸',
        ],
      PropertyType.house => [
          'Дом 120 м², Алматы (пригород) — 40–55 млн ₸',
          'Дом 200 м², Астана — 65–90 млн ₸',
          'Дом 90 м², Шымкент — 25–35 млн ₸',
        ],
      PropertyType.land => [
          'Участок 10 соток, Алматинская обл. — 8–15 млн ₸',
          'Участок 6 соток, Астана — 12–20 млн ₸',
          'Участок 15 соток, Шымкент — 9–14 млн ₸',
        ],
      PropertyType.commercial => [
          'Помещение 60 м², Алматы (1 этаж) — 35–50 млн ₸',
          'Офис 80 м², Астана — 40–60 млн ₸',
          'Магазин 45 м², Шымкент — 25–35 млн ₸',
        ],
    };
  }

  /// Диапазон предварительной стоимости: ±15% от расчётной середины.
  ({int min, int max}) _estimateRange(double area) {
    final base = _basePricePerM2() * _conditionFactor() * area;
    final mid = base;
    final min = (mid * 0.85 / 10000).round() * 10000;
    final max = (mid * 1.15 / 10000).round() * 10000;
    return (min: min, max: max);
  }

  void _showEstimate({required double area}) {
    final range = _estimateRange(area);
    final type = PropertyType.values[_selectedType].label;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final sc = AppColors.of(sheetCtx);
        return Container(
          decoration: BoxDecoration(
            color: sc.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 12,
            bottom: MediaQuery.of(sheetCtx).viewPadding.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: sc.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Предварительная оценка',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: sc.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ориентир для $type · ${formatTenge(range.min)} – ${formatTenge(range.max)}',
                  style: TextStyle(fontSize: 13, color: sc.textSecondary),
                ),
                const SizedBox(height: 20),
                _estimateCard(sc, range),
                const SizedBox(height: 16),
                Text(
                  'Примеры с рынка (открытые источники):',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: sc.textSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 10),
                ..._marketExamples().map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.circle, size: 5, color: sc.textHint),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e,
                            style: TextStyle(
                              fontSize: 13,
                              color: sc.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: sc.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sc.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 18, color: sc.warning),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Это предварительный расчёт, а не официальный документ. '
                          'Для получения официального отчёта заполните все данные '
                          'во вкладке ИИ и следуйте инструкциям ИИ.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: sc.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: sc.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      AppNavigator.push(context, const AiChatScreen());
                    },
                    child: const Text(
                      'Перейти к ИИ-анализу',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    child: Text(
                      'Закрыть',
                      style: TextStyle(fontSize: 14, color: sc.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _estimateCard(
    AppColors sc,
    ({int min, int max}) range,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [sc.accent.withValues(alpha: 0.12), sc.surfaceLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sc.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Примерная стоимость',
            style: TextStyle(fontSize: 13, color: sc.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '${formatTenge(range.min)} – ${formatTenge(range.max)}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: sc.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '±15% · без учёта документов, осмотра и страховки',
            style: TextStyle(fontSize: 12, color: sc.textHint),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    final c = AppColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: c.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      'Расчёт стоимости',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Тип недвижимости',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.6,
                      ),
                      itemCount: PropertyType.values.length,
                      itemBuilder: (context, index) {
                        final type = PropertyType.values[index];
                        final selected = _selectedType == index;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedType = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: selected
                                  ? c.accent.withValues(alpha: 0.08)
                                  : c.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? c.accent
                                    : c.border,
                                width: 1,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: c.accent
                                            .withValues(alpha: 0.1),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  type.icon,
                                  color: selected
                                      ? c.accent
                                      : c.textSecondary,
                                  size: 22,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  type.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? c.accent
                                        : c.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.border, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Данные объекта',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: c.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        context,
                        'Адрес объекта',
                        controller: _addressController,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              context,
                              'Площадь (м²)',
                              controller: _areaController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              context,
                              'Комнаты',
                              controller: _roomsController,
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
                              context,
                              'Этаж',
                              controller: _floorController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              context,
                              'Всего этажей',
                              controller: _totalFloorsController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Состояние / Ремонт',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: c.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: c.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.border, width: 1),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCondition,
                            isExpanded: true,
                            dropdownColor: c.surface,
                            style: TextStyle(color: c.textPrimary, fontSize: 14),
                            items: [
                              'Без ремонта',
                              'Косметический ремонт',
                              'Капитальный ремонт',
                              'Дизайнерский ремонт',
                              'Евро ремонт',
                            ].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() => _selectedCondition = newValue);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.info.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 18, color: c.info),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Здесь вы получите только предварительную оценку — '
                          'это не официальный документ. Для официального отчёта '
                          'перейдите во вкладку ИИ, заполните все данные и '
                          'следуйте инструкциям.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: GestureDetector(
                  onTap: _submit,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: c.accent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: c.accent.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Рассчитать стоимость',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    BuildContext context,
    String hint, {
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final c = AppColors.of(context);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        color: c.textPrimary,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: c.textHint,
          fontSize: 14,
        ),
        filled: true,
        fillColor: c.surfaceLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
      ),
    );
  }
}

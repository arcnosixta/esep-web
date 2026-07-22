import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/border_icon.dart';
import '../services/supabase_service.dart';

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
  bool _loading = false;

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
    final roomsText = _roomsController.text.trim();
    final floorText = _floorController.text.trim();
    final totalFloorsText = _totalFloorsController.text.trim();

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

    setState(() => _loading = true);

    try {
      final property = await SupabaseService.addProperty(
        type: PropertyType.values[_selectedType].dbType,
        address: address,
        area: area,
        rooms: int.tryParse(roomsText),
        floor: int.tryParse(floorText),
        totalFloors: int.tryParse(totalFloorsText),
      );

      await SupabaseService.createApplication(
        propertyId: property['id'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Заявка создана! AI-ассистент начнёт диалог',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _showError('Ошибка: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── White strip: title ──
              Container(
                width: double.infinity,
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'НОВАЯ ЗАЯВКА',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Paper strip: property type grid ──
              Container(
                width: double.infinity,
                color: AppColors.paper,
                padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ТИП НЕДВИЖИМОСТИ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.6,
                      ),
                      itemCount: PropertyType.values.length,
                      itemBuilder: (context, index) {
                        final type = PropertyType.values[index];
                        final selected = _selectedType == index;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedType = index),
                          child: BorderIcon(
                            backgroundColor: selected
                                ? AppColors.accent.withValues(alpha: 0.08)
                                : AppColors.surface,
                            borderColor: selected
                                ? AppColors.accent
                                : AppColors.border,
                            borderRadius: 12,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  type.icon,
                                  color: selected
                                      ? AppColors.accent
                                      : AppColors.textSecondary,
                                  size: 22,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  type.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? AppColors.accent
                                        : AppColors.textPrimary,
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

              // ── White strip: object data ──
              Container(
                width: double.infinity,
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(24, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ДАННЫЕ ОБЪЕКТА',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      'Адрес объекта',
                      controller: _addressController,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            'Площадь (м²)',
                            controller: _areaController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildField(
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
                            'Этаж',
                            controller: _floorController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildField(
                            'Всего этажей',
                            controller: _totalFloorsController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Paper strip: AI helper note ──
              Container(
                width: double.infinity,
                color: AppColors.paper,
                padding: const EdgeInsets.fromLTRB(24, 18, 20, 18),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: AppColors.accent.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'ИИ-ассистент поможет после создания',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Muted strip: submit button ──
              Container(
                width: double.infinity,
                color: AppColors.muted,
                padding: const EdgeInsets.fromLTRB(24, 18, 20, 18),
                child: GestureDetector(
                  onTap: _loading ? null : _submit,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _loading
                          ? AppColors.accent.withValues(alpha: 0.5)
                          : AppColors.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'СОЗДАТЬ ЗАЯВКУ',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String hint, {
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
    );
  }
}

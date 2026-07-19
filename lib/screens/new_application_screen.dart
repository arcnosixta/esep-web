import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_button.dart';

class _PropertyType {
  final String label;
  final IconData icon;
  final Color color;

  const _PropertyType(this.label, this.icon, this.color);
}

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
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  static const _types = [
    _PropertyType('Квартира', Icons.apartment_rounded, Color(0xFF7C5CFC)),
    _PropertyType('Дом', Icons.home_rounded, Color(0xFF38BDF8)),
    _PropertyType('Участок', Icons.landscape_rounded, Color(0xFF2DD4A8)),
    _PropertyType('Коммерческая', Icons.business_rounded, Color(0xFFFBBF24)),
  ];

  @override
  void dispose() {
    _addressController.dispose();
    _areaController.dispose();
    _roomsController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новая заявка'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Тип недвижимости',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
              ),
              itemCount: _types.length,
              itemBuilder: (context, index) {
                final type = _types[index];
                final selected = _selectedType == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected
                          ? type.color.withValues(alpha: 0.1)
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected ? type.color : AppColors.border,
                        width: selected ? 1.5 : 0.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: type.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(type.icon, color: type.color, size: 20),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          type.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? type.color
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 28),
            const Text(
              'Данные объекта',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            _buildField('Адрес объекта', Icons.location_on_outlined,
                controller: _addressController),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildField('Площадь (м²)', Icons.straighten_rounded,
                      controller: _areaController,
                      keyboardType: TextInputType.number),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField('Комнаты', Icons.meeting_room_outlined,
                      controller: _roomsController,
                      keyboardType: TextInputType.number),
                ),
              ],
            ),

            const SizedBox(height: 28),
            const Text(
              'Контакты',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            _buildField('Ваше имя', Icons.person_outline_rounded,
                controller: _nameController),
            const SizedBox(height: 14),
            _buildField('Телефон', Icons.phone_outlined,
                controller: _phoneController,
                keyboardType: TextInputType.phone),

            const SizedBox(height: 28),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.smart_toy_rounded,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ИИ-ассистент поможет',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'После создания заявки AI начнёт диалог и уточнит детали',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Создать заявку',
              icon: Icons.add_location_alt_rounded,
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Заявка создана! AI-ассистент начнёт диалог',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: AppColors.accent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String hint,
    IconData icon, {
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_button.dart';

class _UploadedFile {
  final String name;
  final String size;
  final String type;

  const _UploadedFile({
    required this.name,
    required this.size,
    required this.type,
  });
}

class DocumentUploadScreen extends StatelessWidget {
  const DocumentUploadScreen({super.key});

  static final List<_UploadedFile> _files = const [
    _UploadedFile(name: 'свидетельство.pdf', size: '2.4 MB', type: 'pdf'),
    _UploadedFile(name: 'фото_квартиры.jpg', size: '5.1 MB', type: 'jpg'),
    _UploadedFile(name: 'план_этажа.png', size: '1.2 MB', type: 'png'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Документы',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Загрузите документы для оценки',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Upload zone
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.cloud_upload_rounded,
                            size: 28,
                            color: AppColors.accent.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Перетащите файлы сюда',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'или нажмите для выбора',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textHint,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: ['JPG', 'PNG', 'PDF'].map((type) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                type,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textHint,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Files header
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Загруженные файлы',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${_files.length} файлов',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Files
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  List.generate(_files.length, (i) {
                    final file = _files[i];
                    return GlassCard(
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _fileColor(file.type).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _fileIcon(file.type),
                              color: _fileColor(file.type),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  file.size,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: AppColors.error,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverToBoxAdapter(
                child: PrimaryButton(
                  label: 'Продолжить',
                  onPressed: () {},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _fileColor(String type) => switch (type) {
        'pdf' => const Color(0xFFEF4444),
        'jpg' => const Color(0xFF38BDF8),
        'png' => const Color(0xFF2DD4A8),
        _ => AppColors.textSecondary,
      };

  IconData _fileIcon(String type) => switch (type) {
        'pdf' => Icons.picture_as_pdf_rounded,
        'jpg' => Icons.photo_rounded,
        'png' => Icons.image_rounded,
        _ => Icons.insert_drive_file_rounded,
      };
}

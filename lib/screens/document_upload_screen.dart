import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/gradient_button.dart';

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

  static final List<_UploadedFile> _files = [
    const _UploadedFile(name: 'свидетельство.pdf', size: '2.4 MB', type: 'pdf'),
    const _UploadedFile(name: 'фото_квартиры.jpg', size: '5.1 MB', type: 'jpg'),
    const _UploadedFile(name: 'план_этажа.png', size: '1.2 MB', type: 'png'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Документы'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upload zone
            GestureDetector(
              onTap: () {
                // TODO: Pick files
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 48),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.cloud_upload_rounded,
                        size: 32,
                        color: AppColors.accent.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Перетащите файлы сюда',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'или нажмите для выбора',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: ['JPG', 'PNG', 'PDF'].map((type) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
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
            const SizedBox(height: 28),
            // Uploaded files header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Загруженные файлы',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
            const SizedBox(height: 16),
            // File list
            ...List.generate(_files.length, (i) {
              final file = _files[i];
              return AppCard(
                child: Row(
                  children: [
                    // File icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _fileColor(file.type).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _fileIcon(file.type),
                        color: _fileColor(file.type),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Info
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
                    // Delete
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: AppColors.error,
                      ),
                      onPressed: () {
                        // TODO: Delete file
                      },
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            GradientButton(
              label: 'Продолжить',
              onPressed: () {
                // TODO: Continue
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _fileColor(String type) => switch (type) {
        'pdf' => const Color(0xFFEF4444),
        'jpg' => const Color(0xFF3B82F6),
        'png' => const Color(0xFF22C55E),
        _ => AppColors.textSecondary,
      };

  IconData _fileIcon(String type) => switch (type) {
        'pdf' => Icons.picture_as_pdf_rounded,
        'jpg' => Icons.photo_rounded,
        'png' => Icons.image_rounded,
        _ => Icons.insert_drive_file_rounded,
      };
}

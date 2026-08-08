import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../widgets/animated_count.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  List<Map<String, dynamic>> _documents = [];
  bool _loading = true;
  bool _uploading = false;
  bool _hovered = false;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _loading = true);
    try {
      final docs = await SupabaseService.getDocuments();
      if (mounted) setState(() => _documents = docs);
    } catch (e) {
      if (mounted) setState(() => _documents = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() {
        _uploading = true;
        _uploadError = null;
      });

      for (final file in result.files) {
        final Uint8List bytes;
        if (file.bytes != null) {
          bytes = file.bytes!;
        } else if (file.path != null) {
          bytes = await file.xFile.readAsBytes();
        } else {
          continue;
        }
        try {
          await SupabaseService.uploadDocument(fileName: file.name, bytes: bytes);
        } catch (e) {
          _uploadError = 'Ошибка загрузки ${file.name}: $e';
        }
      }

      await _loadDocuments();
    } catch (e) {
      if (mounted) {
        setState(() => _uploadError = 'Не удалось выбрать файлы');
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deleteDocument(Map<String, dynamic> doc) async {
    final c = AppColors.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Удалить документ?'),
        content: Text('«${doc['name']}» будет удалён навсегда.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Удалить', style: TextStyle(color: c.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await SupabaseService.deleteDocument(
        doc['id'].toString(),
        filePath: doc['file_url']?.toString(),
      );
      await _loadDocuments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка удаления')),
        );
      }
    }
  }

  Future<void> _openDocument(Map<String, dynamic> doc) async {
    final filePath = doc['file_url']?.toString();
    if (filePath == null || filePath.isEmpty) return;

    final String url;
    try {
      url = await SupabaseService.getDocumentUrl(filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка открытия документа: $e')),
        );
      }
      return;
    }
    final fileType = (doc['file_type'] ?? '').toString().toLowerCase();

    if (fileType == 'jpg' || fileType == 'jpeg' || fileType == 'png') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _DocumentPreviewScreen(
            imageUrl: url,
            title: doc['name'] ?? '',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Открытие ${doc['name']}...')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDocuments,
          color: c.accent,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Документы',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08),
                      const SizedBox(height: 6),
                      _documents.isEmpty
                          ? Text(
                              'Загрузите документы — ИИ учтёт их при оценке',
                              style: TextStyle(
                                fontSize: 14,
                                color: c.textSecondary,
                              ),
                            ).animate(delay: 100.ms).fadeIn(duration: 350.ms)
                          : Row(
                              children: [
                                AnimatedCountText(
                                  _documents.length,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: c.accent,
                                  ),
                                ),
                                Text(
                                  ' файл(ов) загружено',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: c.textSecondary,
                                  ),
                                ),
                              ],
                            ).animate(delay: 100.ms).fadeIn(duration: 350.ms),
                      const SizedBox(height: 14),
                      // Чип: ИИ учитывает документы при оценке.
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: c.accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: c.accent.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 15,
                              color: c.accent,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'ИИ учитывает документы при оценке',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: c.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate(delay: 200.ms)
                          .fadeIn(duration: 400.ms)
                          .slideX(begin: -0.08),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: MouseRegion(
                    cursor: _uploading
                        ? SystemMouseCursors.wait
                        : SystemMouseCursors.click,
                    onEnter: (_) => setState(() => _hovered = true),
                    onExit: (_) => setState(() => _hovered = false),
                    child: GestureDetector(
                      onTap: _uploading ? null : _pickAndUpload,
                      child: AnimatedScale(
                        scale: _hovered && !_uploading ? 1.02 : 1.0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        decoration: BoxDecoration(
                          color: _uploading
                              ? c.accent.withValues(alpha: 0.04)
                              : c.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _uploading
                                ? c.accent.withValues(alpha: 0.3)
                                : c.accent.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            if (_uploading)
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: c.accent,
                                ),
                              )
                            else
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: c.accent.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.cloud_upload_rounded,
                                  size: 28,
                                  color: c.accent,
                                ),
                              ),
                            const SizedBox(height: 14),
                            Text(
                              _uploading ? 'Загрузка...' : 'Нажмите для выбора файлов',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _uploading
                                    ? c.accent
                                    : c.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'PDF, JPG, PNG',
                              style: TextStyle(
                                fontSize: 13,
                                color: c.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ).animate(delay: 150.ms).fadeIn(duration: 400.ms).scale(begin: const Offset(0.97, 0.97), curve: Curves.easeOutCubic),
                ),
              ),

              if (_uploadError != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, size: 18, color: c.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _uploadError!,
                              style: TextStyle(fontSize: 13, color: c.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (!_loading && _documents.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Загруженные файлы',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: c.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '${_documents.length} файлов',
                          style: TextStyle(
                            fontSize: 13,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              _loading
                  ? SliverPadding(
                      padding: const EdgeInsets.all(40),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: c.accent,
                          ),
                        ),
                      ),
                    )
                  : _documents.isEmpty
                      ? SliverPadding(
                          padding: const EdgeInsets.only(top: 60),
                          sliver: SliverToBoxAdapter(
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.folder_open_rounded,
                                    size: 56,
                                    color: c.muted,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Пока нет документов',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: c.textHint,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Нажмите кнопку выше, чтобы загрузить',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: c.textHint,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) {
                                final doc = _documents[i];
                                final fileType = (doc['file_type'] ?? '').toString().toLowerCase();
                                final fileSize = doc['file_size'];
                                final createdAt = doc['created_at']?.toString();
                                final sizeLabel = fileSize != null
                                    ? _formatFileSize((fileSize as num).toDouble())
                                    : '';
                                final dateLabel = createdAt != null
                                    ? DateFormat('d MMM yyyy, HH:mm').format(DateTime.parse(createdAt).toLocal())
                                    : '';
                                final filePath = doc['file_url']?.toString();
                                final isImage = fileType == 'jpg' || fileType == 'jpeg' || fileType == 'png';

                                return GestureDetector(
                                  onTap: () => _openDocument(doc),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: c.surface,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: c.border, width: 1),
                                    ),
                                    child: Row(
                                      children: [
                                        if (isImage && filePath != null)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: FutureBuilder<String>(
                                              future: SupabaseService.getDocumentUrl(filePath),
                                              builder: (context, snapshot) {
                                                final url = snapshot.data;
                                                if (url == null || url.isEmpty) {
                                                  return _buildFileIcon(c, fileType);
                                                }
                                                return Image.network(
                                                  url,
                                                  width: 48,
                                                  height: 48,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, obj, stack) => _buildFileIcon(c, fileType),
                                                );
                                              },
                                            ),
                                          )
                                        else
                                          _buildFileIcon(c, fileType),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                doc['name'] ?? '',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: c.textPrimary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Text(
                                                    sizeLabel,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: c.textSecondary,
                                                    ),
                                                  ),
                                                  if (dateLabel.isNotEmpty) ...[
                                                    Text(
                                                      ' · ',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: c.textHint,
                                                      ),
                                                    ),
                                                    Text(
                                                      dateLabel,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: c.textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete_outline_rounded,
                                            size: 20,
                                            color: c.error,
                                          ),
                                          onPressed: () => _deleteDocument(doc),
                                        ),
                                      ],
                                    ),
                                  ),
                                ).animate(delay: 150.ms + 60.ms * i)
                                    .fadeIn(duration: 300.ms)
                                    .slideY(begin: 0.08);
                              },
                              childCount: _documents.length,
                            ),
                          ),
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon(AppColors c, String type) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _fileColor(c, type).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        _fileIcon(type),
        color: _fileColor(c, type),
        size: 22,
      ),
    );
  }

  String _formatFileSize(double bytes) {
    if (bytes < 1024) return '${bytes.round()} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Color _fileColor(AppColors c, String type) => switch (type) {
        'pdf' => const Color(0xFFEF4444),
        'jpg' || 'jpeg' => const Color(0xFF38BDF8),
        'png' => const Color(0xFF2DD4A8),
        _ => c.textSecondary,
      };

  IconData _fileIcon(String type) => switch (type) {
        'pdf' => Icons.picture_as_pdf_rounded,
        'jpg' || 'jpeg' => Icons.photo_rounded,
        'png' => Icons.image_rounded,
        _ => Icons.insert_drive_file_rounded,
      };
}

class _DocumentPreviewScreen extends StatelessWidget {
  final String imageUrl;
  final String title;

  const _DocumentPreviewScreen({
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              );
            },
            errorBuilder: (_, obj, stack) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image_rounded, color: Colors.white54, size: 64),
                SizedBox(height: 12),
                Text(
                  'Не удалось загрузить изображение',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

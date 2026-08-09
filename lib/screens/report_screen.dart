import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/report_template.dart';
import '../services/cms_signature_parser.dart';
import '../services/ncalayer_service.dart';
import '../services/report_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/information_tile.dart';
import '../widgets/option_button.dart';
import '../widgets/case_progress_bar.dart';

class ReportScreen extends StatefulWidget {
  final String? applicationId;
  final ReportData? reportData;

  const ReportScreen({super.key, this.applicationId, this.reportData});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportData? _reportData;
  bool _loading = false;
  bool _generating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final rd = widget.reportData;
    if (rd != null) {
      _reportData = rd;
    } else if (widget.applicationId != null) {
      _loadApplicationData();
    }
  }

  Future<void> _loadApplicationData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final appId = widget.applicationId!;
      final app = await SupabaseService.getApplication(appId);

      final prop = app['properties'] ?? {};
      final profile = app['profiles'] ?? {};

      final data = await ReportService.generateReportData(
        propertyType: prop['type'] ?? 'Квартира',
        address: prop['address'] ?? '',
        area: (prop['area'] as num?)?.toDouble() ?? 0,
        rooms: prop['rooms'] ?? 0,
        floor: prop['floor'] ?? 0,
        totalFloors: prop['total_floors'] ?? 0,
        condition: prop['condition'] ?? 'Не указано',
        yearBuilt: prop['year_built'] ?? 0,
        clientName: profile['full_name'] ?? 'Не указано',
        clientIin: profile['iin'] ?? '',
      );

      if (mounted) {
        setState(() {
          _reportData = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Ошибка: $e';
        });
      }
    }
  }

  Future<void> _downloadPdf() async {
    if (_reportData == null) return;

    setState(() => _generating = true);

    try {
      final pdfBytes = await ReportService.generatePdf(_reportData!);

      if (mounted) {
        await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name: 'ESEP_Report_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка генерации PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _sharePdf() async {
    if (_reportData == null) return;

    setState(() => _generating = true);

    try {
      final pdfBytes = await ReportService.generatePdf(_reportData!);
      await Printing.sharePdf(bytes: pdfBytes, filename: 'report.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  // ============================================
  // ЭЦП-ПОДПИСЬ (NCALayer + CMS)
  // ============================================

  static const _ezSignerUrl = 'https://ezsigner.kz/#!/signCMS';
  static const _ncalayerUrl = 'https://pki.gov.kz';

  CmsSignatureInfo? _signatureInfo;
  DateTime? _signedAt;
  bool _signing = false;

  Future<void> _signWithNcalayer() async {
    final c = AppColors.of(context);
    setState(() => _signing = true);
    try {
      final available = await NcalayerService.isAvailable();
      if (!mounted) return;
      if (!available) {
        await _showNcalayerMissingDialog();
        return;
      }

      final result = await NcalayerService.signDocument();
      if (!mounted) return;

      if (result.success) {
        await _showSignedDialog(result.message ?? '');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Ошибка подписи',
                style: const TextStyle(color: Colors.white)),
            backgroundColor: c.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _signing = false);
    }
  }

  Future<void> _showNcalayerMissingDialog() async {
    final c = AppColors.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('NCALayer не запущен'),
        content: SingleChildScrollView(
          child: Text(
            'Для подписи ЭЦП нужна программа NCALayer от НУЦ РК '
            '(Windows, macOS или Linux).\n\n'
            '1. Скачайте и установите NCALayer с pki.gov.kz\n'
            '2. Запустите программу\n'
            '3. Вернитесь сюда и нажмите «Подписать ЭЦП»\n\n'
            'Или подпишите документ вручную на ezsigner.kz '
            'и загрузите .cms файл в отчёт.',
            style: TextStyle(color: c.textSecondary, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Позже', style: TextStyle(color: c.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openUrl(_ncalayerUrl);
            },
            child: const Text('Скачать NCALayer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openUrl(_ezSignerUrl);
            },
            child: Text('Открыть ezSigner',
                style: TextStyle(color: c.accent)),
          ),
        ],
      ),
    );
  }

  Future<void> _showSignedDialog(String savedPath) async {
    final c = AppColors.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Документ подписан'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ЭЦП-подпись сохранена:',
                style: TextStyle(color: c.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                savedPath,
                style: TextStyle(
                    color: c.textPrimary, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 12),
              Text(
                'Загрузите .cms файл в отчёт, чтобы сохранить подпись в ESEP.',
                style: TextStyle(color: c.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Позже', style: TextStyle(color: c.textSecondary)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _uploadCms();
            },
            child: const Text('Загрузить .cms'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadCms() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['cms'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      Uint8List? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        bytes = await file.xFile.readAsBytes();
      }
      if (bytes == null || bytes.isEmpty) {
        _showErrorSnack('Не удалось прочитать файл');
        return;
      }

      final info = CmsSignatureParser.parse(bytes);
      if (info == null || !info.hasName) {
        _showErrorSnack(
            'Не удалось распознать ЭЦП-подпись. Убедитесь, что это .cms файл.');
        return;
      }

      final appId = widget.applicationId;
      if (appId == null) {
        if (!mounted) return;
        setState(() {
          _signatureInfo = info;
          _signedAt = DateTime.now();
        });
        _showSuccessSnack('Подпись распознана: ${info.signerName}');
        return;
      }

      await SupabaseService.attachCmsSignature(
        applicationId: appId,
        cmsBytes: bytes,
        signerName: info.signerName,
        signerIin: info.signerIin,
      );

      if (!mounted) return;
      setState(() {
        _signatureInfo = info;
        _signedAt = DateTime.now();
      });
      _showSuccessSnack('ЭЦП-подпись сохранена: ${info.signerName}');
    } catch (e) {
      _showErrorSnack('Ошибка загрузки: $e');
    }
  }

  void _openUrl(String url) {
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _showErrorSnack(String message) {
    if (!mounted) return;
    final c = AppColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: c.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnack(String message) {
    if (!mounted) return;
    final c = AppColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: c.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatDate(DateTime d) => DateFormat('d MMM yyyy, HH:mm').format(d);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (_loading || _generating) {
      return Scaffold(
        backgroundColor: c.background,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: c.accent, strokeWidth: 2),
                const SizedBox(height: 16),
                Text(
                  _generating ? 'Генерация PDF...' : 'Анализ данных...',
                  style: TextStyle(fontSize: 14, color: c.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: c.background,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 56, color: c.error),
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(fontSize: 14, color: c.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Назад'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final data = _reportData;
    if (data == null) {
      return Scaffold(
        backgroundColor: c.background,
        body: SafeArea(
          child: Center(
            child: Text('Нет данных', style: TextStyle(color: c.textSecondary)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
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
                      'Отчёт об оценке',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.border, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ИТОГОВАЯ СТОИМОСТЬ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        data.formattedPrice,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: c.textPrimary,
                          letterSpacing: -1,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: c.accent.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                data.confidencePercent,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: c.accent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Уверенность оценки',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: c.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                CaseProgressBar(progress: data.confidence),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Диапазон оценки',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            data.formattedPriceRangeLow,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                          ),
                          Text(
                            data.formattedPriceRangeHigh,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      CaseProgressBar(
                        progress: (data.estimatedPrice - data.priceRangeLow) /
                            (data.priceRangeHigh - data.priceRangeLow),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Text(
                  'Данные объекта',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    InformationTile(
                      content: '${data.area.round()}',
                      name: 'Площадь м²',
                      icon: Icons.square_foot_rounded,
                      valueColor: c.textPrimary,
                    ),
                    InformationTile(
                      content: '${data.rooms}',
                      name: 'Комнаты',
                      icon: Icons.meeting_room_rounded,
                      valueColor: c.info,
                    ),
                    InformationTile(
                      content: '${data.floor}',
                      name: 'Этаж',
                      icon: Icons.layers_rounded,
                      valueColor: c.warning,
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.border, width: 1),
                  ),
                  child: Column(
                    children: [
                      infoRow(context, 'Адрес', data.address),
                      divider(context),
                      infoRow(context, 'Дата оценки', data.appraisalDate),
                      divider(context),
                      infoRow(context, 'Тип', data.propertyType),
                      divider(context),
                      infoRow(context, 'Цена за м²', data.formattedPricePerMeter),
                    ],
                  ),
                ),
              ),
            ),

            if (data.comparables.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Text(
                    'Аналоги (${data.comparables.length})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final comp = data.comparables[index];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.border, width: 1),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(comp.address,
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary),
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text('${comp.area.round()} м² · ${comp.source}',
                                      style: TextStyle(fontSize: 11, color: c.textSecondary)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(comp.formattedPrice,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.accent)),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: data.comparables.length,
                ),
              ),
            ],

            if (data.recommendations.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Text(
                    'Рекомендации',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.border, width: 1),
                    ),
                    child: Column(
                      children: data.recommendations
                          .map((r) => _recItem(
                                context,
                                _iconFromString(r.icon),
                                r.title,
                                r.description,
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ],

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Row(
                  children: [
                    Expanded(
                      child: OptionButton(
                        text: 'Скачать PDF',
                        icon: Icons.download_rounded,
                        onTap: _downloadPdf,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OptionButton(
                        text: 'Поделиться',
                        icon: Icons.share_rounded,
                        backgroundColor: Colors.transparent,
                        textColor: c.accent,
                        onTap: _sharePdf,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ЭЦП-подпись отчёта (NCALayer / ezSigner)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: _buildEcpBlock(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEcpBlock(BuildContext context) {
    final c = AppColors.of(context);
    final info = _signatureInfo;
    final signed = info != null && _signedAt != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: signed ? c.success.withValues(alpha: 0.5) : c.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                signed ? Icons.verified_rounded : Icons.lock_outline_rounded,
                color: signed ? c.success : c.accent,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  signed ? 'Отчёт подписан ЭЦП' : 'ЭЦП-подпись отчёта',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (signed) ...[
            Text(
              'Подписал: ${info.signerName}',
              style: TextStyle(fontSize: 13, color: c.textPrimary),
            ),
            if (info.signerIin.isNotEmpty)
              Text(
                'ИИН: ${info.signerIin}',
                style: TextStyle(fontSize: 13, color: c.textSecondary),
              ),
            Text(
              'Дата: ${_formatDate(_signedAt!)}',
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
            const SizedBox(height: 10),
          ] else
            Text(
              'Подпишите PDF-отчёт своей ЭЦП (NCALayer, десктоп) или '
              'загрузите готовый .cms файл с ezsigner.kz.',
              style: TextStyle(
                  fontSize: 13, color: c.textSecondary, height: 1.4),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OptionButton(
                  text: _signing ? 'Подписание…' : 'Подписать ЭЦП',
                  icon: Icons.draw_rounded,
                  onTap: _signing ? null : _signWithNcalayer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OptionButton(
                  text: 'Загрузить .cms',
                  icon: Icons.upload_file_rounded,
                  backgroundColor: Colors.transparent,
                  textColor: c.accent,
                  onTap: _uploadCms,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recItem(BuildContext context, IconData icon, String title, String subtitle) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: c.accent, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: c.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconFromString(String icon) {
    switch (icon) {
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'location':
        return Icons.location_on_rounded;
      case 'info':
        return Icons.info_outline_rounded;
      default:
        return Icons.lightbulb_outline_rounded;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/report_template.dart';
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
          ],
        ),
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

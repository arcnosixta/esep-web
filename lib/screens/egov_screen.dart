import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import '../services/egov_service.dart';

class EgovScreen extends StatefulWidget {
  const EgovScreen({super.key});

  @override
  State<EgovScreen> createState() => _EgovScreenState();
}

class _EgovScreenState extends State<EgovScreen> {
  bool _ecpConnected = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _loading = true;

  EgovPersonalData? _personalData;
  List<EgovPropertyData> _properties = [];
  List<EgovDocument> _documents = [];
  List<EgovOwnerInfo> _owners = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final connected = await EgovService.isEcpConnected();
    final biometricAvail = await EgovService.isBiometricAvailable();
    final biometricOn = await EgovService.isBiometricEnabled();

    _ecpConnected = connected;
    _biometricAvailable = biometricAvail;
    _biometricEnabled = biometricOn;

    if (connected) {
      _personalData = await EgovService.getPersonalData();
      _properties = await EgovService.getPropertyData();
      _documents = await EgovService.getDocuments();
      _owners = await EgovService.getOwnerInfo();
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _connectEcp() async {
    final pinController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Подключение ЭЦП'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.upload_file_rounded,
                      size: 36,
                      color: AppColors.accent.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Загрузите файл ЭЦП',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Форматы: .p12, .pfx',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                obscureText: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'PIN-код ЭЦП',
                  prefixIcon: Icon(Icons.lock_outline, size: 18),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Подключить',
                style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );

    if (result == true && pinController.text.isNotEmpty) {
      setState(() => _loading = true);

      final ecpResult = await EgovService.pickAndParseEcpFile(pinController.text);

      if (ecpResult == null) {
        if (mounted) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Файл не выбран',
                  style: TextStyle(color: Colors.white)),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return;
      }

      if (ecpResult.error != null) {
        if (mounted) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ecpResult.error!,
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return;
      }

      await EgovService.saveEcpData(
        certificateBase64: 'file_based_cert',
        pin: pinController.text,
        ownerName: ecpResult.ownerName ?? '',
        iin: ecpResult.iin ?? '',
        fileName: ecpResult.fileName,
        validUntil: ecpResult.validUntil,
        serialNumber: ecpResult.serialNumber,
      );

      await EgovService.syncToSupabase();
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ЭЦП подключён! ${ecpResult.ownerName ?? ""}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _disconnectEcp() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Отключить ЭЦП?'),
        content: const Text(
          'Все данные EGOV будут удалены из приложения',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Отключить',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _loading = true);
      await EgovService.disconnectEcp();
      await _loadData();
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final auth = await EgovService.authenticateWithBiometrics(
        reason: 'Включите биометрию для защиты ЭЦП',
      );
      if (!auth) return;
    }
    await EgovService.setBiometricEnabled(value);
    setState(() => _biometricEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ЭЦП и EGOV'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.accent,
        child: CustomScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: const Text(
                  'ЭЦП И EGOV',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      left: BorderSide(
                        color: _ecpConnected
                            ? AppColors.success
                            : AppColors.muted,
                        width: 3,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _ecpConnected ? 'ЭЦП подключён' : 'ЭЦП не подключён',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _ecpConnected
                                  ? 'Данные EGOV доступны'
                                  : 'Подключите ЭЦП для доступа к данным',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (_ecpConnected
                                  ? AppColors.success
                                  : AppColors.muted)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _ecpConnected ? 'Активен' : 'Неактивен',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _ecpConnected
                                ? AppColors.success
                                : AppColors.textHint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  width: double.infinity,
                  child: _ecpConnected
                      ? OutlinedButton(
                          onPressed: _disconnectEcp,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: AppColors.error, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Отключить ЭЦП',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        )
                      : PrimaryButton(
                          label: 'Подключить ЭЦП',
                          icon: Icons.vpn_key_rounded,
                          onPressed: _connectEcp,
                        ),
                ),
              ),
            ),

            if (_biometricAvailable && _ecpConnected)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    color: AppColors.paper,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.fingerprint_rounded,
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
                                'Биометрическая защита',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Требовать отпечаток/лицо для ЭЦП',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _biometricEnabled,
                          onChanged: _toggleBiometric,
                          activeThumbColor: AppColors.accent,
                          activeTrackColor:
                              AppColors.accent.withValues(alpha: 0.3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (_ecpConnected && _personalData != null) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    color: AppColors.surface,
                    padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
                    child: const Text(
                      'ЛИЧНЫЕ ДАННЫЕ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    color: AppColors.surface,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Column(
                      children: [
                        _dataRow('ФИО', _personalData!.fullName),
                        _thinDivider(),
                        _dataRow('ИИН', _personalData!.iin),
                        _thinDivider(),
                        _dataRow('Дата рождения', _personalData!.dateOfBirth),
                        _thinDivider(),
                        _dataRow('Адрес', _personalData!.address),
                        _thinDivider(),
                        _dataRow('Телефон', _personalData!.phone),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            if (_ecpConnected && _properties.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    color: AppColors.surface,
                    padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'НЕДВИЖИМОСТЬ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          '${_properties.length} объектов',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    _properties.map((prop) {
                      return Column(
                        children: [
                          Container(
                            width: double.infinity,
                            color: AppColors.surface,
                            padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 16),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.apartment_rounded,
                                    color: AppColors.accent,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        prop.type,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        prop.address,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          _miniStat('${prop.area} м²',
                                              AppColors.accent),
                                          const SizedBox(width: 8),
                                          _miniStat(
                                              'Кадастр: ${prop.cadastralNumber}',
                                              AppColors.textSecondary),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${prop.ownershipType} · ${prop.registrationDate}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textHint,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textHint,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 1,
                            margin: const EdgeInsets.only(left: 68),
                            color: AppColors.border,
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],

            if (_ecpConnected && _documents.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    color: AppColors.surface,
                    padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
                    child: const Text(
                      'ДОКУМЕНТЫ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    _documents.map((doc) {
                      final icon = doc.type == 'certificate'
                          ? Icons.verified_rounded
                          : doc.type == 'passport'
                              ? Icons.badge_rounded
                              : Icons.description_rounded;
                      final color = doc.type == 'certificate'
                          ? AppColors.success
                          : doc.type == 'passport'
                              ? AppColors.info
                              : AppColors.accent;
                      return Column(
                        children: [
                          Container(
                            width: double.infinity,
                            color: AppColors.surface,
                            padding:
                                const EdgeInsets.fromLTRB(16, 14, 16, 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child:
                                      Icon(icon, color: color, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc.name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${doc.date} · ${doc.status}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textHint,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 1,
                            margin: const EdgeInsets.only(left: 68),
                            color: AppColors.border,
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],

            if (_ecpConnected && _owners.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    color: AppColors.surface,
                    padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
                    child: const Text(
                      'СВЕДЕНИЯ О СОБСТВЕННИКЕ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    _owners.map((owner) {
                      return Column(
                        children: [
                          Container(
                            width: double.infinity,
                            color: AppColors.surface,
                            padding:
                                const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: Column(
                              children: [
                                _dataRow('ФИО', owner.fullName),
                                _thinDivider(),
                                _dataRow('ИИН', owner.iin),
                                _thinDivider(),
                                _dataRow('Доля', owner.ownershipShare),
                                _thinDivider(),
                                _dataRow('Тип', owner.registrationType),
                                _thinDivider(),
                                _dataRow(
                                    'Дата регистрации', owner.registrationDate),
                              ],
                            ),
                          ),
                          Container(
                            height: 1,
                            color: AppColors.border,
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],

            if (!_ecpConnected)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 40, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.vpn_key_off_rounded,
                          size: 64,
                          color: AppColors.textHint.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Подключите ЭЦП\nдля доступа к данным EGOV',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        ),
      ),
    );
  }

  Widget _dataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _thinDivider() =>
      Container(height: 1, color: AppColors.border);
}

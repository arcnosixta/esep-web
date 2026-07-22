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
    final c = AppColors.of(context);
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
                  color: c.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: c.accent.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.upload_file_rounded,
                      size: 36,
                      color: c.accent.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Загрузите файл ЭЦП',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Форматы: .p12, .pfx',
                      style: TextStyle(
                        fontSize: 12,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                obscureText: true,
                style: TextStyle(color: c.textPrimary),
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
            child: Text('Отмена',
                style: TextStyle(color: c.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Подключить',
                style: TextStyle(color: c.accent)),
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
              backgroundColor: AppColors.of(context).error,
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
              backgroundColor: AppColors.of(context).error,
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
            backgroundColor: AppColors.of(context).success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _disconnectEcp() async {
    final c = AppColors.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Отключить ЭЦП?'),
        content: Text(
          'Все данные EGOV будут удалены из приложения',
          style: TextStyle(color: c.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Отмена',
                style: TextStyle(color: c.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Отключить',
                style: TextStyle(color: c.error)),
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
    final c = AppColors.of(context);

    if (_loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: c.accent)),
      );
    }

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: c.accent,
          child: CustomScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                        'ЭЦП и EGOV',
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
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _ecpConnected ? 'ЭЦП подключён' : 'ЭЦП не подключён',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: c.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _ecpConnected
                                    ? 'Данные EGOV доступны'
                                    : 'Подключите ЭЦП для доступа к данным',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: c.textSecondary,
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
                                    ? c.success
                                    : c.muted)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _ecpConnected ? 'Активен' : 'Неактивен',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _ecpConnected
                                  ? c.success
                                  : c.textHint,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: _ecpConnected
                        ? OutlinedButton(
                            onPressed: _disconnectEcp,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: c.error, width: 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Отключить ЭЦП',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: c.error,
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.border, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: c.accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.fingerprint_rounded,
                              color: c.accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Биометрическая защита',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: c.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Требовать отпечаток/лицо для ЭЦП',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: c.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _biometricEnabled,
                            onChanged: _toggleBiometric,
                            activeThumbColor: c.accent,
                            activeTrackColor:
                                c.accent.withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (_ecpConnected && _personalData != null) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Text(
                      'ЛИЧНЫЕ ДАННЫЕ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.border, width: 1),
                      ),
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'НЕДВИЖИМОСТЬ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: c.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          '${_properties.length} объектов',
                          style: TextStyle(
                            fontSize: 13,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.border, width: 1),
                      ),
                      child: Column(
                        children: _properties.map((prop) {
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: c.accent
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.apartment_rounded,
                                        color: c.accent,
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
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: c.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            prop.address,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: c.textSecondary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              _miniStat(context, '${prop.area} м²',
                                                  c.accent),
                                              const SizedBox(width: 8),
                                              _miniStat(
                                                  context,
                                                  'Кадастр: ${prop.cadastralNumber}',
                                                  c.textSecondary),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${prop.ownershipType} · ${prop.registrationDate}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: c.textHint,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: c.textHint,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                              if (prop != _properties.last)
                                Container(
                                  height: 1,
                                  margin: const EdgeInsets.only(left: 68),
                                  color: c.divider,
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],

              if (_ecpConnected && _documents.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Text(
                      'ДОКУМЕНТЫ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.border, width: 1),
                      ),
                      child: Column(
                        children: _documents.map((doc) {
                          final icon = doc.type == 'certificate'
                              ? Icons.verified_rounded
                              : doc.type == 'passport'
                                  ? Icons.badge_rounded
                                  : Icons.description_rounded;
                          final color = doc.type == 'certificate'
                              ? c.success
                              : doc.type == 'passport'
                                  ? c.info
                                  : c.accent;
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(14),
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
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: c.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${doc.date} · ${doc.status}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: c.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: c.textHint,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                              if (doc != _documents.last)
                                Container(
                                  height: 1,
                                  margin: const EdgeInsets.only(left: 68),
                                  color: c.divider,
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],

              if (_ecpConnected && _owners.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Text(
                      'СВЕДЕНИЯ О СОБСТВЕННИКЕ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.border, width: 1),
                      ),
                      child: Column(
                        children: _owners.map((owner) {
                          return Column(
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
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],

              if (!_ecpConnected)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.vpn_key_off_rounded,
                            size: 64,
                            color: c.textHint.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Подключите ЭЦП\nдля доступа к данным EGOV',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: c.textSecondary,
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
      ),
    );
  }

  Widget _dataRow(String label, String value) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: c.textSecondary)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(BuildContext context, String text, Color color) {
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

  Widget _thinDivider() {
    final c = AppColors.of(context);
    return Container(height: 1, color: c.divider);
  }
}

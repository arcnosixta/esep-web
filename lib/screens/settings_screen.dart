import 'package:flutter/material.dart';

import '../providers/app_settings.dart';
import '../services/egov_service.dart';
import '../theme/app_colors.dart';
import '../l10n/app_strings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final bioAvail = await EgovService.isBiometricAvailable();
    if (mounted) {
      setState(() => _biometricAvailable = bioAvail);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final s = AppStrings.of(context);
    final currentTheme = appSettings.themeMode;
    final currentLangCode = appSettings.localeCode;

    final themeLabel = switch (currentTheme) {
      ThemeMode.system => s.themeSystem,
      ThemeMode.light => s.themeLight,
      ThemeMode.dark => s.themeDark,
    };

    final langLabel = switch (currentLangCode) {
      'kk' => s.langKazakh,
      'en' => s.langEnglish,
      _ => s.langRussian,
    };

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  s.settingsTitle,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              sliver: SliverToBoxAdapter(
                child: _sectionHeader(s.settingsGeneral),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              sliver: SliverToBoxAdapter(
                child: _card(
                  children: [
                    _switchRow(
                      icon: Icons.notifications_rounded,
                      iconColor: c.accent,
                      title: s.settingsNotifications,
                      subtitle: s.settingsNotificationsSubtitle,
                      value: _notificationsEnabled,
                      onChanged: (v) => setState(() => _notificationsEnabled = v),
                    ),
                    _divider(),
                    _tapRow(
                      icon: Icons.language_rounded,
                      iconColor: c.info,
                      title: s.settingsLanguage,
                      trailing: Text(
                        langLabel,
                        style: TextStyle(
                          fontSize: 14,
                          color: c.textSecondary,
                        ),
                      ),
                      onTap: _showLanguageDialog,
                    ),
                    _divider(),
                    _tapRow(
                      icon: Icons.palette_rounded,
                      iconColor: c.gold,
                      title: s.settingsTheme,
                      trailing: Text(
                        themeLabel,
                        style: TextStyle(
                          fontSize: 14,
                          color: c.textSecondary,
                        ),
                      ),
                      onTap: _showThemeDialog,
                    ),
                  ],
                ),
              ),
            ),

            if (_biometricAvailable) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: _sectionHeader(s.settingsSecurity),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: _card(
                    children: [
                      _switchRow(
                        icon: Icons.fingerprint_rounded,
                        iconColor: c.success,
                        title: s.settingsBiometrics,
                        subtitle: s.settingsBiometricsSubtitle,
                        value: _biometricEnabled,
                        onChanged: (v) => setState(() => _biometricEnabled = v),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              sliver: SliverToBoxAdapter(
                child: _sectionHeader(s.settingsAbout),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              sliver: SliverToBoxAdapter(
                child: _card(
                  children: [
                    _tapRow(
                      icon: Icons.info_outline_rounded,
                      iconColor: c.textSecondary,
                      title: s.settingsVersion,
                      trailing: Text(
                        '1.0.0',
                        style: TextStyle(
                          fontSize: 14,
                          color: c.textSecondary,
                        ),
                      ),
                      onTap: () {},
                    ),
                    _divider(),
                    _tapRow(
                      icon: Icons.description_rounded,
                      iconColor: c.textSecondary,
                      title: s.settingsTerms,
                      onTap: () {},
                    ),
                    _divider(),
                    _tapRow(
                      icon: Icons.shield_rounded,
                      iconColor: c.textSecondary,
                      title: s.settingsPrivacy,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              sliver: SliverToBoxAdapter(
                child: _sectionHeader(s.settingsAccount),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              sliver: SliverToBoxAdapter(
                child: _card(
                  children: [
                    _tapRow(
                      icon: Icons.delete_outline_rounded,
                      iconColor: c.error,
                      title: s.settingsDeleteAccount,
                      titleColor: c.error,
                      onTap: _deleteAccount,
                    ),
                  ],
                ),
              ),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    final c = AppColors.of(context);
    final s = AppStrings.of(context);
    final languages = [
      (code: 'ru', label: s.langRussian),
      (code: 'kk', label: s.langKazakh),
      (code: 'en', label: s.langEnglish),
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.settingsLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            final selected = lang.code == appSettings.localeCode;
            return ListTile(
              title: Text(
                lang.label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? c.accent : c.textPrimary,
                ),
              ),
              trailing: selected
                  ? Icon(Icons.check_rounded, color: c.accent, size: 20)
                  : null,
              onTap: () {
                appSettings.setLocale(AppStrings.localeFromCode(lang.code));
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog() {
    final c = AppColors.of(context);
    final s = AppStrings.of(context);
    final themes = [
      (mode: ThemeMode.system, label: s.themeSystem),
      (mode: ThemeMode.light, label: s.themeLight),
      (mode: ThemeMode.dark, label: s.themeDark),
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.settingsTheme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: themes.map((t) {
            final selected = t.mode == appSettings.themeMode;
            return ListTile(
              title: Text(
                t.label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? c.accent : c.textPrimary,
                ),
              ),
              trailing: selected
                  ? Icon(Icons.check_rounded, color: c.accent, size: 20)
                  : null,
              onTap: () {
                appSettings.setThemeMode(t.mode);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final c = AppColors.of(context);
    final s = AppStrings.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.settingsDeleteAccountTitle),
        content: Text(
          s.settingsDeleteAccountContent,
          style: TextStyle(color: c.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete, style: TextStyle(color: c.error)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.settingsDeleteAccountComingSoon)),
      );
    }
  }

  Widget _sectionHeader(String title) {
    final c = AppColors.of(context);
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: c.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border, width: 1),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() {
    final c = AppColors.of(context);
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 52),
      color: c.divider,
    );
  }

  Widget _switchRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: c.accent,
          ),
        ],
      ),
    );
  }

  Widget _tapRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? titleColor,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: titleColor ?? c.textPrimary,
                ),
              ),
            ),
            ?trailing,
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: c.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

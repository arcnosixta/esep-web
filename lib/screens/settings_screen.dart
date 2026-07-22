import 'package:flutter/material.dart';

import '../main.dart';
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  s.settingsTitle,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
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
                      iconColor: AppColors.accent,
                      title: s.settingsNotifications,
                      subtitle: s.settingsNotificationsSubtitle,
                      value: _notificationsEnabled,
                      onChanged: (v) => setState(() => _notificationsEnabled = v),
                    ),
                    _divider(),
                    _tapRow(
                      icon: Icons.language_rounded,
                      iconColor: AppColors.info,
                      title: s.settingsLanguage,
                      trailing: Text(
                        langLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      onTap: _showLanguageDialog,
                    ),
                    _divider(),
                    _tapRow(
                      icon: Icons.palette_rounded,
                      iconColor: AppColors.gold,
                      title: s.settingsTheme,
                      trailing: Text(
                        themeLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
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
                        iconColor: AppColors.success,
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
                      iconColor: AppColors.textSecondary,
                      title: s.settingsVersion,
                      trailing: const Text(
                        '1.0.0',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      onTap: () {},
                    ),
                    _divider(),
                    _tapRow(
                      icon: Icons.description_rounded,
                      iconColor: AppColors.textSecondary,
                      title: s.settingsTerms,
                      onTap: () {},
                    ),
                    _divider(),
                    _tapRow(
                      icon: Icons.shield_rounded,
                      iconColor: AppColors.textSecondary,
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
                      iconColor: AppColors.error,
                      title: s.settingsDeleteAccount,
                      titleColor: AppColors.error,
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
    final s = AppStrings.of(context);
    final languages = [
      (code: 'ru', label: s.langRussian),
      (code: 'kk', label: s.langKazakh),
      (code: 'en', label: s.langEnglish),
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
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
                  color: selected ? AppColors.accent : AppColors.textPrimary,
                ),
              ),
              trailing: selected
                  ? const Icon(Icons.check_rounded, color: AppColors.accent, size: 20)
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
    final s = AppStrings.of(context);
    final themes = [
      (mode: ThemeMode.system, label: s.themeSystem),
      (mode: ThemeMode.light, label: s.themeLight),
      (mode: ThemeMode.dark, label: s.themeDark),
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
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
                  color: selected ? AppColors.accent : AppColors.textPrimary,
                ),
              ),
              trailing: selected
                  ? const Icon(Icons.check_rounded, color: AppColors.accent, size: 20)
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
    final s = AppStrings.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.settingsDeleteAccountTitle),
        content: Text(
          s.settingsDeleteAccountContent,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete, style: const TextStyle(color: AppColors.error)),
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
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 52),
      color: AppColors.divider,
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.accent,
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
                  color: titleColor ?? AppColors.textPrimary,
                ),
              ),
            ),
            ?trailing,
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

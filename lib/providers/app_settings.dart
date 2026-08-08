import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Глобальный экземпляр настроек приложения.
final appSettings = AppSettings();

class AppSettings extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _localeKey = 'locale';
  static const _onboardingKey = 'onboarding_done';
  static const _tourKey = 'tour_pending';

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('ru');
  bool _onboardingDone = false;
  bool _tourPending = false;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get onboardingDone => _onboardingDone;
  bool get tourPending => _tourPending;

  String get localeCode => _locale.languageCode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    _themeMode = ThemeMode.values[themeIndex.clamp(0, 2)];
    final localeCode = prefs.getString(_localeKey) ?? 'ru';
    _locale = _localeFromString(localeCode);
    _onboardingDone = prefs.getBool(_onboardingKey) ?? false;
    _tourPending = prefs.getBool(_tourKey) ?? false;
    notifyListeners();
  }

  /// Отметить, что онбординг показан.
  /// [withTour] — показывать ли экскурсию по интерфейсу после онбординга.
  Future<void> completeOnboarding({bool withTour = true}) async {
    _onboardingDone = true;
    _tourPending = withTour;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    await prefs.setBool(_tourKey, withTour);
  }

  Future<void> setTourDone() async {
    _tourPending = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tourKey, false);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  static Locale _localeFromString(String code) => switch (code) {
        'kk' => const Locale('kk'),
        'en' => const Locale('en'),
        _ => const Locale('ru'),
      };
}

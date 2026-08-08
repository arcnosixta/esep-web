import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Глобальный экземпляр настроек приложения.
final appSettings = AppSettings();

class AppSettings extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _localeKey = 'locale';

  SharedPreferences? _prefs;

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('ru');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  String get localeCode => _locale.languageCode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    _themeMode = ThemeMode.values[themeIndex.clamp(0, 2)];
    final localeCode = prefs.getString(_localeKey) ?? 'ru';
    _locale = _localeFromString(localeCode);
    notifyListeners();
  }

  // ── Онбординг и экскурсия ─────────────────────────────────────────
  // Флаги хранятся отдельно для каждого пользователя (по userId),
  // чтобы новый аккаунт снова увидел вступительную инструкцию,
  // а у того же пользователя она не повторялась.

  static String _onboardingKeyFor(String userId) => 'onboarding_done_$userId';
  static String _tourKeyFor(String userId) => 'tour_pending_$userId';

  /// Показывать ли вступительную инструкцию пользователю [userId].
  bool onboardingDoneFor(String userId) =>
      _prefs?.getBool(_onboardingKeyFor(userId)) ?? false;

  /// Показывать ли экскурсию по интерфейсу после онбординга.
  bool tourPendingFor(String userId) =>
      _prefs?.getBool(_tourKeyFor(userId)) ?? false;

  /// Отметить, что инструкция показана.
  /// [withTour] — показывать ли экскурсию по интерфейсу после неё.
  Future<void> completeOnboarding(String userId, {bool withTour = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKeyFor(userId), true);
    await prefs.setBool(_tourKeyFor(userId), withTour);
    notifyListeners();
  }

  Future<void> setTourDone(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tourKeyFor(userId), false);
    notifyListeners();
  }

  // ── Тема и язык ───────────────────────────────────────────────────

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

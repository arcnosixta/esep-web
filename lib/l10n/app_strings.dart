import 'package:flutter/material.dart';

class AppStrings {
  AppStrings._();

  // ── Helpers ──────────────────────────────────────────────────

  static const _ru = _Ru();
  static const _kk = _Kk();
  static const _en = _En();

  static StringsBase of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return switch (code) {
      'kk' => _kk,
      'en' => _en,
      _ => _ru,
    };
  }

  static Locale localeFromCode(String code) => switch (code) {
        'kk' => const Locale('kk'),
        'en' => const Locale('en'),
        _ => const Locale('ru'),
      };
}

class AppStringsDelegate extends LocalizationsDelegate<StringsBase> {
  const AppStringsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['ru', 'kk', 'en'].contains(locale.languageCode);

  @override
  Future<StringsBase> load(Locale locale) async =>
      _stringsForLocale(locale.languageCode);

  @override
  bool shouldReload(covariant LocalizationsDelegate<StringsBase> old) => false;

  static StringsBase _stringsForLocale(String code) => switch (code) {
        'kk' => const _Kk(),
        'en' => const _En(),
        _ => const _Ru(),
      };
}

// ── Abstract interface ──────────────────────────────────────

abstract class StringsBase {
  // General
  String get appName;
  String get save;
  String get cancel;
  String get delete;
  String get close;
  String get back;
  String get loading;
  String get error;
  String get retry;

  // Navigation
  String get navHome;
  String get navCases;
  String get navAi;
  String get navDocuments;
  String get navProfile;

  // Home
  String get homeGreetingMorning;
  String get homeGreetingAfternoon;
  String get homeGreetingEvening;
  String get homeCurrentApplication;
  String get homeContinueWork;
  String get homeNewApplication;
  String get homeDocuments;
  String get homePayment;
  String get homeEvaluate;
  String get homeRecentApplications;
  String get homeAll;
  String get homeNoApplications;

  // Profile
  String get profileTitle;
  String get profileTab;
  String get settingsTab;
  String get profileVerified;
  String get profileEdit;
  String get profileEditTitle;
  String get profileName;
  String get profilePhone;
  String get profileIin;
  String get profileRole;
  String get profileRoleClient;
  String get profileRoleAppraiser;
  String get profileRoleAdmin;
  String get profileObjects;
  String get profileDocuments;
  String get profileEvaluations;
  String get profileMyProperty;
  String get profileMyDocuments;
  String get profileHistory;
  String get profileNoProperty;
  String get profileNoDocuments;
  String get profileNoHistory;
  String get profileHelp;
  String get profileAbout;
  String get profileSignOut;
  String get profileSignOutTitle;
  String get profileSignOutContent;
  String get profileNameEmpty;
  String get profileUpdated;
  String get profileEgovTitle;
  String get profileEgovSubtitle;
  String get profileEgovOpen;

  // Settings
  String get settingsTitle;
  String get settingsGeneral;
  String get settingsNotifications;
  String get settingsNotificationsSubtitle;
  String get settingsLanguage;
  String get settingsTheme;
  String get settingsSecurity;
  String get settingsBiometrics;
  String get settingsBiometricsSubtitle;
  String get settingsAbout;
  String get settingsVersion;
  String get settingsTerms;
  String get settingsPrivacy;
  String get settingsAccount;
  String get settingsDeleteAccount;
  String get settingsDeleteAccountTitle;
  String get settingsDeleteAccountContent;
  String get settingsDeleteAccountComingSoon;

  // Theme names
  String get themeSystem;
  String get themeLight;
  String get themeDark;

  // Language names
  String get langRussian;
  String get langKazakh;
  String get langEnglish;

  // Cases
  String get casesTitle;
  String get casesAll;
  String get casesInProgress;
  String get casesCompleted;
  String get casesNoCases;

  // Status labels
  String get statusNew;
  String get statusInProgress;
  String get statusCompleted;
  String get statusRejected;
  String get statusPaid;
  String get statusPendingPayment;

  // Property types
  String get propertyApartment;
  String get propertyHouse;
  String get propertyLand;
  String get propertyCommercial;

  // New Application
  String get newAppTitle;
  String get newAppPropertyType;
  String get newAppAddress;
  String get newAppArea;
  String get newAppRooms;
  String get newAppFloor;
  String get newAppTotalFloors;
  String get newAppOwnerType;
  String get newAppSubmit;
  String get newAppSuccess;
  String get newAppFillAll;

  // Documents
  String get docsTitle;
  String get docsUpload;
  String get docsUploadHint;
  String get docsEmpty;
  String get docsDeleteTitle;
  String get docsDeleteConfirm;
  String get docsUploading;
  String get docsFormats;

  // AI Chat
  String get aiTitle;
  String get aiPlaceholder;
  String get aiGreeting;
  String get aiGreetingSubtitle;
  String get aiError;
  String get aiSuggestions;

  // Payment
  String get paymentTitle;
  String get paymentMethod;
  String get paymentCard;
  String get paymentKaspi;
  String get paymentAmount;
  String get paymentPay;
  String get paymentSuccess;

  // Report
  String get reportTitle;
  String get reportShare;
  String get reportDownloadPdf;
  String get reportView;

  // Case Detail
  String get caseDetailTitle;
  String get caseDetailObject;
  String get caseDetailOwner;
  String get caseDetailDates;
  String get caseDetailFactors;
  String get caseDetailRange;
  String get caseDetailConfidence;

  // Admin
  String get adminTitle;
  String get adminStats;
  String get adminUsers;
  String get adminAppraisers;

  // Egov
  String get egovTitle;
  String get egovConnect;
  String get egovConnected;
  String get egovNotConnected;
  String get egovDisable;
  String get egovDisableTitle;
  String get egovDisableContent;
  String get egovPinPrompt;
  String get egovFilePrompt;
  String get egovFormats;
  String get egovDataAvailable;
  String get egovAllDataWillBeRemoved;
  String get egovBiometricPrompt;
  String get egovRequireBiometric;
  String get egovFileEmpty;
  String get egovFileReadError;

  // Login / Registration
  String get loginTitle;
  String get loginSubtitle;
  String get loginEmail;
  String get loginPassword;
  String get loginButton;
  String get loginButtonLoading;
  String get loginForgotPassword;
  String get loginNoAccount;
  String get loginSignUp;
  String get loginError;

  String get regTitle;
  String get regSubtitle;
  String get regName;
  String get regEmail;
  String get regPassword;
  String get regPasswordMin;
  String get regButton;
  String get regButtonLoading;
  String get regHasAccount;
  String get regSignIn;
  String get regTermsPrefix;
  String get regTermsLink;
  String get regSuccess;

  // Splash
  String get splashTitle;
  String get splashSubtitle;
}

// ── Russian ─────────────────────────────────────────────────

class _Ru implements StringsBase {
  const _Ru();

  @override String get appName => 'ESEP';
  @override String get save => 'Сохранить';
  @override String get cancel => 'Отмена';
  @override String get delete => 'Удалить';
  @override String get close => 'Закрыть';
  @override String get back => 'Назад';
  @override String get loading => 'Загрузка...';
  @override String get error => 'Ошибка';
  @override String get retry => 'Повторить';

  @override String get navHome => 'Главная';
  @override String get navCases => 'Заявки';
  @override String get navAi => 'AI';
  @override String get navDocuments => 'Документы';
  @override String get navProfile => 'Профиль';

  @override String get homeGreetingMorning => 'Доброе утро';
  @override String get homeGreetingAfternoon => 'Добрый день';
  @override String get homeGreetingEvening => 'Добрый вечер';
  @override String get homeCurrentApplication => 'Текущая заявка';
  @override String get homeContinueWork => 'Продолжить работу';
  @override String get homeNewApplication => 'Новая заявка';
  @override String get homeDocuments => 'Документы';
  @override String get homePayment => 'Оплата';
  @override String get homeEvaluate => 'Оценить';
  @override String get homeRecentApplications => 'Последние заявки';
  @override String get homeAll => 'Все →';
  @override String get homeNoApplications => 'Пока нет заявок';

  @override String get profileTitle => 'Профиль';
  @override String get profileTab => 'Профиль';
  @override String get settingsTab => 'Настройки';
  @override String get profileVerified => 'Верифицирован';
  @override String get profileEdit => 'Редактировать профиль';
  @override String get profileEditTitle => 'Редактировать профиль';
  @override String get profileName => 'ФИО';
  @override String get profilePhone => 'Телефон';
  @override String get profileIin => 'ИИН';
  @override String get profileRole => 'Роль';
  @override String get profileRoleClient => 'Клиент';
  @override String get profileRoleAppraiser => 'Оценщик';
  @override String get profileRoleAdmin => 'Администратор';
  @override String get profileObjects => 'Объектов';
  @override String get profileDocuments => 'Документов';
  @override String get profileEvaluations => 'Оценок';
  @override String get profileMyProperty => 'МОЁ ИМУЩЕСТВО';
  @override String get profileMyDocuments => 'МОИ ДОКУМЕНТЫ';
  @override String get profileHistory => 'ИСТОРИЯ ОЦЕНОК';
  @override String get profileNoProperty => 'Пока нет имущества';
  @override String get profileNoDocuments => 'Пока нет документов';
  @override String get profileNoHistory => 'Пока нет оценок';
  @override String get profileHelp => 'Помощь';
  @override String get profileAbout => 'О приложении';
  @override String get profileSignOut => 'Выйти';
  @override String get profileSignOutTitle => 'Выйти из аккаунта?';
  @override String get profileSignOutContent => 'Вы сможете войти снова';
  @override String get profileNameEmpty => 'Введите ФИО';
  @override String get profileUpdated => 'Профиль обновлён';
  @override String get profileEgovTitle => 'ГОСУСЛУГИ (EGOV)';
  @override String get profileEgovSubtitle => 'Подключение к Госуслугам';
  @override String get profileEgovOpen => 'Открыть';

  @override String get settingsTitle => 'Настройки';
  @override String get settingsGeneral => 'Общие';
  @override String get settingsNotifications => 'Уведомления';
  @override String get settingsNotificationsSubtitle => 'Push-уведомления о статусе заявок';
  @override String get settingsLanguage => 'Язык';
  @override String get settingsTheme => 'Тема';
  @override String get settingsSecurity => 'Безопасность';
  @override String get settingsBiometrics => 'Биометрия';
  @override String get settingsBiometricsSubtitle => 'Вход по отпечатку / Face ID';
  @override String get settingsAbout => 'О приложении';
  @override String get settingsVersion => 'Версия';
  @override String get settingsTerms => 'Условия использования';
  @override String get settingsPrivacy => 'Политика конфиденциальности';
  @override String get settingsAccount => 'Аккаунт';
  @override String get settingsDeleteAccount => 'Удалить аккаунт';
  @override String get settingsDeleteAccountTitle => 'Удалить аккаунт?';
  @override String get settingsDeleteAccountContent => 'Это действие необратимо. Все ваши данные будут удалены.';
  @override String get settingsDeleteAccountComingSoon => 'Функция будет доступна в следующем обновлении';

  @override String get themeSystem => 'Системная';
  @override String get themeLight => 'Светлая';
  @override String get themeDark => 'Тёмная';

  @override String get langRussian => 'Русский';
  @override String get langKazakh => 'Қазақша';
  @override String get langEnglish => 'English';

  @override String get casesTitle => 'Заявки';
  @override String get casesAll => 'Все';
  @override String get casesInProgress => 'В работе';
  @override String get casesCompleted => 'Завершённые';
  @override String get casesNoCases => 'Нет заявок';

  @override String get statusNew => 'Новая';
  @override String get statusInProgress => 'В работе';
  @override String get statusCompleted => 'Завершена';
  @override String get statusRejected => 'Отклонена';
  @override String get statusPaid => 'Оплачена';
  @override String get statusPendingPayment => 'Ожидает оплаты';

  @override String get propertyApartment => 'Квартира';
  @override String get propertyHouse => 'Дом';
  @override String get propertyLand => 'Участок';
  @override String get propertyCommercial => 'Коммерческая';

  @override String get newAppTitle => 'Новая заявка';
  @override String get newAppPropertyType => 'Тип недвижимости';
  @override String get newAppAddress => 'Адрес объекта';
  @override String get newAppArea => 'Площадь (м²)';
  @override String get newAppRooms => 'Комнаты';
  @override String get newAppFloor => 'Этаж';
  @override String get newAppTotalFloors => 'Всего этажей';
  @override String get newAppOwnerType => 'Тип собственности';
  @override String get newAppSubmit => 'Создать заявку';
  @override String get newAppSuccess => 'Заявка создана!';
  @override String get newAppFillAll => 'Заполните все поля';

  @override String get docsTitle => 'Документы';
  @override String get docsUpload => 'Добавить фото';
  @override String get docsUploadHint => 'Нажмите для выбора файлов';
  @override String get docsEmpty => 'Пока нет документов';
  @override String get docsDeleteTitle => 'Удалить документ?';
  @override String get docsDeleteConfirm => 'Документ будет удалён навсегда';
  @override String get docsUploading => 'Загрузка...';
  @override String get docsFormats => 'Форматы: PDF, JPG, PNG';

  @override String get aiTitle => 'AI Оценка';
  @override String get aiPlaceholder => 'Задайте вопрос...';
  @override String get aiGreeting => 'Чем могу помочь?';
  @override String get aiGreetingSubtitle => 'Задайте вопрос об оценке недвижимости,\nотправьте фото объекта для анализа';
  @override String get aiError => 'Не удалось подключиться к AI-сервису.';
  @override String get aiSuggestions => 'Рекомендации';

  @override String get paymentTitle => 'Оплата';
  @override String get paymentMethod => 'Способ оплаты';
  @override String get paymentCard => 'Банковская карта';
  @override String get paymentKaspi => 'Kaspi';
  @override String get paymentAmount => 'СУММА К ОПЛАТЕ';
  @override String get paymentPay => 'Оплатить';
  @override String get paymentSuccess => 'Оплата прошла успешно';

  @override String get reportTitle => 'Отчёт об оценке';
  @override String get reportShare => 'Поделиться';
  @override String get reportDownloadPdf => 'Скачать PDF';
  @override String get reportView => 'Посмотреть отчёт';

  @override String get caseDetailTitle => 'Детали заявки';
  @override String get caseDetailObject => 'Детали объекта';
  @override String get caseDetailOwner => 'СВЕДЕНИЯ О СОБСТВЕННИКЕ';
  @override String get caseDetailDates => 'Даты';
  @override String get caseDetailFactors => 'Факторы стоимости дома';
  @override String get caseDetailRange => 'Диапазон оценки';
  @override String get caseDetailConfidence => 'Уверенность оценки';

  @override String get adminTitle => 'АДМИН-ПАНЕЛЬ';
  @override String get adminStats => 'СТАТИСТИКА';
  @override String get adminUsers => 'Пользователи';
  @override String get adminAppraisers => 'Оценщики';

  @override String get egovTitle => 'ЭЦП и EGOV';
  @override String get egovConnect => 'Подключить ЭЦП';
  @override String get egovConnected => 'ЭЦП подключён';
  @override String get egovNotConnected => 'ЭЦП не подключён';
  @override String get egovDisable => 'Отключить ЭЦП';
  @override String get egovDisableTitle => 'Отключить ЭЦП?';
  @override String get egovDisableContent => 'Все данные EGOV будут удалены из приложения';
  @override String get egovPinPrompt => 'Введите PIN-код';
  @override String get egovFilePrompt => 'Загрузите файл ЭЦП';
  @override String get egovFormats => 'Форматы: .p12, .pfx';
  @override String get egovDataAvailable => 'Данные EGOV доступны';
  @override String get egovAllDataWillBeRemoved => 'Все данные EGOV будут удалены из приложения';
  @override String get egovBiometricPrompt => 'Включите биометрию для защиты ЭЦП';
  @override String get egovRequireBiometric => 'Требовать отпечаток/лицо для ЭЦП';
  @override String get egovFileEmpty => 'Файл пуст';
  @override String get egovFileReadError => 'Ошибка чтения файла';

  @override String get loginTitle => 'Вход';
  @override String get loginSubtitle => 'Войдите в свой аккаунт ESEP';
  @override String get loginEmail => 'Email';
  @override String get loginPassword => 'Пароль';
  @override String get loginButton => 'Войти';
  @override String get loginButtonLoading => 'Вход...';
  @override String get loginForgotPassword => 'Забыли пароль?';
  @override String get loginNoAccount => 'Нет аккаунта? ';
  @override String get loginSignUp => 'Зарегистрироваться';
  @override String get loginError => 'Произошла ошибка. Попробуйте ещё раз.';

  @override String get regTitle => 'Регистрация';
  @override String get regSubtitle => 'Создайте аккаунт для оценки недвижимости';
  @override String get regName => 'Имя';
  @override String get regEmail => 'Email';
  @override String get regPassword => 'Пароль';
  @override String get regPasswordMin => 'Минимум 8 символов';
  @override String get regButton => 'Зарегистрироваться';
  @override String get regButtonLoading => 'Регистрация...';
  @override String get regHasAccount => 'Уже есть аккаунт? ';
  @override String get regSignIn => 'Войти';
  @override String get regTermsPrefix => 'Я согласен с ';
  @override String get regTermsLink => 'условиями использования';
  @override String get regSuccess => 'Аккаунт создан! Проверьте email для подтверждения';

  @override String get splashTitle => 'ОЦЕНКА НЕДВИЖИМОСТИ';
  @override String get splashSubtitle => 'Профессиональная оценка недвижимости в Казахстане';
}

// ── Kazakh ──────────────────────────────────────────────────

class _Kk implements StringsBase {
  const _Kk();

  @override String get appName => 'ESEP';
  @override String get save => 'Сақтау';
  @override String get cancel => 'Бас тарту';
  @override String get delete => 'Жою';
  @override String get close => 'Жабу';
  @override String get back => 'Артқа';
  @override String get loading => 'Жүктелуде...';
  @override String get error => 'Қате';
  @override String get retry => 'Қайталау';

  @override String get navHome => 'Басты бет';
  @override String get navCases => 'Өтініштер';
  @override String get navAi => 'AI';
  @override String get navDocuments => 'Құжаттар';
  @override String get navProfile => 'Профиль';

  @override String get homeGreetingMorning => 'Қайырлы таң';
  @override String get homeGreetingAfternoon => 'Қайырлы күн';
  @override String get homeGreetingEvening => 'Қайырлы кеш';
  @override String get homeCurrentApplication => 'Ағымдағы өтініш';
  @override String get homeContinueWork => 'Жұмысты жалғастыру';
  @override String get homeNewApplication => 'Жаңа өтініш';
  @override String get homeDocuments => 'Құжаттар';
  @override String get homePayment => 'Төлем';
  @override String get homeEvaluate => 'Бағалау';
  @override String get homeRecentApplications => 'Соңғы өтініштер';
  @override String get homeAll => 'Барлығы →';
  @override String get homeNoApplications => 'Әлі өтініштер жоқ';

  @override String get profileTitle => 'Профиль';
  @override String get profileTab => 'Профиль';
  @override String get settingsTab => 'Баптаулар';
  @override String get profileVerified => 'Расталған';
  @override String get profileEdit => 'Профильді өңдеу';
  @override String get profileEditTitle => 'Профильді өңдеу';
  @override String get profileName => 'Толық аты';
  @override String get profilePhone => 'Телефон';
  @override String get profileIin => 'ЖСН';
  @override String get profileRole => 'Рөл';
  @override String get profileRoleClient => 'Клиент';
  @override String get profileRoleAppraiser => 'Бағалаушы';
  @override String get profileRoleAdmin => 'Әкімші';
  @override String get profileObjects => 'Объектілер';
  @override String get profileDocuments => 'Құжаттар';
  @override String get profileEvaluations => 'Бағалаулар';
  @override String get profileMyProperty => 'МЕНІҢ МҮЛКІМ';
  @override String get profileMyDocuments => 'МЕНІҢ ҚҰЖАТТАРЫМ';
  @override String get profileHistory => 'БАҒАЛАУ ТАРИХЫ';
  @override String get profileNoProperty => 'Әлі мүлік жоқ';
  @override String get profileNoDocuments => 'Әлі құжат жоқ';
  @override String get profileNoHistory => 'Әлі бағалау жоқ';
  @override String get profileHelp => 'Көмек';
  @override String get profileAbout => 'Қосымша туралы';
  @override String get profileSignOut => 'Шығу';
  @override String get profileSignOutTitle => 'Аккаунттан шығу керек пе?';
  @override String get profileSignOutContent => 'Сіз қайта кіре аласыз';
  @override String get profileNameEmpty => 'Толық атыңызды енгізіңіз';
  @override String get profileUpdated => 'Профиль жаңартылды';
  @override String get profileEgovTitle => 'МЕМЛЕКЕТТІК ҚЫЗМЕТТЕР (EGOV)';
  @override String get profileEgovSubtitle => 'Мемлекеттік қызметтерге қосылу';
  @override String get profileEgovOpen => 'Ашу';

  @override String get settingsTitle => 'Баптаулар';
  @override String get settingsGeneral => 'Жалпы';
  @override String get settingsNotifications => 'Хабарландырулар';
  @override String get settingsNotificationsSubtitle => 'Өтініштер статусы туралы push-хабарландырулар';
  @override String get settingsLanguage => 'Тіл';
  @override String get settingsTheme => 'Тақырып';
  @override String get settingsSecurity => 'Қауіпсіздік';
  @override String get settingsBiometrics => 'Биометрия';
  @override String get settingsBiometricsSubtitle => 'Саусақ ізі / Face ID арқылы кіру';
  @override String get settingsAbout => 'Қосымша туралы';
  @override String get settingsVersion => 'Нұсқа';
  @override String get settingsTerms => 'Қолдану шарттары';
  @override String get settingsPrivacy => 'Құпиялылық саясаты';
  @override String get settingsAccount => 'Аккаунт';
  @override String get settingsDeleteAccount => 'Аккаунтты жою';
  @override String get settingsDeleteAccountTitle => 'Аккаунтты жою керек пе?';
  @override String get settingsDeleteAccountContent => 'Бұл әрекетті қайтару мүмкін емес. Барлық деректеріңіз жойылады.';
  @override String get settingsDeleteAccountComingSoon => 'Функция келесі жаңартуда қол жетімді болады';

  @override String get themeSystem => 'Жүйелік';
  @override String get themeLight => 'Ашық';
  @override String get themeDark => 'Қараңғы';

  @override String get langRussian => 'Русский';
  @override String get langKazakh => 'Қазақша';
  @override String get langEnglish => 'English';

  @override String get casesTitle => 'Өтініштер';
  @override String get casesAll => 'Барлығы';
  @override String get casesInProgress => 'Жұмыста';
  @override String get casesCompleted => 'Аяқталған';
  @override String get casesNoCases => 'Өтініштер жоқ';

  @override String get statusNew => 'Жаңа';
  @override String get statusInProgress => 'Жұмыста';
  @override String get statusCompleted => 'Аяқталды';
  @override String get statusRejected => 'Бас тартылды';
  @override String get statusPaid => 'Төленді';
  @override String get statusPendingPayment => 'Төлемді күтуде';

  @override String get propertyApartment => 'Пәтер';
  @override String get propertyHouse => 'Үй';
  @override String get propertyLand => 'Жер учаскесі';
  @override String get propertyCommercial => 'Коммерциялық';

  @override String get newAppTitle => 'Жаңа өтініш';
  @override String get newAppPropertyType => 'Мүлік түрі';
  @override String get newAppAddress => 'Объектінің мекенжайы';
  @override String get newAppArea => 'Алаңы (м²)';
  @override String get newAppRooms => 'Бөлмелер';
  @override String get newAppFloor => 'Қабат';
  @override String get newAppTotalFloors => 'Барлық қабаттар';
  @override String get newAppOwnerType => 'Мүлік иелігінің түрі';
  @override String get newAppSubmit => 'Өтініш жасау';
  @override String get newAppSuccess => 'Өтініш жасалды!';
  @override String get newAppFillAll => 'Барлық өрістерді толтырыңыз';

  @override String get docsTitle => 'Құжаттар';
  @override String get docsUpload => 'Сурет қосу';
  @override String get docsUploadHint => 'Файлдарды таңдау үшін басыңыз';
  @override String get docsEmpty => 'Әлі құжат жоқ';
  @override String get docsDeleteTitle => 'Құжатты жою керек пе?';
  @override String get docsDeleteConfirm => 'Құжат мәңгі жойылады';
  @override String get docsUploading => 'Жүктелуде...';
  @override String get docsFormats => 'Форматтар: PDF, JPG, PNG';

  @override String get aiTitle => 'AI Бағалау';
  @override String get aiPlaceholder => 'Сұрақ қойыңыз...';
  @override String get aiGreeting => 'Чем көмектесе аламын?';
  @override String get aiGreetingSubtitle => 'Мүлікті бағалау туралы сұрақ қойыңыз,\nобъектінің суретін жіберіңіз';
  @override String get aiError => 'AI қызметіне қосылу мүмкін болмады.';
  @override String get aiSuggestions => 'Ұсыныстар';

  @override String get paymentTitle => 'Төлем';
  @override String get paymentMethod => 'Төлем әдісі';
  @override String get paymentCard => 'Банк картасы';
  @override String get paymentKaspi => 'Kaspi';
  @override String get paymentAmount => 'ТӨЛЕМ СУММАСЫ';
  @override String get paymentPay => 'Төлеу';
  @override String get paymentSuccess => 'Төлем сәтті өтті';

  @override String get reportTitle => 'Бағалау есептемесі';
  @override String get reportShare => 'Бөлісу';
  @override String get reportDownloadPdf => 'PDF жүктеу';
  @override String get reportView => 'Есептемені көру';

  @override String get caseDetailTitle => 'Өтініш мәліметтері';
  @override String get caseDetailObject => 'Объект мәліметтері';
  @override String get caseDetailOwner => 'ИЕСІ ТУРАЛЫ МӘЛІМЕТТЕР';
  @override String get caseDetailDates => 'Күндер';
  @override String get caseDetailFactors => 'Үй құнының факторлары';
  @override String get caseDetailRange => 'Бағалау диапазоны';
  @override String get caseDetailConfidence => 'Бағалау сенімділігі';

  @override String get adminTitle => 'ӘКІМШІ ПАНЕЛІ';
  @override String get adminStats => 'СТАТИСТИКА';
  @override String get adminUsers => 'Пайдаланушылар';
  @override String get adminAppraisers => 'Бағалаушылар';

  @override String get egovTitle => 'ЭЦП және EGOV';
  @override String get egovConnect => 'ЭЦП қосу';
  @override String get egovConnected => 'ЭЦП қосылған';
  @override String get egovNotConnected => 'ЭЦП қосылмаған';
  @override String get egovDisable => 'ЭЦП өшіру';
  @override String get egovDisableTitle => 'ЭЦП өшіру керек пе?';
  @override String get egovDisableContent => 'EGOV-тың барлық деректері қосымшадан жойылады';
  @override String get egovPinPrompt => 'PIN-кодты енгізіңіз';
  @override String get egovFilePrompt => 'ЭЦП файлын жүктеңіз';
  @override String get egovFormats => 'Форматтар: .p12, .pfx';
  @override String get egovDataAvailable => 'EGOV деректері қол жетімді';
  @override String get egovAllDataWillBeRemoved => 'EGOV-тың барлық деректері қосымшадан жойылады';
  @override String get egovBiometricPrompt => 'ЭЦП қорғау үшін биометрияны қосыңыз';
  @override String get egovRequireBiometric => 'ЭЦП үшін саусақ ізі/бет қажет';
  @override String get egovFileEmpty => 'Файл бос';
  @override String get egovFileReadError => 'Файлды оқу қатесі';

  @override String get loginTitle => 'Кіру';
  @override String get loginSubtitle => 'ESEP аккаунтыңызға кіріңіз';
  @override String get loginEmail => 'Email';
  @override String get loginPassword => 'Құпия сөз';
  @override String get loginButton => 'Кіру';
  @override String get loginButtonLoading => 'Кіруде...';
  @override String get loginForgotPassword => 'Құпия сөзді ұмыттыңыз ба?';
  @override String get loginNoAccount => 'Аккаунт жоқ па? ';
  @override String get loginSignUp => 'Тіркелу';
  @override String get loginError => 'Қате орын алды. Қайталаңыз.';

  @override String get regTitle => 'Тіркеу';
  @override String get regSubtitle => 'Мүлікті бағалау үшін аккаунт жасаңыз';
  @override String get regName => 'Аты';
  @override String get regEmail => 'Email';
  @override String get regPassword => 'Құпия сөз';
  @override String get regPasswordMin => 'Кемінде 8 таңба';
  @override String get regButton => 'Тіркелу';
  @override String get regButtonLoading => 'Тіркелуде...';
  @override String get regHasAccount => 'Аккаунт бар ма? ';
  @override String get regSignIn => 'Кіру';
  @override String get regTermsPrefix => 'Мен келісемін ';
  @override String get regTermsLink => 'қолдану шарттарымен';
  @override String get regSuccess => 'Аккаунт жасалды! Растау үшін email-ді тексеріңіз';

  @override String get splashTitle => 'МҮЛІКТІ БАҒАЛАУ';
  @override String get splashSubtitle => 'Қазақстандағы кәсіби мүлік бағалау';
}

// ── English ─────────────────────────────────────────────────

class _En implements StringsBase {
  const _En();

  @override String get appName => 'ESEP';
  @override String get save => 'Save';
  @override String get cancel => 'Cancel';
  @override String get delete => 'Delete';
  @override String get close => 'Close';
  @override String get back => 'Back';
  @override String get loading => 'Loading...';
  @override String get error => 'Error';
  @override String get retry => 'Retry';

  @override String get navHome => 'Home';
  @override String get navCases => 'Cases';
  @override String get navAi => 'AI';
  @override String get navDocuments => 'Documents';
  @override String get navProfile => 'Profile';

  @override String get homeGreetingMorning => 'Good morning';
  @override String get homeGreetingAfternoon => 'Good afternoon';
  @override String get homeGreetingEvening => 'Good evening';
  @override String get homeCurrentApplication => 'Current application';
  @override String get homeContinueWork => 'Continue working';
  @override String get homeNewApplication => 'New application';
  @override String get homeDocuments => 'Documents';
  @override String get homePayment => 'Payment';
  @override String get homeEvaluate => 'Evaluate';
  @override String get homeRecentApplications => 'Recent applications';
  @override String get homeAll => 'All →';
  @override String get homeNoApplications => 'No applications yet';

  @override String get profileTitle => 'Profile';
  @override String get profileTab => 'Profile';
  @override String get settingsTab => 'Settings';
  @override String get profileVerified => 'Verified';
  @override String get profileEdit => 'Edit profile';
  @override String get profileEditTitle => 'Edit profile';
  @override String get profileName => 'Full name';
  @override String get profilePhone => 'Phone';
  @override String get profileIin => 'IIN';
  @override String get profileRole => 'Role';
  @override String get profileRoleClient => 'Client';
  @override String get profileRoleAppraiser => 'Appraiser';
  @override String get profileRoleAdmin => 'Administrator';
  @override String get profileObjects => 'Objects';
  @override String get profileDocuments => 'Documents';
  @override String get profileEvaluations => 'Evaluations';
  @override String get profileMyProperty => 'MY PROPERTY';
  @override String get profileMyDocuments => 'MY DOCUMENTS';
  @override String get profileHistory => 'EVALUATION HISTORY';
  @override String get profileNoProperty => 'No property yet';
  @override String get profileNoDocuments => 'No documents yet';
  @override String get profileNoHistory => 'No evaluations yet';
  @override String get profileHelp => 'Help';
  @override String get profileAbout => 'About';
  @override String get profileSignOut => 'Sign out';
  @override String get profileSignOutTitle => 'Sign out?';
  @override String get profileSignOutContent => 'You can sign in again later';
  @override String get profileNameEmpty => 'Enter your full name';
  @override String get profileUpdated => 'Profile updated';
  @override String get profileEgovTitle => 'GOV SERVICES (EGOV)';
  @override String get profileEgovSubtitle => 'Connect to Gov services';
  @override String get profileEgovOpen => 'Open';

  @override String get settingsTitle => 'Settings';
  @override String get settingsGeneral => 'General';
  @override String get settingsNotifications => 'Notifications';
  @override String get settingsNotificationsSubtitle => 'Push notifications for application status';
  @override String get settingsLanguage => 'Language';
  @override String get settingsTheme => 'Theme';
  @override String get settingsSecurity => 'Security';
  @override String get settingsBiometrics => 'Biometrics';
  @override String get settingsBiometricsSubtitle => 'Login with fingerprint / Face ID';
  @override String get settingsAbout => 'About';
  @override String get settingsVersion => 'Version';
  @override String get settingsTerms => 'Terms of Service';
  @override String get settingsPrivacy => 'Privacy Policy';
  @override String get settingsAccount => 'Account';
  @override String get settingsDeleteAccount => 'Delete account';
  @override String get settingsDeleteAccountTitle => 'Delete account?';
  @override String get settingsDeleteAccountContent => 'This action is irreversible. All your data will be deleted.';
  @override String get settingsDeleteAccountComingSoon => 'This feature will be available in the next update';

  @override String get themeSystem => 'System';
  @override String get themeLight => 'Light';
  @override String get themeDark => 'Dark';

  @override String get langRussian => 'Русский';
  @override String get langKazakh => 'Қазақша';
  @override String get langEnglish => 'English';

  @override String get casesTitle => 'Cases';
  @override String get casesAll => 'All';
  @override String get casesInProgress => 'In progress';
  @override String get casesCompleted => 'Completed';
  @override String get casesNoCases => 'No cases';

  @override String get statusNew => 'New';
  @override String get statusInProgress => 'In progress';
  @override String get statusCompleted => 'Completed';
  @override String get statusRejected => 'Rejected';
  @override String get statusPaid => 'Paid';
  @override String get statusPendingPayment => 'Pending payment';

  @override String get propertyApartment => 'Apartment';
  @override String get propertyHouse => 'House';
  @override String get propertyLand => 'Land';
  @override String get propertyCommercial => 'Commercial';

  @override String get newAppTitle => 'New Application';
  @override String get newAppPropertyType => 'Property type';
  @override String get newAppAddress => 'Property address';
  @override String get newAppArea => 'Area (m²)';
  @override String get newAppRooms => 'Rooms';
  @override String get newAppFloor => 'Floor';
  @override String get newAppTotalFloors => 'Total floors';
  @override String get newAppOwnerType => 'Ownership type';
  @override String get newAppSubmit => 'Create application';
  @override String get newAppSuccess => 'Application created!';
  @override String get newAppFillAll => 'Fill in all fields';

  @override String get docsTitle => 'Documents';
  @override String get docsUpload => 'Add photo';
  @override String get docsUploadHint => 'Tap to select files';
  @override String get docsEmpty => 'No documents yet';
  @override String get docsDeleteTitle => 'Delete document?';
  @override String get docsDeleteConfirm => 'Document will be permanently deleted';
  @override String get docsUploading => 'Uploading...';
  @override String get docsFormats => 'Formats: PDF, JPG, PNG';

  @override String get aiTitle => 'AI Evaluation';
  @override String get aiPlaceholder => 'Ask a question...';
  @override String get aiGreeting => 'How can I help?';
  @override String get aiGreetingSubtitle => 'Ask about property evaluation,\nsend photos for analysis';
  @override String get aiError => 'Could not connect to AI service.';
  @override String get aiSuggestions => 'Suggestions';

  @override String get paymentTitle => 'Payment';
  @override String get paymentMethod => 'Payment method';
  @override String get paymentCard => 'Bank card';
  @override String get paymentKaspi => 'Kaspi';
  @override String get paymentAmount => 'AMOUNT TO PAY';
  @override String get paymentPay => 'Pay';
  @override String get paymentSuccess => 'Payment successful';

  @override String get reportTitle => 'Evaluation Report';
  @override String get reportShare => 'Share';
  @override String get reportDownloadPdf => 'Download PDF';
  @override String get reportView => 'View report';

  @override String get caseDetailTitle => 'Case Details';
  @override String get caseDetailObject => 'Object Details';
  @override String get caseDetailOwner => 'OWNER INFORMATION';
  @override String get caseDetailDates => 'Dates';
  @override String get caseDetailFactors => 'Property value factors';
  @override String get caseDetailRange => 'Valuation range';
  @override String get caseDetailConfidence => 'Valuation confidence';

  @override String get adminTitle => 'ADMIN PANEL';
  @override String get adminStats => 'STATISTICS';
  @override String get adminUsers => 'Users';
  @override String get adminAppraisers => 'Appraisers';

  @override String get egovTitle => 'Digital Signature & EGOV';
  @override String get egovConnect => 'Connect digital signature';
  @override String get egovConnected => 'Digital signature connected';
  @override String get egovNotConnected => 'Digital signature not connected';
  @override String get egovDisable => 'Disable digital signature';
  @override String get egovDisableTitle => 'Disable digital signature?';
  @override String get egovDisableContent => 'All EGOV data will be removed from the app';
  @override String get egovPinPrompt => 'Enter PIN code';
  @override String get egovFilePrompt => 'Upload digital signature file';
  @override String get egovFormats => 'Formats: .p12, .pfx';
  @override String get egovDataAvailable => 'EGOV data available';
  @override String get egovAllDataWillBeRemoved => 'All EGOV data will be removed from the app';
  @override String get egovBiometricPrompt => 'Enable biometrics to protect your digital signature';
  @override String get egovRequireBiometric => 'Require biometric for digital signature';
  @override String get egovFileEmpty => 'File is empty';
  @override String get egovFileReadError => 'Error reading file';

  @override String get loginTitle => 'Sign In';
  @override String get loginSubtitle => 'Sign in to your ESEP account';
  @override String get loginEmail => 'Email';
  @override String get loginPassword => 'Password';
  @override String get loginButton => 'Sign In';
  @override String get loginButtonLoading => 'Signing in...';
  @override String get loginForgotPassword => 'Forgot password?';
  @override String get loginNoAccount => "Don't have an account? ";
  @override String get loginSignUp => 'Sign Up';
  @override String get loginError => 'An error occurred. Please try again.';

  @override String get regTitle => 'Sign Up';
  @override String get regSubtitle => 'Create an account for property evaluation';
  @override String get regName => 'Name';
  @override String get regEmail => 'Email';
  @override String get regPassword => 'Password';
  @override String get regPasswordMin => 'Minimum 8 characters';
  @override String get regButton => 'Sign Up';
  @override String get regButtonLoading => 'Signing up...';
  @override String get regHasAccount => 'Already have an account? ';
  @override String get regSignIn => 'Sign In';
  @override String get regTermsPrefix => 'I agree to the ';
  @override String get regTermsLink => 'terms of service';
  @override String get regSuccess => 'Account created! Check your email for verification';

  @override String get splashTitle => 'PROPERTY EVALUATION';
  @override String get splashSubtitle => 'Professional property evaluation in Kazakhstan';
}

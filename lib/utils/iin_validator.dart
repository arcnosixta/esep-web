/// Валидатор казахстанских идентификационных номеров (ИИН/БИН).
///
/// ИИН (физлицо) и БИН (юрлицо) — 12 цифр. Контрольная цифра:
/// взвешенная сумма первых 11 цифр по модулю 11; если остаток 10 —
/// пересчёт с альтернативными весами. Первые 6 цифр — дата рождения
/// (регистрации) в формате YYMMDD (месяц 01-12, день 01-31).
library;

class IinValidationResult {
  const IinValidationResult({
    required this.valid,
    this.error = '',
    this.isOrg = false,
  });

  final bool valid;
  final String error;

  /// true, если номер похож на БИН юрлица: у ИИН 7-я цифра — код века/пола
  /// (1-8), у БИН — десятки кода региона (0-2). Однозначно на БИН указывают
  /// 0 и 9 (таких кодов у ИИН не бывает). Это подсказка, а не точная
  /// классификация — тип клиента задаётся явно в профиле.
  final bool isOrg;
}

/// Данные, декодированные из номера ИИН (не зависят от того, что указал
/// пользователь в профиле — «настоящая» часть идентификации).
class IinInfo {
  const IinInfo({
    required this.isOrg,
    this.birthDateLabel = '',
    this.gender = '',
    this.centuryLabel = '',
  });

  final bool isOrg;

  /// Дата рождения, например «15 мая 1985 г.» (для физлица).
  final String birthDateLabel;

  /// «Мужской» / «Женский».
  final String gender;

  /// «XX век» / «XXI век» и т.п.
  final String centuryLabel;
}

class IinValidator {
  IinValidator._();

  static const _weights1 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
  static const _weights2 = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];

  /// Проверяет ИИН/БИН (12 цифр + контрольная цифра + правдоподобная дата).
  static IinValidationResult validate(String raw) {
    final s = raw.replaceAll(RegExp(r'[\s\-]'), '');
    if (s.isEmpty) {
      return const IinValidationResult(valid: false, error: 'Введите ИИН/БИН');
    }
    if (!RegExp(r'^\d{12}$').hasMatch(s)) {
      return const IinValidationResult(
        valid: false,
        error: 'ИИН/БИН — 12 цифр (например, 900101123456)',
      );
    }

    // Первые 6 цифр — дата YYMMDD.
    final month = int.parse(s.substring(2, 4));
    final day = int.parse(s.substring(4, 6));
    if (month < 1 || month > 12) {
      return const IinValidationResult(
        valid: false,
        error: 'Некорректная дата в ИИН (месяц)',
      );
    }
    if (day < 1 || day > 31) {
      return const IinValidationResult(
        valid: false,
        error: 'Некорректная дата в ИИН (день)',
      );
    }

    // Контрольная цифра (модуль 11, двойные веса).
    final digits = s.split('').map(int.parse).toList();
    var check = _checksum(digits, _weights1);
    if (check == 10) check = _checksum(digits, _weights2);

    if (check != digits[11]) {
      return const IinValidationResult(
        valid: false,
        error: 'Контрольная цифра не совпадает — проверьте номер',
      );
    }

    // 7-я цифра: у ИИН это код века/пола (1-8), у БИН — десятки кода
    // региона. Однозначно на БИН указывают 0 и 9 (у ИИН таких кодов нет).
    final isOrg = digits[6] == 0 || digits[6] == 9;

    return IinValidationResult(valid: true, isOrg: isOrg);
  }

  /// Декодирует из номера то, что зашито в сам ИИН: дату рождения, пол и
  /// век рождения. Для БИН (юрлица) возвращает только isOrg=true.
  /// Возвращает null для невалидного номера.
  static IinInfo? decode(String raw) {
    final check = validate(raw);
    if (!check.valid) return null;
    final digits = raw.split('').map(int.parse).toList();
    if (check.isOrg) return const IinInfo(isOrg: true);

    // Код века/пола: 1/2 → 19xx, 3/4 → 20xx, 5/6 → 21xx, 7/8 → 22xx;
    // нечётный → мужской, чётный → женский.
    final code = digits[6];
    final male = code.isOdd;
    var centuryOffset = ((code - 1) ~/ 2); // 0 → 19xx, 1 → 20xx, ...
    var yearBase = 1900 + centuryOffset * 100;

    final yy = int.parse(raw.substring(0, 2));
    final mm = int.parse(raw.substring(2, 4));
    final dd = int.parse(raw.substring(4, 6));

    // «Мягкий» век: у части выдач код века сдвинут на 1 (например, код 5
    // у родившихся в 2000-х). Дата рождения живого человека не может быть
    // в будущем — если получилась, откатываем на 100 лет.
    var year = yearBase + yy;
    final nowYear = DateTime.now().year;
    while (year > nowYear && centuryOffset > 0) {
      year -= 100;
      centuryOffset -= 1;
      yearBase -= 100;
    }

    final centuryLabel = _centuryNames[centuryOffset];

    String birthLabel;
    if (yy == 0 && mm == 0 && dd == 0) {
      // Служебные ИИН без даты рождения.
      birthLabel = 'Не указана (служебный номер)';
    } else {
      birthLabel = '$dd ${_monthNames[mm - 1]} $year г.';
    }

    return IinInfo(
      isOrg: false,
      birthDateLabel: birthLabel,
      gender: male ? 'Мужской' : 'Женский',
      centuryLabel: centuryLabel,
    );
  }

  static const _monthNames = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];

  static const _centuryNames = [
    'XX век (1900-1999)',
    'XXI век (2000-2099)',
    'XXII век (2100-2199)',
    'XXIII век (2200-2299)',
  ];

  static int _checksum(List<int> digits, List<int> weights) {
    var sum = 0;
    for (var i = 0; i < 11; i++) {
      sum += digits[i] * weights[i];
    }
    return sum % 11;
  }
}

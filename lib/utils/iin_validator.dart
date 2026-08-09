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

  static int _checksum(List<int> digits, List<int> weights) {
    var sum = 0;
    for (var i = 0; i < 11; i++) {
      sum += digits[i] * weights[i];
    }
    return sum % 11;
  }
}

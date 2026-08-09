import 'ncalayer_impl_stub.dart'
    if (dart.library.html) 'ncalayer_impl_web.dart'
    if (dart.library.io) 'ncalayer_impl_io.dart' as impl;

/// Результат вызова NCALayer.
class NcalayerResult {
  const NcalayerResult({
    this.success = false,
    this.message,
    this.responseObject,
    this.error,
  });

  final bool success;

  /// Человекочитаемое сообщение от NCALayer (например, путь к подписанному файлу).
  final String? message;

  /// Сырой responseObject от NCALayer (Map или String).
  final dynamic responseObject;

  /// Текст ошибки (для UI).
  final String? error;
}

/// Клиент NCALayer (НУЦ РК) — локальный WebSocket-агент ЭЦП.
///
/// Протокол восстановлен из ezsigner.kz (АО «НИТ») — старый JSON-RPC:
///   запрос:  {"module": "...", "lang": "ru", "method": "...", "args": [...]}
///   ответ:   {"code": "200", "responseObject": ...}  |  {"errorCode": "NONE", ...}
///   ошибка:  {"code": "4xx", "message": "..."} | {"errorCode": "MODULE_NOT_FOUND"}
///
/// NCALayer слушает localhost:13579 (wss:// и ws://). Подпись выполняется
/// системными диалогами NCALayer (выбор файла, ключа, PIN) — приватный ключ
/// не покидает машину пользователя.
class NcalayerService {
  NcalayerService._();

  /// Проверяет, запущен ли NCALayer (пробует подключиться к localhost:13579).
  static Future<bool> isAvailable() => impl.NcalayerImpl.isAvailable();

  /// Подписывает документ через NCALayer:
  /// 1. getFilePath — системный диалог выбора файла;
  /// 2. signFilePath — подпись (диалог выбора ключа + PIN) → сохранение .cms.
  ///
  /// [storage] — имя хранилища ключей (по умолчанию PKCS12, как в ezSigner).
  static Future<NcalayerResult> signDocument({String storage = 'PKCS12'}) =>
      impl.NcalayerImpl.signDocument(storage: storage);
}

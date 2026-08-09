import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'ncalayer_service.dart';

/// Desktop-реализация NCALayer (Windows/Linux/macOS): dart:io WebSocket.
///
/// NCALayer поддерживается на десктопе, поэтому нативные сборки ESEP
/// тоже могут подписывать документы. Используем plain ws://127.0.0.1:13579/
/// (TLS с самоподписанным сертификатом нативный клиент не проверяет).
class NcalayerImpl {
  static const _url = 'ws://127.0.0.1:13579/';

  static Future<bool> isAvailable() async {
    try {
      final ws = await WebSocket.connect(_url).timeout(const Duration(seconds: 3));
      await ws.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<NcalayerResult> signDocument({String storage = 'PKCS12'}) async {
    // 1. Системный диалог выбора файла.
    final fileRes = await _call('kz.gov.pki.cms.CMSSignUtil', 'getFilePath', ['all', '']);
    if (!fileRes.success) {
      return fileRes.error == null
          ? const NcalayerResult(error: 'Файл не выбран')
          : fileRes;
    }

    final obj = fileRes.responseObject;
    final filePath = (obj is Map) ? obj['path']?.toString() : null;
    if (filePath == null || filePath.isEmpty) {
      return const NcalayerResult(error: 'Файл не выбран');
    }

    // 2. Подпись файла: NCALayer сам спросит ключ и PIN,
    //    сохранит .cms рядом с исходным файлом.
    return _call('kz.gov.pki.cms.CMSSignUtil', 'signFilePath', [filePath, '', storage]);
  }

  static Future<NcalayerResult> _call(
    String module,
    String method,
    List<dynamic> args,
  ) async {
    WebSocket? ws;
    try {
      ws = await WebSocket.connect(_url).timeout(const Duration(seconds: 3));
    } catch (_) {
      return const NcalayerResult(
        error:
            'Не удалось подключиться к NCALayer. Убедитесь, что программа запущена, и повторите попытку.',
      );
    }

    try {
      final request = jsonEncode({
        'module': module,
        'lang': 'ru',
        'method': method,
        'args': args,
      });
      final response = await _request(ws, request);
      return _parseResponse(response);
    } finally {
      await ws.close();
    }
  }

  static Future<Map<String, dynamic>> _request(WebSocket ws, String request) async {
    final completer = Completer<Map<String, dynamic>>();
    final sub = ws.listen((data) {
      if (data is String) {
        try {
          completer.complete(jsonDecode(data) as Map<String, dynamic>);
        } catch (_) {
          completer.completeError(const FormatException('Невалидный ответ NCALayer'));
        }
      }
    });

    try {
      ws.add(request);
      return await completer.future.timeout(const Duration(seconds: 120));
    } finally {
      sub.cancel();
    }
  }

  static NcalayerResult _parseResponse(Map<String, dynamic> resp) {
    if (resp['code'] == '200' || resp['errorCode'] == 'NONE') {
      return NcalayerResult(
        success: true,
        message: resp['message']?.toString(),
        responseObject: resp['responseObject'],
      );
    }

    if (resp['errorCode'] == 'MODULE_NOT_FOUND') {
      return const NcalayerResult(
        error:
            "Необходимо установить дополнительный модуль 'NLDocSignerModule' в приложении NCALayer (НУЦ РК).",
      );
    }

    final message = resp['message']?.toString();
    return NcalayerResult(
      error: message == null || message.isEmpty
          ? 'Ошибка NCALayer (${resp['code'] ?? resp['errorCode']})'
          : message,
    );
  }
}

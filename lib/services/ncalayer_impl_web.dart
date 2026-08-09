import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'ncalayer_service.dart';

/// Web-реализация NCALayer: WebSocket из браузера (dart:html).
///
/// С https-страницы браузеры разрешают подключение к localhost
/// (secure-context exception), поэтому wss://127.0.0.1:13579/ работает;
/// при сбое TLS пробуем plain ws://127.0.0.1:13579/.
class NcalayerImpl {
  static const _urls = <String>[
    'wss://127.0.0.1:13579/',
    'ws://127.0.0.1:13579/',
  ];

  static Future<bool> isAvailable() async {
    for (final url in _urls) {
      final ws = html.WebSocket(url);
      try {
        await ws.onOpen.first.timeout(const Duration(seconds: 3));
        ws.close();
        return true;
      } catch (_) {
        // переходим к следующему URL
      }
    }
    return false;
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
    final ws = await _connect();
    if (ws == null) {
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
      ws.close();
    }
  }

  static Future<html.WebSocket?> _connect() async {
    for (final url in _urls) {
      final ws = html.WebSocket(url);
      try {
        await ws.onOpen.first.timeout(const Duration(seconds: 3));
        return ws;
      } catch (_) {
        // пробуем следующий URL
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>> _request(html.WebSocket ws, String request) async {
    final completer = Completer<Map<String, dynamic>>();
    final sub = ws.onMessage.listen((event) {
      final data = event.data;
      if (data is String) {
        try {
          completer.complete(jsonDecode(data) as Map<String, dynamic>);
        } catch (_) {
          completer.completeError(const FormatException('Невалидный ответ NCALayer'));
        }
      }
    });

    try {
      ws.send(request);
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

import 'ncalayer_service.dart';

/// Заглушка для платформ без NCALayer (Android/iOS).
///
/// На мобильных устройствах NCALayer не устанавливается — там работает
/// только eGov mobile (QR-подписание, отдельная интеграция). UI должен
/// показывать фолбэк: подписать вручную через ezsigner.kz.
class NcalayerImpl {
  static Future<bool> isAvailable() async => false;

  static Future<NcalayerResult> signDocument({String storage = 'PKCS12'}) async {
    return const NcalayerResult(
      error: 'NCALayer недоступен на этом устройстве. Подпишите документ на ezsigner.kz и загрузите .cms файл.',
    );
  }
}

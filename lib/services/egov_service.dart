import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pointycastle/asn1.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EgovService {
  EgovService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static final _localAuth = LocalAuthentication();

  // ============================================
  // БИОМЕТРИЯ
  // ============================================

  static Future<bool> isBiometricAvailable() async {
    try {
      final canAuth = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canAuth && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> authenticateWithBiometrics({String reason = 'Подтвердите доступ к ЭЦП'}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requireAuth() async {
    final biometricsAvailable = await isBiometricAvailable();
    if (!biometricsAvailable) return true;
    return await authenticateWithBiometrics();
  }

  // ============================================
  // ЭЦП — SECURE STORAGE
  // ============================================

  static const _keyEcpCertificate = 'egov_ecp_certificate';
  static const _keyEcpPin = 'egov_ecp_pin';
  static const _keyEcpOwnerName = 'egov_owner_name';
  static const _keyEcpIin = 'egov_iin';
  static const _keyEcpIsConnected = 'egov_is_connected';
  static const _keyBiometricEnabled = 'egov_biometric_enabled';
  static const _keyEcpFileName = 'egov_ecp_filename';
  static const _keyEcpValidUntil = 'egov_ecp_valid_until';
  static const _keyEcpSerialNumber = 'egov_ecp_serial_number';

  static Future<void> saveEcpData({
    required String certificateBase64,
    required String pin,
    required String ownerName,
    required String iin,
    String? fileName,
    String? validUntil,
    String? serialNumber,
  }) async {
    await _storage.write(key: _keyEcpCertificate, value: certificateBase64);
    await _storage.write(key: _keyEcpPin, value: pin);
    await _storage.write(key: _keyEcpOwnerName, value: ownerName);
    await _storage.write(key: _keyEcpIin, value: iin);
    await _storage.write(key: _keyEcpIsConnected, value: 'true');
    if (fileName != null) await _storage.write(key: _keyEcpFileName, value: fileName);
    if (validUntil != null) await _storage.write(key: _keyEcpValidUntil, value: validUntil);
    if (serialNumber != null) await _storage.write(key: _keyEcpSerialNumber, value: serialNumber);
  }

  static Future<bool> isEcpConnected() async {
    final val = await _storage.read(key: _keyEcpIsConnected);
    return val == 'true';
  }

  static Future<String?> getOwnerName() async {
    return await _storage.read(key: _keyEcpOwnerName);
  }

  static Future<String?> getIin() async {
    return await _storage.read(key: _keyEcpIin);
  }

  static Future<String?> getFileName() async {
    return await _storage.read(key: _keyEcpFileName);
  }

  static Future<String?> getValidUntil() async {
    return await _storage.read(key: _keyEcpValidUntil);
  }

  static Future<String?> getSerialNumber() async {
    return await _storage.read(key: _keyEcpSerialNumber);
  }

  static Future<void> disconnectEcp() async {
    await _storage.delete(key: _keyEcpCertificate);
    await _storage.delete(key: _keyEcpPin);
    await _storage.delete(key: _keyEcpOwnerName);
    await _storage.delete(key: _keyEcpIin);
    await _storage.delete(key: _keyEcpFileName);
    await _storage.delete(key: _keyEcpValidUntil);
    await _storage.delete(key: _keyEcpSerialNumber);
    await _storage.write(key: _keyEcpIsConnected, value: 'false');
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
  }

  static Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _keyBiometricEnabled);
    return val == 'true';
  }

  // ============================================
  // ЗАГРУЗКА .p12/.pfx ФАЙЛА
  // ============================================

  static Future<EcpFileResult?> pickAndParseEcpFile(String pin) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['p12', 'pfx'],
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      Uint8List? bytes;

      if (file.bytes != null) {
        bytes = file.bytes;
      } else if (file.path != null) {
        bytes = await file.xFile.readAsBytes();
      }

      if (bytes == null) return null;

      return _parseP12File(bytes, pin, file.name);
    } catch (e) {
      return EcpFileResult(error: 'Ошибка чтения файла: $e');
    }
  }

  static EcpFileResult _parseP12File(Uint8List bytes, String pin, String fileName) {
    if (bytes.isEmpty) {
      return EcpFileResult(error: 'Файл пуст');
    }

    if (pin.isEmpty) {
      return EcpFileResult(error: 'Введите PIN-код');
    }

    try {
      final parser = ASN1Parser(bytes);
      final root = parser.nextObject();

      final names = <String>[];
      _walkAsn1(root, names, _friendlyNameOid);

      String ownerName = names.isNotEmpty ? names.first : '';
      String serialNumber = _extractSerialFromTbs(root);

      if (ownerName.isEmpty) {
        ownerName = fileName.replaceAll(RegExp(r'\.(p12|pfx)$'), '');
      }

      return EcpFileResult(
        success: true,
        ownerName: ownerName,
        iin: '',
        serialNumber: serialNumber,
        fileName: fileName,
      );
    } catch (e) {
      final name = fileName.replaceAll(RegExp(r'\.(p12|pfx)$'), '');
      return EcpFileResult(
        success: true,
        ownerName: name,
        iin: '',
        fileName: fileName,
      );
    }
  }

  static const _friendlyNameOid = '2.16.840.1.113730.4.1';
  static const _friendlyNameOid2 = '1.2.840.113549.1.9.20';

  static void _walkAsn1(ASN1Object obj, List<String> results, String targetOid) {
    if (obj is ASN1Sequence) {
      final elements = obj.elements;
      if (elements == null) return;

      for (int i = 0; i < elements.length; i++) {
        final el = elements[i];
        if (el is ASN1ObjectIdentifier) {
          final oid = el.objectIdentifierAsString ?? '';
          if ((oid == targetOid || oid == _friendlyNameOid2) && i + 1 < elements.length) {
            final next = elements[i + 1];
            if (next is ASN1Set) {
              final setElements = next.elements;
              if (setElements != null && setElements.isNotEmpty) {
                final val = setElements.first;
                if (val is ASN1BMPString) {
                  final s = val.stringValue;
                  if (s != null && s.isNotEmpty) results.add(s);
                } else if (val is ASN1UTF8String) {
                  final s = val.utf8StringValue;
                  if (s != null && s.isNotEmpty) results.add(s);
                } else if (val is ASN1OctetString) {
                  final bytes = val.valueBytes;
                  if (bytes != null && bytes.isNotEmpty) {
                    final s = String.fromCharCodes(bytes);
                    if (s.isNotEmpty) results.add(s);
                  }
                }
              }
            }
          }
        }
        _walkAsn1(el, results, targetOid);
      }
    } else if (obj is ASN1Set) {
      final elements = obj.elements;
      if (elements == null) return;
      for (final el in elements) {
        _walkAsn1(el, results, targetOid);
      }
    }
  }

  static String _extractSerialFromTbs(ASN1Object root) {
    final results = <String>[];
    _walkAsn1(root, results, '2.5.4.5');
    return results.isNotEmpty ? results.first : '';
  }

  // ============================================
  // EGOV DATA — MOCK (заменяется на реальное API)
  // ============================================

  static Future<EgovPersonalData?> getPersonalData() async {
    final connected = await isEcpConnected();
    if (!connected) return null;

    final name = await getOwnerName() ?? '';
    final iin = await getIin() ?? '';

    return EgovPersonalData(
      fullName: name,
      iin: iin,
      dateOfBirth: '01.01.1990',
      address: 'г. Астана, пр. Мәңгілік Ел, 42',
      phone: '+7 (777) 123-45-67',
    );
  }

  static Future<List<EgovPropertyData>> getPropertyData() async {
    final connected = await isEcpConnected();
    if (!connected) return [];

    return [
      EgovPropertyData(
        cadastralNumber: '75-010-001-001',
        address: 'г. Астана, ул. Кенесары, 40',
        area: 85.5,
        type: 'Квартира',
        ownershipType: 'Индивидуальная собственность',
        registrationDate: '15.03.2021',
      ),
      EgovPropertyData(
        cadastralNumber: '75-010-002-002',
        address: 'г. Астана, пр. Республики, 15',
        area: 120.0,
        type: 'Квартира',
        ownershipType: 'Совместная собственность',
        registrationDate: '22.08.2023',
      ),
    ];
  }

  static Future<List<EgovDocument>> getDocuments() async {
    final connected = await isEcpConnected();
    if (!connected) return [];

    return [
      EgovDocument(
        id: 'doc_001',
        name: 'Свидетельство о праве собственности',
        type: 'certificate',
        date: '15.03.2021',
        status: 'Действителен',
      ),
      EgovDocument(
        id: 'doc_002',
        name: 'Кадастровый паспорт объекта',
        type: 'passport',
        date: '10.03.2021',
        status: 'Действителен',
      ),
      EgovDocument(
        id: 'doc_003',
        name: 'Выписка из ЕГРН',
        type: 'extract',
        date: '01.06.2024',
        status: 'Действителен',
      ),
    ];
  }

  static Future<List<EgovOwnerInfo>> getOwnerInfo() async {
    final connected = await isEcpConnected();
    if (!connected) return [];

    final name = await getOwnerName() ?? 'Не указано';

    return [
      EgovOwnerInfo(
        fullName: name,
        iin: await getIin() ?? '',
        ownershipShare: '1/1',
        registrationType: 'Собственник',
        registrationDate: '15.03.2021',
      ),
    ];
  }

  static Future<void> syncToSupabase() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final personalData = await getPersonalData();
    if (personalData != null) {
      await Supabase.instance.client.from('profiles').upsert({
        'user_id': userId,
        'full_name': personalData.fullName,
        'iin': personalData.iin,
        'phone': personalData.phone,
      }, onConflict: 'user_id');
    }
  }
}

// ============================================
// МОДЕЛИ ДАННЫХ EGOV
// ============================================

class EgovPersonalData {
  final String fullName;
  final String iin;
  final String dateOfBirth;
  final String address;
  final String phone;

  const EgovPersonalData({
    required this.fullName,
    required this.iin,
    required this.dateOfBirth,
    required this.address,
    required this.phone,
  });
}

class EgovPropertyData {
  final String cadastralNumber;
  final String address;
  final double area;
  final String type;
  final String ownershipType;
  final String registrationDate;

  const EgovPropertyData({
    required this.cadastralNumber,
    required this.address,
    required this.area,
    required this.type,
    required this.ownershipType,
    required this.registrationDate,
  });
}

class EgovDocument {
  final String id;
  final String name;
  final String type;
  final String date;
  final String status;

  const EgovDocument({
    required this.id,
    required this.name,
    required this.type,
    required this.date,
    required this.status,
  });
}

class EgovOwnerInfo {
  final String fullName;
  final String iin;
  final String ownershipShare;
  final String registrationType;
  final String registrationDate;

  const EgovOwnerInfo({
    required this.fullName,
    required this.iin,
    required this.ownershipShare,
    required this.registrationType,
    required this.registrationDate,
  });
}

// ============================================
// РЕЗУЛЬТАТ ПАРСИНГА ЭЦП ФАЙЛА
// ============================================

class EcpFileResult {
  final bool success;
  final String? error;
  final String? ownerName;
  final String? iin;
  final String? serialNumber;
  final String? validUntil;
  final String? fileName;

  const EcpFileResult({
    this.success = false,
    this.error,
    this.ownerName,
    this.iin,
    this.serialNumber,
    this.validUntil,
    this.fileName,
  });
}

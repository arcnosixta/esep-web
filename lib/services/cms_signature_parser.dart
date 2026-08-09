import 'dart:typed_data';

import 'package:pointycastle/asn1.dart';

/// Данные подписанта, извлечённые из CMS-подписи (PKCS#7).
class CmsSignatureInfo {
  const CmsSignatureInfo({
    required this.signerName,
    required this.signerIin,
    this.organization = '',
  });

  /// ФИО подписанта (CN из сертификата).
  final String signerName;

  /// ИИН подписанта (serialNumber из subject сертификата).
  final String signerIin;

  /// Организация (O), если указана в сертификате.
  final String organization;

  bool get hasName => signerName.isNotEmpty;
}

/// Парсер CMS (отделённой ЭЦП-подписи, .cms).
///
/// CMS = PKCS#7 SignedData: SEQUENCE { OID signedData, [0] SignedData }.
/// Внутри SignedData лежит набор сертификатов (certificates) — берём первый
/// и читаем subject: CN (2.5.4.3) = ФИО, serialNumber (2.5.4.5) = ИИН,
/// O (2.5.4.10) = организация (по стандарту НУЦ РК).
class CmsSignatureParser {
  CmsSignatureParser._();

  static const _oidCn = '2.5.4.3';
  static const _oidSerialNumber = '2.5.4.5';
  static const _oidOrganization = '2.5.4.10';

  static CmsSignatureInfo? parse(Uint8List cmsBytes) {
    if (cmsBytes.isEmpty) return null;

    try {
      final parser = ASN1Parser(cmsBytes);
      final root = parser.nextObject();

      final cnValues = <String>[];
      final serialValues = <String>[];
      final orgValues = <String>[];
      _walk(root, _oidCn, cnValues);
      _walk(root, _oidSerialNumber, serialValues);
      _walk(root, _oidOrganization, orgValues);

      final name = cnValues.isNotEmpty ? cnValues.first.trim() : '';
      var iin = serialValues.isNotEmpty ? serialValues.first.trim() : '';

      // Старые сертификаты НУЦ: ИИН не в serialNumber, а хвостом в CN
      // («ФАМИЛИЯ ИМЯ ОТЧЕСТВО 890101123456»).
      if (iin.isEmpty && name.isNotEmpty) {
        final match = RegExp(r'\b(\d{12})\b').firstMatch(name);
        if (match != null) iin = match.group(1)!;
      }

      if (name.isEmpty && iin.isEmpty) return null;

      return CmsSignatureInfo(
        signerName: name,
        signerIin: iin,
        organization: orgValues.isNotEmpty ? orgValues.first.trim() : '',
      );
    } catch (_) {
      return null;
    }
  }

  static void _walk(ASN1Object obj, String targetOid, List<String> results) {
    List<ASN1Object>? elements;
    if (obj is ASN1Sequence) {
      elements = obj.elements;
    } else if (obj is ASN1Set) {
      elements = obj.elements;
    }

    if (elements != null) {
      for (int i = 0; i < elements.length; i++) {
        final el = elements[i];
        if (el is ASN1ObjectIdentifier) {
          final oid = el.objectIdentifierAsString ?? '';
          if (oid == targetOid && i + 1 < elements.length) {
            final value = _stringValue(elements[i + 1]);
            if (value != null && value.isNotEmpty) results.add(value);
          }
        }
        _walk(el, targetOid, results);
      }
    } else if (obj.isConstructed == true && obj.valueBytes != null) {
      // Контекстные теги [0]/[1] (в CMS: обёртка SignedData и certificates)
      // pointycastle парсит в «ванильный» ASN1Object — пере-парсим содержимое.
      try {
        final parser = ASN1Parser(obj.valueBytes!);
        while (parser.hasNext()) {
          _walk(parser.nextObject(), targetOid, results);
        }
      } catch (_) {
        // невалидный узел — пропускаем
      }
    }
  }

  static String? _stringValue(ASN1Object obj) {
    if (obj is ASN1UTF8String) return obj.utf8StringValue;
    if (obj is ASN1PrintableString) return obj.stringValue;
    if (obj is ASN1BMPString) return obj.stringValue;
    if (obj is ASN1OctetString) {
      final bytes = obj.valueBytes;
      if (bytes != null && bytes.isNotEmpty) return String.fromCharCodes(bytes);
    }
    return null;
  }
}

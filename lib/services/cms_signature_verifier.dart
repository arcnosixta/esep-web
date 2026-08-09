import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/digests/sha1.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/digests/sha384.dart';
import 'package:pointycastle/digests/sha512.dart';
import 'package:pointycastle/signers/rsa_signer.dart';

import 'cms_signature_parser.dart';

/// Результат криптографической проверки CMS-подписи.
class CmsVerificationResult {
  const CmsVerificationResult({
    required this.verified,
    required this.message,
    this.signer,
  });

  final bool verified;
  final String message;
  final CmsSignatureInfo? signer;
}

/// Криптографическая проверка CMS (PKCS#7) подписи.
///
/// Проверяет подпись SignerInfo поверх DER-кодировки signedAttrs
/// (RFC 5652 §5.4: подпись считается по signedAttrs включая тег 0xA0/длину).
/// Поддерживается RSA (PKCS#1 v1.5) с SHA-1/256/384/512 — основной случай
/// сертификатов НУЦ РК. Для других алгоритмов (GOST 34.10, ECDSA)
/// возвращает понятное сообщение «не поддерживается» — полную проверку
/// цепочки можно сделать на ezsigner.kz/#!/checkCMS.
class CmsSignatureVerifier {
  CmsSignatureVerifier._();

  static const _oidSignedData = '1.2.840.113549.1.7.2';
  static const _oidRsa = '1.2.840.113549.1.1.1';

  static const _oidSha1WithRsa = '1.2.840.113549.1.1.5';
  static const _oidSha256WithRsa = '1.2.840.113549.1.1.11';
  static const _oidSha384WithRsa = '1.2.840.113549.1.1.12';
  static const _oidSha512WithRsa = '1.2.840.113549.1.1.13';

  // Hex-кодировка DigestIdentifier (OID-узел с тегом 06 и длиной).
  // Полный DigestInfo (SEQUENCE + OCTET STRING хэша) RSASigner собирает сам.
  static const _prefixSha1 = '06052b0e03021a';
  static const _prefixSha256 = '0609608648016503040201';
  static const _prefixSha384 = '0609608648016503040202';
  static const _prefixSha512 = '0609608648016503040203';

  static CmsVerificationResult verify(Uint8List cmsBytes) {
    try {
      final parser = ASN1Parser(cmsBytes);
      final root = parser.nextObject();

      final signedData = _findSignedData(root);
      if (signedData == null) {
        return const CmsVerificationResult(
          verified: false,
          message: 'Это не CMS-подпись (PKCS#7 SignedData)',
        );
      }

      final cert = _firstCertificate(signedData);
      final rsaKey = cert == null ? null : _rsaPublicKeyFromCert(cert);
      if (rsaKey == null) {
        return const CmsVerificationResult(
          verified: false,
          message:
              'В подписи нет сертификата с RSA-ключом — полная проверка доступна на ezsigner.kz/#!/checkCMS',
        );
      }

      final signerInfo = _firstSignerInfo(signedData);
      if (signerInfo is! ASN1Sequence || signerInfo.elements == null) {
        return const CmsVerificationResult(
          verified: false,
          message: 'В CMS не найден блок подписанта (SignerInfo)',
        );
      }
      final siEls = signerInfo.elements!;
      if (siEls.length < 6) {
        return const CmsVerificationResult(
          verified: false,
          message: 'Структура SignerInfo повреждена',
        );
      }

      final sigAlg = _oidOfSequence(siEls[4]);
      final signature = _signatureBytes(siEls[5]);
      final attrsEl = siEls[3];

      if (sigAlg == null || signature == null) {
        return const CmsVerificationResult(
          verified: false,
          message: 'Структура SignerInfo повреждена',
        );
      }

      // signedAttrs = [0] IMPLICIT SET OF Attribute. pointycastle парсит
      // контекстный тег в «ванильный» ASN1Object — для проверки нужен полный
      // TLV (0xA0 + длина + содержимое), т.е. encodedBytes.
      if (attrsEl.isConstructed != true || attrsEl.encodedBytes == null) {
        return const CmsVerificationResult(
          verified: false,
          message:
              'Подпись без атрибутов (нельзя проверить без исходного документа)',
        );
      }
      final signedBytes = attrsEl.encodedBytes!;

      final (digest, oidHex) = _digestFor(sigAlg);
      if (digest == null || oidHex == null) {
        return CmsVerificationResult(
          verified: false,
          message:
              'Алгоритм подписи $sigAlg не поддерживается (поддерживается RSA/SHA-1,256,384,512). Полная проверка — ezsigner.kz/#!/checkCMS',
        );
      }

      final signer = RSASigner(digest, oidHex)
        ..init(false, PublicKeyParameter<RSAPublicKey>(rsaKey));
      final ok = signer.verifySignature(signedBytes, RSASignature(signature));

      return CmsVerificationResult(
        verified: ok,
        message: ok
            ? 'Подпись криптографически действительна (RSA)'
            : 'Подпись НЕ прошла проверку — документ или подпись изменены',
        signer: CmsSignatureParser.parse(cmsBytes),
      );
    } catch (e) {
      return CmsVerificationResult(
        verified: false,
        message: 'Не удалось разобрать подпись: $e',
      );
    }
  }

  // ---------- разбор структуры ----------

  static ASN1Object? _findSignedData(ASN1Object root) {
    if (root is! ASN1Sequence || root.elements == null) return null;
    final els = root.elements!;
    if (els.length < 2) return null;
    final oid = els[0];
    if (oid is! ASN1ObjectIdentifier ||
        oid.objectIdentifierAsString != _oidSignedData) {
      return null;
    }
    // ContentInfo.content = [0] EXPLICIT SignedData — содержимое в valueBytes.
    final wrapper = els[1];
    if (wrapper.valueBytes == null) return null;
    final p = ASN1Parser(wrapper.valueBytes!);
    return p.hasNext() ? p.nextObject() : null;
  }

  /// Поле certificates: [0] IMPLICIT CertificateSet (контекстный тег 0xA0).
  static ASN1Object? _certsField(ASN1Object signedData) {
    if (signedData is! ASN1Sequence) return null;
    final els = signedData.elements;
    if (els == null) return null;
    for (final el in els) {
      if (el.tag != null && el.tag == 0xA0) return el;
    }
    return null;
  }

  static ASN1Object? _firstCertificate(ASN1Object signedData) {
    final certs = _certsField(signedData);
    if (certs == null || certs.valueBytes == null) return null;
    final p = ASN1Parser(certs.valueBytes!);
    if (!p.hasNext()) return null;
    final first = p.nextObject();
    if (first is ASN1Sequence) {
      // [0] IMPLICIT: содержимое — сразу сертификат (без SET-заголовка).
      return first;
    }
    if (first is ASN1Set && first.elements != null && first.elements!.isNotEmpty) {
      // Редкий [0] EXPLICIT SET OF Certificate.
      return first.elements!.first;
    }
    return null;
  }

  static ASN1Object? _firstSignerInfo(ASN1Object signedData) {
    if (signedData is! ASN1Sequence) return null;
    final els = signedData.elements;
    if (els == null || els.isEmpty) return null;
    // signerInfos — последний элемент SignedData (SET OF SignerInfo;
    // в простых CMS без CRL/вложенных подписей идёт сразу после certificates).
    final last = els.last;
    if (last is ASN1Set && last.elements != null && last.elements!.isNotEmpty) {
      return last.elements!.first;
    }
    return null;
  }

  static String? _oidOfSequence(ASN1Object? seq) {
    if (seq is! ASN1Sequence || seq.elements == null || seq.elements!.isEmpty) {
      return null;
    }
    final oid = seq.elements!.first;
    if (oid is ASN1ObjectIdentifier) return oid.objectIdentifierAsString;
    return null;
  }

  static Uint8List? _signatureBytes(ASN1Object? obj) {
    if (obj is! ASN1OctetString) return null;
    return obj.valueBytes;
  }

  static (dynamic, String?) _digestFor(String oid) {
    switch (oid) {
      case _oidSha1WithRsa:
        return (SHA1Digest(), _prefixSha1);
      case _oidSha256WithRsa:
        return (SHA256Digest(), _prefixSha256);
      case _oidSha384WithRsa:
        return (SHA384Digest(), _prefixSha384);
      case _oidSha512WithRsa:
        return (SHA512Digest(), _prefixSha512);
      default:
        return (null, null);
    }
  }

  /// Извлекает RSA-ключ из сертификата X.509 (subjectPublicKeyInfo).
  static RSAPublicKey? _rsaPublicKeyFromCert(ASN1Object cert) {
    try {
      // Certificate ::= SEQUENCE { tbsCertificate, sigAlg, sigValue }
      final tbs = _element(cert, 0);
      if (tbs is! ASN1Sequence || tbs.elements == null) return null;
      final els = tbs.elements!;

      // Ищем subjectPublicKeyInfo: SEQUENCE {
      //   algorithm SEQUENCE { OID rsaEncryption, NULL },
      //   BIT STRING }
      ASN1Object? spki;
      for (final el in els) {
        if (el is! ASN1Sequence || el.elements == null || el.elements!.length < 2) {
          continue;
        }
        final alg = el.elements![0];
        if (alg is ASN1Sequence && alg.elements != null && alg.elements!.isNotEmpty) {
          final oid = alg.elements![0];
          if (oid is ASN1ObjectIdentifier &&
              oid.objectIdentifierAsString == _oidRsa) {
            spki = el;
            break;
          }
        }
      }
      if (spki == null) return null;

      final bitString = _element(spki, 1);
      // stringValues уже без байта unused-bits.
      if (bitString is! ASN1BitString || bitString.stringValues == null) {
        return null;
      }

      // subjectPublicKey: BIT STRING → DER SEQUENCE { INTEGER n, INTEGER e }
      final p = ASN1Parser(Uint8List.fromList(bitString.stringValues!));
      final keySeq = p.nextObject();
      if (keySeq is! ASN1Sequence ||
          keySeq.elements == null ||
          keySeq.elements!.length < 2) {
        return null;
      }
      final n = keySeq.elements![0];
      final e = keySeq.elements![1];
      if (n is! ASN1Integer || e is! ASN1Integer) return null;
      if (n.integer == null || e.integer == null) return null;

      return RSAPublicKey(n.integer!, e.integer!);
    } catch (_) {
      return null;
    }
  }

  /// Элемент последовательности по индексу; для контекстно-тегированных
  /// [0]-обёрток (vanilla ASN1Object) возвращает внутренний объект.
  static ASN1Object? _element(ASN1Object seq, int index) {
    if (seq is! ASN1Sequence || seq.elements == null) return null;
    final els = seq.elements!;
    if (index >= els.length) return null;
    final el = els[index];
    if (el.isConstructed == true && el.valueBytes != null) {
      final p = ASN1Parser(el.valueBytes!);
      if (p.hasNext()) {
        final inner = p.nextObject();
        if (inner is ASN1Sequence || inner is ASN1Set) return inner;
        return el;
      }
    }
    return el;
  }
}

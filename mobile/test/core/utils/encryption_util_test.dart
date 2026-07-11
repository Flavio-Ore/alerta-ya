import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:alertaya/core/utils/encryption_util.dart';

// Clave pública RSA-2048 de prueba (no sensible, solo para tests).
const _testPublicKeyPem = '''
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7P7cLcLhbz4BEQGfDSz+
Xr3ZXrhBksBwzbVGU9mOrgTvT0OtLpfzOI6+ZzWd/SCmnj3CTcX3ODfWHXwjLryk
d4kjFVOON4YSAT52vbwDvHPFkV8cHYoOcsEeljd+41Hwbr2f1VyZdQAXZLFU8qMq
ZbzYYOYPkljyDoPU4PGjWnLT4L5WL/Cm8qyqcEb4hN/OQ9b/6ZUaHz5zfsYV1hBX
lMoIm/s5UphYiygXhEmSnPxhZa0Qm9lzilsnnYry1PLiPMrWnXQXJzqxr+3DOhqD
zGqOHKIBbxMt5/ysxbUP1vwX+4GxnVHL+1p/rDl2PY00W6NfWfMDfbRQZSAA30bs
TwIDAQAB
-----END PUBLIC KEY-----
''';

void main() {
  group('EncryptionUtil — AES-256-GCM', () {
    test('generateKey produce 32 bytes distintos en cada llamada', () {
      final k1 = EncryptionUtil.generateKey();
      final k2 = EncryptionUtil.generateKey();

      expect(k1.length, 32);
      expect(k1, isNot(equals(k2)));
    });

    test('encrypt + decrypt hace roundtrip del plaintext original', () {
      final key = EncryptionUtil.generateKey();
      final plaintext = Uint8List.fromList(utf8.encode('audio de prueba'));

      final blob = EncryptionUtil.encrypt(plaintext, key);
      final decrypted = EncryptionUtil.decrypt(blob, key);

      expect(utf8.decode(decrypted), 'audio de prueba');
    });

    test('el blob cifrado tiene el formato IV(12) || ciphertext || tag(16)', () {
      final key = EncryptionUtil.generateKey();
      final plaintext = Uint8List.fromList(utf8.encode('x'));

      final blob = EncryptionUtil.encrypt(plaintext, key);

      // 12 (IV) + 1 (ciphertext de 1 byte) + 16 (tag) = 29
      expect(blob.length, 29);
    });

    test('decrypt lanza si el blob fue alterado (autenticación GCM)', () {
      final key = EncryptionUtil.generateKey();
      final plaintext = Uint8List.fromList(utf8.encode('audio de prueba'));
      final blob = EncryptionUtil.encrypt(plaintext, key);

      final tampered = Uint8List.fromList(blob);
      tampered[tampered.length - 1] ^= 0xFF; // corrompe el último byte del tag

      expect(() => EncryptionUtil.decrypt(tampered, key), throwsA(anything));
    });

    test('decrypt lanza con la clave equivocada', () {
      final key = EncryptionUtil.generateKey();
      final otherKey = EncryptionUtil.generateKey();
      final plaintext = Uint8List.fromList(utf8.encode('audio de prueba'));
      final blob = EncryptionUtil.encrypt(plaintext, key);

      expect(() => EncryptionUtil.decrypt(blob, otherKey), throwsA(anything));
    });
  });

  group('EncryptionUtil — wrapKeyRsaOaep', () {
    test('devuelve 256 bytes (RSA-2048) distintos del plaintext', () {
      final aesKey = EncryptionUtil.generateKey();

      final wrapped = EncryptionUtil.wrapKeyRsaOaep(aesKey, _testPublicKeyPem);

      expect(wrapped.length, 256);
      expect(wrapped, isNot(equals(aesKey)));
    });

    test('dos llamadas con la misma clave producen ciphertexts distintos (OAEP es probabilístico)', () {
      final aesKey = EncryptionUtil.generateKey();

      final wrapped1 = EncryptionUtil.wrapKeyRsaOaep(aesKey, _testPublicKeyPem);
      final wrapped2 = EncryptionUtil.wrapKeyRsaOaep(aesKey, _testPublicKeyPem);

      expect(wrapped1, isNot(equals(wrapped2)));
    });
  });
}

import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart' as pc;

/// AES-256-GCM para cifrar grabaciones del pánico antes de subir a Storage.
/// Formato del blob: IV(12) || ciphertext || tag(16) — GCM autentica el
/// contenido: un blob alterado o una clave equivocada lanzan excepción en
/// decrypt(), a diferencia del CBC anterior que no detectaba manipulación.
///
/// wrapKeyRsaOaep envuelve la clave AES con la pública RSA-OAEP-SHA256 de
/// Cloud KMS para el flujo de key escrow (ver docs/superpowers/specs/
/// 2026-07-10-panic-key-escrow-design.md).
class EncryptionUtil {
  EncryptionUtil._();

  static const int _keyLength = 32; // 256 bits
  static const int _gcmIvLength = 12; // 96 bits — tamaño recomendado NIST para GCM
  static const int _gcmTagLength = 16; // 128 bits

  static Uint8List generateKey() => enc.Key.fromSecureRandom(_keyLength).bytes;

  static Uint8List encrypt(Uint8List plaintext, Uint8List keyBytes) {
    final key = enc.Key(keyBytes);
    final iv = enc.IV.fromSecureRandom(_gcmIvLength);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encryptBytes(plaintext, iv: iv);
    return Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
  }

  static Uint8List decrypt(Uint8List blob, Uint8List keyBytes) {
    if (blob.length < _gcmIvLength + _gcmTagLength) {
      throw ArgumentError('Blob cifrado inválido: demasiado corto');
    }
    final key = enc.Key(keyBytes);
    final iv = enc.IV(Uint8List.fromList(blob.sublist(0, _gcmIvLength)));
    final ciphertextAndTag = enc.Encrypted(Uint8List.fromList(blob.sublist(_gcmIvLength)));
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    return Uint8List.fromList(encrypter.decryptBytes(ciphertextAndTag, iv: iv));
  }

  static Uint8List wrapKeyRsaOaep(Uint8List aesKey, String publicKeyPem) {
    final publicKey = CryptoUtils.rsaPublicKeyFromPem(publicKeyPem);
    final cipher = pc.OAEPEncoding.withSHA256(pc.RSAEngine())
      ..init(true, pc.PublicKeyParameter<pc.RSAPublicKey>(publicKey));
    return cipher.process(aesKey);
  }
}

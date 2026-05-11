import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;

/// AES-256-CBC para cifrar grabaciones del pánico antes de subir a GCS.
/// Protocolo: encrypt() prefija el IV (16 bytes) al ciphertext para que
/// decrypt() pueda recuperarlo sin almacenarlo por separado.
///
/// Gestión de clave (FASE 4): generar una vez con generateKey(),
/// persistir con flutter_secure_storage, recuperar en cada sesión de pánico.
class EncryptionUtil {
  EncryptionUtil._();

  static const int _keyLength = 32; // 256 bits
  static const int _ivLength = 16; // 128 bits — tamaño de bloque AES

  /// Genera una clave aleatoria segura de 256 bits.
  static Uint8List generateKey() =>
      enc.Key.fromSecureRandom(_keyLength).bytes;

  /// Cifra [plaintext] con AES-256-CBC usando [keyBytes].
  /// Retorna IV (16 bytes) + ciphertext concatenados.
  static Uint8List encrypt(Uint8List plaintext, Uint8List keyBytes) {
    final key = enc.Key(keyBytes);
    final iv = enc.IV.fromSecureRandom(_ivLength);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(plaintext, iv: iv);
    return Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
  }

  /// Descifra [ciphertext] producido por [encrypt].
  /// Espera IV (16 bytes) + ciphertext en los primeros bytes.
  static Uint8List decrypt(Uint8List ciphertext, Uint8List keyBytes) {
    final key = enc.Key(keyBytes);
    final iv = enc.IV(Uint8List.fromList(ciphertext.sublist(0, _ivLength)));
    final data =
        enc.Encrypted(Uint8List.fromList(ciphertext.sublist(_ivLength)));
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    return Uint8List.fromList(encrypter.decryptBytes(data, iv: iv));
  }
}

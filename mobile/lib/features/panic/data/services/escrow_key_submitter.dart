import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/utils/encryption_util.dart';
import 'package:alertaya/features/panic/data/datasources/escrow_remote_datasource.dart';

/// Envuelve la clave AES de una sesión con la pública RSA-OAEP de escrow y
/// la sube al backend, con reintentos con backoff lineal.
@injectable
class EscrowKeySubmitter {
  const EscrowKeySubmitter(this._escrow);
  final EscrowRemoteDataSource _escrow;

  Future<bool> submit({
    required String sessionId,
    required Uint8List aesKey,
    int attempts = 3,
  }) async {
    for (var attempt = 1; attempt <= attempts; attempt++) {
      try {
        final publicKey = await _escrow.fetchPublicKey();
        final wrapped = EncryptionUtil.wrapKeyRsaOaep(aesKey, publicKey.pem);
        await _escrow.submitEscrowKey(
          sessionId: sessionId,
          wrappedKeyBase64: base64Encode(wrapped),
          kmsKeyVersion: publicKey.keyVersion,
        );
        return true;
      } catch (e) {
        debugPrint('[EscrowKeySubmitter] intento $attempt falló: $e');
        if (attempt < attempts) {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
    return false;
  }
}

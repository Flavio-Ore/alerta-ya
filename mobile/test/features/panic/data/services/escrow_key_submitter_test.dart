import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:alertaya/features/panic/data/datasources/escrow_remote_datasource.dart';
import 'package:alertaya/features/panic/data/services/escrow_key_submitter.dart';

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

class _FakeEscrowRemoteDataSource implements EscrowRemoteDataSource {
  _FakeEscrowRemoteDataSource({this.failCount = 0});

  final int failCount;
  int submitCalls = 0;
  Map<String, dynamic>? lastSubmitArgs;

  @override
  Future<({String pem, String keyVersion})> fetchPublicKey() async {
    return (pem: _testPublicKeyPem, keyVersion: '1');
  }

  @override
  Future<void> submitEscrowKey({
    required String sessionId,
    required String wrappedKeyBase64,
    required String kmsKeyVersion,
  }) async {
    submitCalls++;
    lastSubmitArgs = {
      'sessionId': sessionId,
      'wrappedKeyBase64': wrappedKeyBase64,
      'kmsKeyVersion': kmsKeyVersion,
    };
    if (submitCalls <= failCount) {
      throw Exception('fallo simulado intento $submitCalls');
    }
  }

  @override
  Future<void> registerBlock({
    required String sessionId,
    required int blockIndex,
    required String storagePath,
  }) async {}
}

void main() {
  group('EscrowKeySubmitter', () {
    test('devuelve true y llama submitEscrowKey una vez si no hay fallos', () async {
      final fake = _FakeEscrowRemoteDataSource();
      final submitter = EscrowKeySubmitter(fake);
      final aesKey = Uint8List(32);

      final ok = await submitter.submit(sessionId: 'ses-1', aesKey: aesKey);

      expect(ok, isTrue);
      expect(fake.submitCalls, 1);
      expect(fake.lastSubmitArgs!['sessionId'], 'ses-1');
      expect(fake.lastSubmitArgs!['kmsKeyVersion'], '1');
    });

    test('reintenta hasta lograr éxito dentro del límite de intentos', () async {
      final fake = _FakeEscrowRemoteDataSource(failCount: 2);
      final submitter = EscrowKeySubmitter(fake);
      final aesKey = Uint8List(32);

      final ok = await submitter.submit(sessionId: 'ses-1', aesKey: aesKey, attempts: 3);

      expect(ok, isTrue);
      expect(fake.submitCalls, 3);
    });

    test('devuelve false si se agotan los intentos', () async {
      final fake = _FakeEscrowRemoteDataSource(failCount: 5);
      final submitter = EscrowKeySubmitter(fake);
      final aesKey = Uint8List(32);

      final ok = await submitter.submit(sessionId: 'ses-1', aesKey: aesKey, attempts: 2);

      expect(ok, isFalse);
      expect(fake.submitCalls, 2);
    });
  });
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alertaya/features/panic/data/datasources/escrow_remote_datasource.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);
  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);
}

ResponseBody _jsonResponse(Map<String, dynamic> body, int statusCode) {
  final bytes = utf8.encode(jsonEncode(body));
  return ResponseBody.fromBytes(
    bytes,
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  late Dio dio;
  late EscrowRemoteDataSourceImpl dataSource;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
    dataSource = EscrowRemoteDataSourceImpl(dio);
  });

  group('fetchPublicKey', () {
    test('devuelve el PEM y la versión cuando el backend responde 200', () async {
      dio.httpClientAdapter = _FakeAdapter((options) async {
        expect(options.path, '/panic/escrow/public-key');
        return _jsonResponse({
          'publicKeyPem': '-----BEGIN PUBLIC KEY-----\nABC\n-----END PUBLIC KEY-----',
          'kmsKeyVersion': '1',
        }, 200);
      });

      final result = await dataSource.fetchPublicKey();

      expect(result.pem, contains('BEGIN PUBLIC KEY'));
      expect(result.keyVersion, '1');
    });
  });

  group('submitEscrowKey', () {
    test('envía el wrapped key al endpoint correcto con algorithm fijo', () async {
      RequestOptions? captured;
      dio.httpClientAdapter = _FakeAdapter((options) async {
        captured = options;
        return _jsonResponse({}, 201);
      });

      await dataSource.submitEscrowKey(
        sessionId: 'ses-1',
        wrappedKeyBase64: 'd2FubmVk',
        kmsKeyVersion: '1',
      );

      expect(captured!.path, '/panic/sessions/ses-1/escrow-key');
      expect(captured!.method, 'POST');
      expect(captured!.data, {
        'wrappedKey': 'd2FubmVk',
        'kmsKeyVersion': '1',
        'algorithm': 'RSA_OAEP_256',
      });
    });
  });

  group('registerBlock', () {
    test('registra el bloque subido en el endpoint correcto', () async {
      RequestOptions? captured;
      dio.httpClientAdapter = _FakeAdapter((options) async {
        captured = options;
        return _jsonResponse({}, 201);
      });

      await dataSource.registerBlock(
        sessionId: 'ses-1',
        blockIndex: 2,
        storagePath: 'gs://bucket/path.bin',
      );

      expect(captured!.path, '/panic/sessions/ses-1/blocks');
      expect(captured!.data, {'blockIndex': 2, 'storagePath': 'gs://bucket/path.bin'});
    });
  });
}

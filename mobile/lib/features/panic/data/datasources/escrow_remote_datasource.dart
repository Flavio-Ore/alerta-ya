import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/exceptions.dart';

abstract class EscrowRemoteDataSource {
  Future<({String pem, String keyVersion})> fetchPublicKey();

  Future<void> submitEscrowKey({
    required String sessionId,
    required String wrappedKeyBase64,
    required String kmsKeyVersion,
  });

  Future<void> registerBlock({
    required String sessionId,
    required int blockIndex,
    required String storagePath,
  });
}

@LazySingleton(as: EscrowRemoteDataSource)
class EscrowRemoteDataSourceImpl implements EscrowRemoteDataSource {
  const EscrowRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<({String pem, String keyVersion})> fetchPublicKey() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/panic/escrow/public-key');
      final data = response.data!;
      return (pem: data['publicKeyPem'] as String, keyVersion: data['kmsKeyVersion'] as String);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw ServerException(statusCode: e.response?.statusCode ?? 500, message: e.message);
    }
  }

  @override
  Future<void> submitEscrowKey({
    required String sessionId,
    required String wrappedKeyBase64,
    required String kmsKeyVersion,
  }) async {
    try {
      await _dio.post<void>(
        '/panic/sessions/$sessionId/escrow-key',
        data: {
          'wrappedKey': wrappedKeyBase64,
          'kmsKeyVersion': kmsKeyVersion,
          'algorithm': 'RSA_OAEP_256',
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw ServerException(statusCode: e.response?.statusCode ?? 500, message: e.message);
    }
  }

  @override
  Future<void> registerBlock({
    required String sessionId,
    required int blockIndex,
    required String storagePath,
  }) async {
    try {
      await _dio.post<void>(
        '/panic/sessions/$sessionId/blocks',
        data: {'blockIndex': blockIndex, 'storagePath': storagePath},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw ServerException(statusCode: e.response?.statusCode ?? 500, message: e.message);
    }
  }
}

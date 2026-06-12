import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/exceptions.dart';
import 'package:alertaya/features/panic/domain/entities/panic_start_result.dart';
import 'package:alertaya/features/panic/data/models/panic_session_model.dart';

abstract class PanicRemoteDataSource {
  Future<PanicStartResult> startSession({
    required double lat,
    required double lng,
  });
  Future<void> stopSession(String sessionId);
}

@LazySingleton(as: PanicRemoteDataSource)
class PanicRemoteDataSourceImpl implements PanicRemoteDataSource {
  const PanicRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<PanicStartResult> startSession({
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/panic/sessions',
        data: {'lat': lat, 'lng': lng},
      );
      return PanicSessionModel.fromJsonFull(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw ServerException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.message,
      );
    }
  }

  @override
  Future<void> stopSession(String sessionId) async {
    try {
      await _dio.delete<void>('/panic/sessions/$sessionId');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw ServerException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.message,
      );
    }
  }
}

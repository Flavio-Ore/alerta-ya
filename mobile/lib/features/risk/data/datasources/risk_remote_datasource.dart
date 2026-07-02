import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/exceptions.dart';
import 'package:alertaya/features/risk/domain/entities/risk_info.dart';

abstract class RiskRemoteDataSource {
  Future<RiskInfo> getRisk({
    required double lat,
    required double lng,
    int? hour,
  });
}

@LazySingleton(as: RiskRemoteDataSource)
class RiskRemoteDataSourceImpl implements RiskRemoteDataSource {
  const RiskRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<RiskInfo> getRisk({
    required double lat,
    required double lng,
    int? hour,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/risk',
        queryParameters: <String, dynamic>{
          'lat': lat,
          'lng': lng,
          if (hour != null) 'hour': hour,
        },
      );
      return RiskInfo.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Exception _mapError(DioException e) => switch (e.response?.statusCode) {
        401 => const UnauthorizedException(),
        404 => const NotFoundException(),
        429 => const RateLimitException(),
        _ => ServerException(
            statusCode: e.response?.statusCode ?? 500,
            message: e.message,
          ),
      };
}

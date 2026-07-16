import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/exceptions.dart';
import 'package:alertaya/features/risk/domain/entities/risk_info.dart';
import 'package:alertaya/features/risk/domain/entities/risk_prediction.dart';

abstract class RiskRemoteDataSource {
  Future<RiskInfo> getRisk({
    required double lat,
    required double lng,
    int? hour,
  });

  Future<RiskPrediction> getPrediction({
    required double lat,
    required double lng,
    int? hour,
    int? dayOfWeek,
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

  @override
  Future<RiskPrediction> getPrediction({
    required double lat,
    required double lng,
    int? hour,
    int? dayOfWeek,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/risk/predict',
        queryParameters: <String, dynamic>{
          'lat': lat,
          'lng': lng,
          if (hour != null) 'hour': hour,
          if (dayOfWeek != null) 'dayOfWeek': dayOfWeek,
        },
      );
      return RiskPrediction.fromJson(response.data!);
    } on DioException {
      // Fail-open: la predicción ML es complementaria — si el ML service no
      // responde, no debe tumbar la pantalla de riesgo. Devolvemos "no
      // disponible" con la hora/día pedidos (o los actuales como fallback).
      final now = DateTime.now();
      return RiskPrediction.unavailable(
        hour: hour ?? now.hour,
        dayOfWeek: dayOfWeek ?? (now.weekday - 1), // Dart: 1=lunes..7=domingo → 0..6
      );
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

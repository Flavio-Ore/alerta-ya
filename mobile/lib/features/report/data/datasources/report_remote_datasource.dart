import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/exceptions.dart';
import 'package:alertaya/features/report/data/models/report_submit_result_model.dart';
import 'package:alertaya/features/report/domain/entities/incident_type.dart';
import 'package:alertaya/features/report/domain/entities/report_submit_result.dart';

abstract class ReportRemoteDataSource {
  Future<ReportSubmitResult> submitReport({
    required double lat,
    required double lng,
    required IncidentType type,
    required Map<String, dynamic> formData,
    required List<String> mediaUrls,
    DateTime? photoTakenAt,
    String? photoSource,
  });
}

@LazySingleton(as: ReportRemoteDataSource)
class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  const ReportRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<ReportSubmitResult> submitReport({
    required double lat,
    required double lng,
    required IncidentType type,
    required Map<String, dynamic> formData,
    required List<String> mediaUrls,
    DateTime? photoTakenAt,
    String? photoSource,
  }) async {
    try {
      final body = <String, dynamic>{
        'lat': lat,
        'lng': lng,
        'type': type.value,
        'formData': formData,
        'mediaUrls': mediaUrls,
        if (photoTakenAt != null)
          'photoTakenAt': photoTakenAt.toUtc().toIso8601String(),
        if (photoSource != null) 'photoSource': photoSource,
      };

      final response = await _dio.post<Map<String, dynamic>>(
        '/incidents/reports',
        data: body,
      );

      final statusCode = response.statusCode ?? 0;
      final responseBody = response.data ?? <String, dynamic>{};

      if (statusCode == 200 || statusCode == 201) {
        return ReportSubmitResultModel.fromResponse(
          statusCode: statusCode,
          body: responseBody,
        );
      }

      throw ServerException(
        statusCode: statusCode,
        message: 'Respuesta inesperada del servidor',
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      final serverMessage = data is Map<String, dynamic>
          ? data['message'] as String?
          : null;

      switch (status) {
        case 401:
          throw const UnauthorizedException();
        case 422:
          throw ValidationException(
            serverMessage ?? 'La ubicación está fuera de Lima',
          );
        case 429:
          throw RateLimitException(
            serverMessage ?? 'Llegaste al límite de reportes',
          );
        default:
          throw ServerException(
            statusCode: status ?? 0,
            message: serverMessage ?? e.message,
          );
      }
    }
  }
}

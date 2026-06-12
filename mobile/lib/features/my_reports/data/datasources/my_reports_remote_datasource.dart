import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/exceptions.dart';
import 'package:alertaya/features/my_reports/data/models/my_reports_page_model.dart';
import 'package:alertaya/features/my_reports/domain/entities/my_report_entity.dart';

abstract class MyReportsRemoteDataSource {
  Future<MyReportsPage> getMine({int page = 1, int pageSize = 20});
  Future<void> cancelReport(String reportId);
}

@LazySingleton(as: MyReportsRemoteDataSource)
class MyReportsRemoteDataSourceImpl implements MyReportsRemoteDataSource {
  const MyReportsRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<MyReportsPage> getMine({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/incidents/reports/mine',
        queryParameters: <String, dynamic>{
          'page': page,
          'pageSize': pageSize,
        },
      );
      return MyReportsPageModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> cancelReport(String reportId) async {
    try {
      await _dio.delete<void>('/incidents/reports/$reportId');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Exception _mapError(DioException e) => switch (e.response?.statusCode) {
        401 => const UnauthorizedException(),
        404 => const ServerException(statusCode: 404, message: 'Reporte no encontrado'),
        409 => const ServerException(
            statusCode: 409,
            message: 'El reporte ya fue publicado y no puede cancelarse',
          ),
        _ => ServerException(
            statusCode: e.response?.statusCode ?? 500,
            message: e.message,
          ),
      };
}

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/exceptions.dart';
import 'package:alertaya/features/incidents/domain/entities/incident_entity.dart';
import 'package:alertaya/features/incidents/data/models/incident_model.dart';

abstract class IncidentRemoteDataSource {
  Future<List<IncidentEntity>> getIncidents({
    String? severity,
    String? district,
    String? since,
    int page = 1,
    int pageSize = 20,
  });
  Future<IncidentDetailEntity> getIncidentDetail(String id);
  Future<void> confirmIncident(String id, String vote, double lat, double lng);
  Future<void> confirmZone(String zoneKey, String response);
}

@LazySingleton(as: IncidentRemoteDataSource)
class IncidentRemoteDataSourceImpl implements IncidentRemoteDataSource {
  const IncidentRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<IncidentEntity>> getIncidents({
    String? severity,
    String? district,
    String? since,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/incidents',
        queryParameters: <String, dynamic>{
          if (severity != null) 'severity': severity,
          if (district != null) 'district': district,
          if (since != null) 'since': since,
          'page': page,
          'pageSize': pageSize,
        },
      );
      // El API devuelve { items, total, page } — antes esto buscaba 'data' y crasheaba.
      final items = response.data!['items'] as List<dynamic>;
      return items.cast<Map<String, dynamic>>().map(IncidentModel.fromJson).toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<IncidentDetailEntity> getIncidentDetail(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/incidents/$id');
      return IncidentDetailModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> confirmIncident(String id, String vote, double lat, double lng) async {
    try {
      await _dio.post<void>(
        '/incidents/$id/confirm',
        data: {'vote': vote, 'lat': lat, 'lng': lng},
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> confirmZone(String zoneKey, String response) async {
    try {
      await _dio.post<void>(
        '/incidents/zone-confirmations',
        data: {'zoneKey': zoneKey, 'response': response},
      );
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

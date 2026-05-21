import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/exceptions.dart';
import 'package:alertaya/features/alerts/domain/entities/notification_entity.dart';
import 'package:alertaya/features/alerts/data/models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationEntity>> getNotifications({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 20,
  });
  Future<void> markRead({List<String> ids = const [], bool all = false});
}

@LazySingleton(as: NotificationRemoteDataSource)
class NotificationRemoteDataSourceImpl
    implements NotificationRemoteDataSource {
  const NotificationRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<NotificationEntity>> getNotifications({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/notifications',
        queryParameters: <String, dynamic>{
          'unreadOnly': unreadOnly.toString(),
          'page': page,
          'pageSize': pageSize,
        },
      );
      final data = response.data!['data'] as List<dynamic>;
      return data
          .cast<Map<String, dynamic>>()
          .map(NotificationModel.fromJson)
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw ServerException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.message,
      );
    }
  }

  @override
  Future<void> markRead(
      {List<String> ids = const [], bool all = false}) async {
    try {
      await _dio.patch<void>(
        '/notifications/read',
        data: {'ids': ids, 'all': all},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw ServerException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.message,
      );
    }
  }
}

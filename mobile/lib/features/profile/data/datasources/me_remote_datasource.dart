import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/exceptions.dart';
import 'package:alertaya/features/profile/domain/entities/user_profile_entity.dart';

abstract class MeRemoteDataSource {
  Future<UserProfileEntity> getProfile();
  Future<UserPreferencesEntity> getPreferences();
  Future<UserPreferencesEntity> updatePreferences({
    int? alertRadiusMeters,
    bool? muteNotifications,
    bool? panicRecordAudio,
    bool? panicAlarmSound,
  });
}

@LazySingleton(as: MeRemoteDataSource)
class MeRemoteDataSourceImpl implements MeRemoteDataSource {
  const MeRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<UserProfileEntity> getProfile() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/me/profile');
      final d = res.data!;
      return UserProfileEntity(
        reputationScore: d['reputationScore'] as int,
        memberSince: DateTime.parse(d['memberSince'] as String),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw ServerException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.message,
      );
    }
  }

  @override
  Future<UserPreferencesEntity> getPreferences() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/me/preferences');
      return _parsePreferences(res.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw ServerException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.message,
      );
    }
  }

  @override
  Future<UserPreferencesEntity> updatePreferences({
    int? alertRadiusMeters,
    bool? muteNotifications,
    bool? panicRecordAudio,
    bool? panicAlarmSound,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (alertRadiusMeters != null) body['alertRadiusMeters'] = alertRadiusMeters;
      if (muteNotifications != null) body['muteNotifications'] = muteNotifications;
      if (panicRecordAudio != null) body['panicRecordAudio'] = panicRecordAudio;
      if (panicAlarmSound != null) body['panicAlarmSound'] = panicAlarmSound;

      final res = await _dio.patch<Map<String, dynamic>>(
        '/me/preferences',
        data: body,
      );
      return _parsePreferences(res.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw ServerException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.message,
      );
    }
  }

  // Parser tolerante: campos panic son nuevos, defaults true si el API antiguo no los devuelve.
  UserPreferencesEntity _parsePreferences(Map<String, dynamic> d) =>
      UserPreferencesEntity(
        alertRadiusMeters: d['alertRadiusMeters'] as int,
        muteNotifications: d['muteNotifications'] as bool,
        panicRecordAudio: (d['panicRecordAudio'] as bool?) ?? true,
        panicAlarmSound: (d['panicAlarmSound'] as bool?) ?? true,
      );
}

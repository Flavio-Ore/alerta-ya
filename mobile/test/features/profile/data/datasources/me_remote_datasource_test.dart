import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:alertaya/features/profile/data/datasources/me_remote_datasource.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late MeRemoteDataSourceImpl dataSource;

  setUp(() {
    dio = _MockDio();
    dataSource = MeRemoteDataSourceImpl(dio);
  });

  Response<Map<String, dynamic>> buildResponse(Map<String, dynamic> data) =>
      Response<Map<String, dynamic>>(
        data: data,
        statusCode: 200,
        requestOptions: RequestOptions(path: '/me/profile'),
      );

  group('MeRemoteDataSourceImpl.getProfile', () {
    test('parsea level anidado en tier y pointsToNext cuando viene presente',
        () async {
      when(() => dio.get<Map<String, dynamic>>('/me/profile')).thenAnswer(
        (_) async => buildResponse({
          'reputationScore': 72,
          'memberSince': '2024-01-15T00:00:00.000Z',
          'level': {
            'tier': 'medium',
            'score': 72,
            'pointsToNext': 8,
          },
        }),
      );

      final profile = await dataSource.getProfile();

      expect(profile.reputationScore, equals(72));
      expect(profile.tier, equals('medium'));
      expect(profile.pointsToNext, equals(8));
    });

    test('es tolerante cuando level no viene en la respuesta (API vieja)',
        () async {
      when(() => dio.get<Map<String, dynamic>>('/me/profile')).thenAnswer(
        (_) async => buildResponse({
          'reputationScore': 100,
          'memberSince': '2024-01-15T00:00:00.000Z',
        }),
      );

      final profile = await dataSource.getProfile();

      expect(profile.reputationScore, equals(100));
      expect(profile.tier, isNull);
      expect(profile.pointsToNext, isNull);
    });

    test('pointsToNext null dentro de level no rompe el parseo', () async {
      when(() => dio.get<Map<String, dynamic>>('/me/profile')).thenAnswer(
        (_) async => buildResponse({
          'reputationScore': 95,
          'memberSince': '2024-01-15T00:00:00.000Z',
          'level': {
            'tier': 'high',
            'score': 95,
            'pointsToNext': null,
          },
        }),
      );

      final profile = await dataSource.getProfile();

      expect(profile.tier, equals('high'));
      expect(profile.pointsToNext, isNull);
    });
  });
}

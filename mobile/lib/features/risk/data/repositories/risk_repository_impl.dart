import 'package:injectable/injectable.dart';

import 'package:alertaya/features/risk/data/datasources/risk_remote_datasource.dart';
import 'package:alertaya/features/risk/domain/entities/risk_info.dart';
import 'package:alertaya/features/risk/domain/entities/risk_prediction.dart';
import 'package:alertaya/features/risk/domain/repositories/risk_repository.dart';

@LazySingleton(as: RiskRepository)
class RiskRepositoryImpl implements RiskRepository {
  const RiskRepositoryImpl(this._remoteDataSource);
  final RiskRemoteDataSource _remoteDataSource;

  @override
  Future<RiskInfo> getRisk({
    required double lat,
    required double lng,
    int? hour,
  }) =>
      _remoteDataSource.getRisk(lat: lat, lng: lng, hour: hour);

  @override
  Future<RiskPrediction> getPrediction({
    required double lat,
    required double lng,
    int? hour,
    int? dayOfWeek,
  }) =>
      _remoteDataSource.getPrediction(
        lat: lat,
        lng: lng,
        hour: hour,
        dayOfWeek: dayOfWeek,
      );
}

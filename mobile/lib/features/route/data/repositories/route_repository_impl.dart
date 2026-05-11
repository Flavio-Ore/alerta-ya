import 'package:dartz/dartz.dart';
import 'package:latlong2/latlong.dart';

import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/features/incidents/domain/entities/incident_entity.dart';
import 'package:alertaya/features/route/data/datasources/route_remote_datasource.dart';
import 'package:alertaya/features/route/domain/entities/route_option_entity.dart';
import 'package:alertaya/features/route/domain/repositories/route_repository.dart';

class RouteRepositoryImpl implements RouteRepository {
  const RouteRepositoryImpl(this._datasource);

  final RouteRemoteDatasource _datasource;

  @override
  Future<Either<Failure, List<RouteOptionEntity>>> compareRoutes({
    required LatLng origin,
    required LatLng destination,
    required List<IncidentEntity> incidents,
  }) async {
    try {
      final routes = await _datasource.compareRoutes(
        origin: origin,
        destination: destination,
        incidents: incidents,
      );
      return Right(routes);
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }
}

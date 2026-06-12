import 'package:dartz/dartz.dart';
import 'package:latlong2/latlong.dart';

import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/features/incidents/domain/entities/incident_entity.dart';
import 'package:alertaya/features/route/domain/entities/route_option_entity.dart';
import 'package:alertaya/features/route/domain/repositories/route_repository.dart';

class CompareRoutesParams {
  const CompareRoutesParams({
    required this.origin,
    required this.destination,
    required this.incidents,
  });

  final LatLng origin;
  final LatLng destination;
  final List<IncidentEntity> incidents;
}

class CompareRoutesUseCase {
  const CompareRoutesUseCase(this._repository);

  final RouteRepository _repository;

  Future<Either<Failure, List<RouteOptionEntity>>> call(
          CompareRoutesParams params) =>
      _repository.compareRoutes(
        origin: params.origin,
        destination: params.destination,
        incidents: params.incidents,
      );
}

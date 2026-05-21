import 'package:dartz/dartz.dart';
import 'package:latlong2/latlong.dart';

import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/features/incidents/domain/entities/incident_entity.dart';
import 'package:alertaya/features/route/domain/entities/route_option_entity.dart';

abstract class RouteRepository {
  Future<Either<Failure, List<RouteOptionEntity>>> compareRoutes({
    required LatLng origin,
    required LatLng destination,
    required List<IncidentEntity> incidents,
  });
}

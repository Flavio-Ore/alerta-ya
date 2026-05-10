import 'package:dartz/dartz.dart';

import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/features/incidents/domain/entities/incident_entity.dart';

abstract class IncidentRepository {
  Future<Either<Failure, List<IncidentEntity>>> getIncidents({
    String? severity,
    String? district,
    String? since,
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, IncidentDetailEntity>> getIncidentDetail(String id);

  Future<Either<Failure, Unit>> confirmIncident(String id, String vote);

  // Mini-alert: respuesta del ciudadano al "¿viste algo en esta zona?"
  Future<Either<Failure, Unit>> confirmZone(String zoneKey, String response);
}

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/features/incidents/domain/entities/incident_entity.dart';
import 'package:alertaya/features/incidents/domain/repositories/incident_repository.dart';

class GetIncidentsParams {
  const GetIncidentsParams({
    this.severity,
    this.district,
    this.since,
    this.page = 1,
    this.pageSize = 20,
  });
  final String? severity;
  final String? district;
  final String? since;
  final int page;
  final int pageSize;
}

@injectable
class GetIncidentsUseCase {
  const GetIncidentsUseCase(this._repository);
  final IncidentRepository _repository;

  Future<Either<Failure, List<IncidentEntity>>> call(GetIncidentsParams params) =>
      _repository.getIncidents(
        severity: params.severity,
        district: params.district,
        since: params.since,
        page: params.page,
        pageSize: params.pageSize,
      );
}

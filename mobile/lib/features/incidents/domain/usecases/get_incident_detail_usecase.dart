import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/failures.dart';
import '../entities/incident_entity.dart';
import '../repositories/incident_repository.dart';

@injectable
class GetIncidentDetailUseCase {
  const GetIncidentDetailUseCase(this._repository);
  final IncidentRepository _repository;

  Future<Either<Failure, IncidentDetailEntity>> call(String id) =>
      _repository.getIncidentDetail(id);
}

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/features/incidents/domain/repositories/incident_repository.dart';

class ConfirmIncidentParams {
  const ConfirmIncidentParams({required this.id, required this.vote});
  final String id;
  final String vote; // 'yes' | 'no'
}

@injectable
class ConfirmIncidentUseCase {
  const ConfirmIncidentUseCase(this._repository);
  final IncidentRepository _repository;

  Future<Either<Failure, Unit>> call(ConfirmIncidentParams params) =>
      _repository.confirmIncident(params.id, params.vote);
}

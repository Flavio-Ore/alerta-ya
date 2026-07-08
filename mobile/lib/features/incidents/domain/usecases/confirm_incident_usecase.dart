import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/features/incidents/domain/repositories/incident_repository.dart';

class ConfirmIncidentParams {
  const ConfirmIncidentParams({
    required this.id,
    required this.vote,
    required this.lat,
    required this.lng,
  });
  final String id;
  final String vote; // 'yes' | 'no'
  final double lat; // GPS del votante — gate de proximidad
  final double lng;
}

@injectable
class ConfirmIncidentUseCase {
  const ConfirmIncidentUseCase(this._repository);
  final IncidentRepository _repository;

  Future<Either<Failure, Unit>> call(ConfirmIncidentParams params) =>
      _repository.confirmIncident(params.id, params.vote, params.lat, params.lng);
}

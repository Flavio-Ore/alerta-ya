import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/features/incidents/domain/repositories/incident_repository.dart';

class ConfirmZoneParams {
  const ConfirmZoneParams({required this.zoneKey, required this.response});
  final String zoneKey;
  final String response; // 'yes' | 'no'
}

@injectable
class ConfirmZoneUseCase {
  const ConfirmZoneUseCase(this._repository);
  final IncidentRepository _repository;

  Future<Either<Failure, Unit>> call(ConfirmZoneParams params) =>
      _repository.confirmZone(params.zoneKey, params.response);
}

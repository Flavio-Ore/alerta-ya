import 'package:injectable/injectable.dart';
import 'package:alertaya/features/map/domain/repositories/incident_repository.dart';

@lazySingleton
class ConfirmIncidentUseCase {
  const ConfirmIncidentUseCase(this._repository);
  final IncidentRepository _repository;

  Future<void> call({
    required String incidentId,
    required bool stillHere,
  }) =>
      _repository.confirmIncident(
        incidentId: incidentId,
        stillHere: stillHere,
      );
}

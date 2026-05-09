import 'package:alertaya/features/map/domain/repositories/incident_repository.dart';

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

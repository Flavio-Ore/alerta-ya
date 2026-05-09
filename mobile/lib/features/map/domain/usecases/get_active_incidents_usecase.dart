import 'package:alertaya/features/map/domain/entities/incident_entity.dart';
import 'package:alertaya/features/map/domain/repositories/incident_repository.dart';

class GetActiveIncidentsUseCase {
  const GetActiveIncidentsUseCase(this._repository);
  final IncidentRepository _repository;

  Future<List<IncidentEntity>> call() => _repository.getActiveIncidents();
}

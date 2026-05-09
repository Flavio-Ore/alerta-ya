import 'package:alertaya/features/map/domain/entities/incident_entity.dart';

abstract class IncidentRepository {
  Future<List<IncidentEntity>> getActiveIncidents();
  Future<void> confirmIncident({
    required String incidentId,
    required bool stillHere,
  });
}

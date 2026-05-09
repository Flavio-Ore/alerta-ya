import 'package:injectable/injectable.dart';
import 'package:alertaya/features/map/data/datasources/mock_incident_datasource.dart';
import 'package:alertaya/features/map/domain/entities/incident_entity.dart';
import 'package:alertaya/features/map/domain/repositories/incident_repository.dart';

@LazySingleton(as: IncidentRepository)
class MockIncidentRepository implements IncidentRepository {
  MockIncidentRepository(this._datasource);
  final MockIncidentDatasource _datasource;

  @override
  Future<List<IncidentEntity>> getActiveIncidents() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _datasource.getActiveIncidents();
  }

  @override
  Future<void> confirmIncident({
    required String incidentId,
    required bool stillHere,
  }) async {
    // TODO(api): conectar a POST /incidents/:id/confirm en Sprint 3
    await Future.delayed(const Duration(milliseconds: 300));
  }
}

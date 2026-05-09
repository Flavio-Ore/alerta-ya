import 'package:injectable/injectable.dart';
import 'package:alertaya/features/map/domain/entities/incident_entity.dart';
import 'package:alertaya/features/report/domain/entities/incident_type.dart';

/// Mock datasource — reemplazar por DioClient en Sprint 3
@lazySingleton
class MockIncidentDatasource {
  List<IncidentEntity> getActiveIncidents() => [
        IncidentEntity(
          id: 'inc-001',
          type: IncidentType.robbery,
          severity: Severity.critical,
          status: IncidentStatus.active,
          lat: -12.1219,
          lng: -77.0282,
          district: 'Miraflores',
          confirmCount: 3,
          denyCount: 0,
          reportCount: 4,
          expiresAt: DateTime.now().add(const Duration(minutes: 26)),
          weaponReported: true,
          stillInArea: true,
        ),
        IncidentEntity(
          id: 'inc-002',
          type: IncidentType.robbery,
          severity: Severity.moderate,
          status: IncidentStatus.active,
          lat: -12.0830,
          lng: -77.0186,
          district: 'San Isidro',
          confirmCount: 1,
          denyCount: 0,
          reportCount: 2,
          expiresAt: DateTime.now().add(const Duration(minutes: 18)),
        ),
        IncidentEntity(
          id: 'inc-003',
          type: IncidentType.accident,
          severity: Severity.low,
          status: IncidentStatus.active,
          lat: -12.1464,
          lng: -77.0216,
          district: 'Barranco',
          confirmCount: 0,
          denyCount: 0,
          reportCount: 2,
          expiresAt: DateTime.now().add(const Duration(minutes: 14)),
        ),
        IncidentEntity(
          id: 'inc-004',
          type: IncidentType.robbery,
          severity: Severity.moderate,
          status: IncidentStatus.active,
          lat: -12.0700,
          lng: -77.0550,
          district: 'Jesús María',
          confirmCount: 2,
          denyCount: 0,
          reportCount: 3,
          expiresAt: DateTime.now().add(const Duration(minutes: 22)),
        ),
      ];
}

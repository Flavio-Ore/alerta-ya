import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:alertaya/core/domain/enums.dart';
import 'package:alertaya/features/my_reports/domain/entities/my_report_incident.dart';

part 'my_report_entity.freezed.dart';

/// Reporte propio del ciudadano autenticado. `incident == null` significa
/// que el reporte todavía está pendiente de confirmación (no se agregó
/// aún a ningún incidente publicado).
@freezed
class MyReportEntity with _$MyReportEntity {
  const factory MyReportEntity({
    required String reportId,
    required IncidentType type,
    required DateTime createdAt,
    required double lat,
    required double lng,
    required Map<String, dynamic> formData,
    required List<String> mediaUrls,
    MyReportIncident? incident,
  }) = _MyReportEntity;
}

@freezed
class MyReportsPage with _$MyReportsPage {
  const factory MyReportsPage({
    required List<MyReportEntity> items,
    required int page,
    required int pageSize,
    required int total,
  }) = _MyReportsPage;
}

/// Evento WebSocket entrante cuando la autoridad cambia el estado
/// de un incidente que contiene un reporte del usuario.
@freezed
class ReportStatusChangedEvent with _$ReportStatusChangedEvent {
  const factory ReportStatusChangedEvent({
    required String incidentId,
    required IncidentStatus status,
    required String district,
    required IncidentType type,
    required DateTime updatedAt,
    String? feedback,
  }) = _ReportStatusChangedEvent;
}

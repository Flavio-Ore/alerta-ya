import 'package:alertaya/features/incidents/data/models/incident_model.dart';
import 'package:alertaya/features/report/domain/entities/report_submit_result.dart';

/// Mapper de la respuesta del API → entidad de dominio.
///
/// Contrato del backend:
/// - `201` → `{ incident: PublicIncidentDTO, reputationDelta?: number }` (publicado)
/// - `200` → `{ incident: null, reputationDelta?: number }`              (recibido, no publicado todavía)
class ReportSubmitResultModel {
  static ReportSubmitResult fromResponse({
    required int statusCode,
    required Map<String, dynamic> body,
  }) {
    final rawDelta = body['reputationDelta'];
    final reputationDelta = rawDelta is int
        ? rawDelta
        : rawDelta is num
            ? rawDelta.toInt()
            : null;

    final rawIncident = body['incident'];
    if (statusCode == 201 && rawIncident is Map<String, dynamic>) {
      return ReportSubmitResult(
        isPublished: true,
        incident: IncidentModel.fromJson(rawIncident),
        reputationDelta: reputationDelta,
      );
    }
    return ReportSubmitResult(
      isPublished: false,
      reputationDelta: reputationDelta,
    );
  }
}

import 'package:alertaya/features/incidents/data/models/incident_model.dart';
import 'package:alertaya/features/report/domain/entities/report_submit_result.dart';

/// Mapper de la respuesta del API → entidad de dominio.
///
/// Contrato del backend:
/// - `201` → `{ incident: PublicIncidentDTO }` (publicado)
/// - `200` → `{ incident: null }`              (recibido, no publicado todavía)
class ReportSubmitResultModel {
  static ReportSubmitResult fromResponse({
    required int statusCode,
    required Map<String, dynamic> body,
  }) {
    final rawIncident = body['incident'];
    if (statusCode == 201 && rawIncident is Map<String, dynamic>) {
      return ReportSubmitResult(
        isPublished: true,
        incident: IncidentModel.fromJson(rawIncident),
      );
    }
    return const ReportSubmitResult(isPublished: false);
  }
}

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:alertaya/features/incidents/domain/entities/incident_entity.dart';

part 'report_submit_result.freezed.dart';

/// Resultado del envío de un reporte ciudadano al backend.
///
/// - `isPublished = true` → el reporte pasó el threshold y el incidente quedó
///   público (`incident` no nulo).
/// - `isPublished = false` → el reporte fue recibido pero todavía no se
///   publica; espera confirmación de otro ciudadano (`incident` nulo).
@freezed
class ReportSubmitResult with _$ReportSubmitResult {
  const factory ReportSubmitResult({
    required bool isPublished,
    IncidentEntity? incident,
    /// Puntos de reputación ganados/perdidos por este reporte (null si ML no corrió).
    int? reputationDelta,
  }) = _ReportSubmitResult;
}

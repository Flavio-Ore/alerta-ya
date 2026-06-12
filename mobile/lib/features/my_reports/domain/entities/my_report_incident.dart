import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:alertaya/core/domain/enums.dart';

part 'my_report_incident.freezed.dart';

/// Sub-objeto incident del DTO MyReport — refleja el estado actual
/// del incidente al que el reporte fue agregado (puede ser null si aún
/// no alcanzó el threshold de publicación).
@freezed
class MyReportIncident with _$MyReportIncident {
  const factory MyReportIncident({
    required String id,
    required IncidentStatus status,
    required Severity severity,
    required String district,
    required int confirmCount,
    required int denyCount,
    required int reportCount,
    required DateTime expiresAt,
    required DateTime updatedAt,
    String? feedback,
  }) = _MyReportIncident;
}

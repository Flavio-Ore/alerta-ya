import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:alertaya/core/domain/enums.dart';

part 'incident_entity.freezed.dart';

@freezed
class IncidentEntity with _$IncidentEntity {
  const factory IncidentEntity({
    required String id,
    required IncidentType type,
    required Severity severity,
    required IncidentStatus status,
    required double lat,
    required double lng,
    required String district,
    required int confirmCount,
    required int denyCount,
    required int reportCount,
    required DateTime expiresAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? unitAssigned,
    String? feedback,
  }) = _IncidentEntity;
}

@freezed
class IncidentDetailEntity with _$IncidentDetailEntity {
  const factory IncidentDetailEntity({
    required String id,
    required IncidentType type,
    required Severity severity,
    required IncidentStatus status,
    required double lat,
    required double lng,
    required String district,
    required int confirmCount,
    required int denyCount,
    required int reportCount,
    required DateTime expiresAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? unitAssigned,
    String? feedback,
    @Default(0) int weaponReports,
    @Default(0) int injuredReports,
    @Default(0) int stillHereReports,
  }) = _IncidentDetailEntity;
}

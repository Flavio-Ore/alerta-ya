import 'package:alertaya/core/domain/enums.dart';
import 'package:alertaya/features/incidents/domain/entities/incident_entity.dart';

class IncidentModel {
  static IncidentEntity fromJson(Map<String, dynamic> json) => IncidentEntity(
        id: json['id'] as String,
        type: IncidentType.fromValue(json['type'] as String),
        severity: Severity.fromValue(json['severity'] as String),
        status: IncidentStatus.fromValue(json['status'] as String),
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        district: json['district'] as String,
        confirmCount: json['confirmCount'] as int,
        denyCount: json['denyCount'] as int,
        reportCount: json['reportCount'] as int,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        unitAssigned: json['unitAssigned'] as String?,
        feedback: json['feedback'] as String?,
        aiScore: (json['aiScore'] as num?)?.toDouble(),
        aiVerified: json['aiVerified'] as bool?,
      );
}

class IncidentDetailModel {
  static IncidentDetailEntity fromJson(Map<String, dynamic> json) =>
      IncidentDetailEntity(
        id: json['id'] as String,
        type: IncidentType.fromValue(json['type'] as String),
        severity: Severity.fromValue(json['severity'] as String),
        status: IncidentStatus.fromValue(json['status'] as String),
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        district: json['district'] as String,
        confirmCount: json['confirmCount'] as int,
        denyCount: json['denyCount'] as int,
        reportCount: json['reportCount'] as int,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        unitAssigned: json['unitAssigned'] as String?,
        feedback: json['feedback'] as String?,
        aiScore: (json['aiScore'] as num?)?.toDouble(),
        aiVerified: json['aiVerified'] as bool?,
        weaponReports: (json['weaponReports'] as int?) ?? 0,
        injuredReports: (json['injuredReports'] as int?) ?? 0,
        stillHereReports: (json['stillHereReports'] as int?) ?? 0,
        reporterTrust: json['reporterTrust'] as String?,
      );
}

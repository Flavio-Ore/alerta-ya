import 'package:alertaya/core/domain/enums.dart';
import 'package:alertaya/features/my_reports/domain/entities/my_report_entity.dart';
import 'package:alertaya/features/my_reports/domain/entities/my_report_incident.dart';

class MyReportIncidentModel {
  static MyReportIncident fromJson(Map<String, dynamic> json) =>
      MyReportIncident(
        id: json['id'] as String,
        status: IncidentStatus.fromValue(json['status'] as String),
        severity: Severity.fromValue(json['severity'] as String),
        district: json['district'] as String,
        confirmCount: json['confirmCount'] as int,
        denyCount: json['denyCount'] as int,
        reportCount: json['reportCount'] as int,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        feedback: json['feedback'] as String?,
        // null-safe: PR1c agrega estos campos al backend por separado;
        // hasta entonces deben tolerarse ausentes.
        aiScore: (json['aiScore'] as num?)?.toDouble(),
        aiVerified: json['aiVerified'] as bool?,
      );
}

class MyReportModel {
  static MyReportEntity fromJson(Map<String, dynamic> json) {
    final rawIncident = json['incident'];
    return MyReportEntity(
      reportId: json['reportId'] as String,
      type: IncidentType.fromValue(json['type'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      formData: Map<String, dynamic>.from(
        (json['formData'] as Map?) ?? const <String, dynamic>{},
      ),
      mediaUrls: ((json['mediaUrls'] as List?) ?? const [])
          .map((e) => e as String)
          .toList(),
      incident: rawIncident == null
          ? null
          : MyReportIncidentModel.fromJson(
              Map<String, dynamic>.from(rawIncident as Map),
            ),
    );
  }
}

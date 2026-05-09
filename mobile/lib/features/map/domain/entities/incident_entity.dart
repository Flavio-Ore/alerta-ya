import 'package:alertaya/features/report/domain/entities/incident_type.dart';

enum Severity { low, moderate, critical }

enum IncidentStatus { active, inAttention, closed }

class IncidentEntity {
  const IncidentEntity({
    required this.id,
    required this.type,
    required this.severity,
    required this.status,
    required this.lat,
    required this.lng,
    required this.district,
    required this.confirmCount,
    required this.denyCount,
    required this.reportCount,
    required this.expiresAt,
    this.weaponReported = false,
    this.stillInArea = false,
  });

  final String id;
  final IncidentType type;
  final Severity severity;
  final IncidentStatus status;
  final double lat;
  final double lng;
  final String district;
  final int confirmCount;
  final int denyCount;
  final int reportCount;
  final DateTime expiresAt;
  // formSummary agregado — nunca identidad individual
  final bool weaponReported;
  final bool stillInArea;

  String get severityLabel => switch (severity) {
        Severity.low => 'LEVE',
        Severity.moderate => 'MODERADO',
        Severity.critical => 'CRÍTICO',
      };

  String get timeAgo {
    final diff = DateTime.now().difference(
      expiresAt.subtract(const Duration(minutes: 30)),
    );
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    return 'Hace ${diff.inHours}h';
  }
}

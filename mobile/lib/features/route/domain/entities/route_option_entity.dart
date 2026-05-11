import 'package:latlong2/latlong.dart';

import 'package:alertaya/features/incidents/domain/entities/incident_entity.dart';

class RouteOptionEntity {
  const RouteOptionEntity({
    required this.label,
    required this.polyline,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.riskScore,
    required this.nearbyIncidents,
  });

  final String label; // 'A', 'B', ...
  final List<LatLng> polyline;
  final int durationSeconds;
  final double distanceMeters;
  final int riskScore; // 0–100
  final List<IncidentEntity> nearbyIncidents;

  String get durationLabel {
    final mins = (durationSeconds / 60).round();
    return '$mins min';
  }

  String get distanceLabel {
    final km = distanceMeters / 1000;
    return '${km.toStringAsFixed(1)} km';
  }

  String get riskLabel => switch (riskScore) {
        <= 30 => 'BAJO',
        <= 60 => 'MODERADO',
        _ => 'CRÍTICO',
      };
}

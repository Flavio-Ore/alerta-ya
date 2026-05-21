import 'incident_type.dart';

class ReportEntity {
  const ReportEntity({
    required this.type,
    required this.lat,
    required this.lng,
    required this.formData,
  });
  final IncidentType type;
  final double lat;
  final double lng;
  final Map<String, String> formData;
}

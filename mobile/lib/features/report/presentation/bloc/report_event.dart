part of 'report_bloc.dart';

sealed class ReportEvent {
  const ReportEvent();
}

class ReportStarted extends ReportEvent {
  const ReportStarted();
}

class ReportSubmitted extends ReportEvent {
  const ReportSubmitted({
    required this.type,
    required this.lat,
    required this.lng,
    required this.formData,
    this.mediaPaths,
  });
  final IncidentType type;
  final double lat;
  final double lng;
  final Map<String, String> formData;
  final List<String>? mediaPaths;
}

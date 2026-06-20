part of 'report_bloc.dart';

sealed class ReportState {
  const ReportState();
}

class ReportInitial extends ReportState {
  const ReportInitial();
}

class ReportSubmitting extends ReportState {
  const ReportSubmitting();
}

class ReportSuccess extends ReportState {
  const ReportSuccess({
    required this.isPublished,
    this.incident,
    this.reputationDelta,
  });
  final bool isPublished;
  final IncidentEntity? incident;
  /// Puntos de reputación ganados/perdidos. Null si ML no corrió o falló.
  final int? reputationDelta;
}

class ReportFailure extends ReportState {
  const ReportFailure(this.message);
  final String message;
}

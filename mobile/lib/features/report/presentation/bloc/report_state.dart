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
  const ReportSuccess({required this.isPublished, this.incident});
  final bool isPublished;
  final IncidentEntity? incident;
}

class ReportFailure extends ReportState {
  const ReportFailure(this.message);
  final String message;
}

part of 'my_reports_bloc.dart';

abstract class MyReportsEvent {
  const MyReportsEvent();
}

class MyReportsLoaded extends MyReportsEvent {
  const MyReportsLoaded({this.page = 1});
  final int page;
}

class MyReportsRefreshed extends MyReportsEvent {
  const MyReportsRefreshed();
}

class MyReportsStatusChanged extends MyReportsEvent {
  const MyReportsStatusChanged(this.event);
  final ReportStatusChangedEvent event;
}

class MyReportCancelRequested extends MyReportsEvent {
  const MyReportCancelRequested(this.reportId);
  final String reportId;
}

part of 'my_reports_bloc.dart';

abstract class MyReportsState {
  const MyReportsState();
}

class MyReportsInitial extends MyReportsState {
  const MyReportsInitial();
}

class MyReportsLoading extends MyReportsState {
  const MyReportsLoading();
}

class MyReportsData extends MyReportsState {
  const MyReportsData({required this.items, required this.hasMore});
  final List<MyReportEntity> items;
  final bool hasMore;
}

class MyReportsError extends MyReportsState {
  const MyReportsError(this.message);
  final String message;
}

/// Error puntual al cancelar — la lista vuelve al estado anterior.
/// La UI lo consume como SnackBar y vuelve a MyReportsData.
class MyReportsCancelError extends MyReportsState {
  const MyReportsCancelError(this.message);
  final String message;
}

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/features/my_reports/domain/entities/my_report_entity.dart';
import 'package:alertaya/features/my_reports/domain/usecases/cancel_report_usecase.dart';
import 'package:alertaya/features/my_reports/domain/usecases/get_my_reports_usecase.dart';
import 'package:alertaya/features/my_reports/domain/usecases/watch_my_reports_usecase.dart';

part 'my_reports_event.dart';
part 'my_reports_state.dart';

@injectable
class MyReportsBloc extends Bloc<MyReportsEvent, MyReportsState> {
  MyReportsBloc(this._getMyReports, this._watch, this._cancelReport)
      : super(const MyReportsInitial()) {
    on<MyReportsLoaded>(_onLoaded);
    on<MyReportsRefreshed>(_onRefreshed);
    on<MyReportsStatusChanged>(_onStatusChanged);
    on<MyReportCancelRequested>(_onCancelRequested);

    _statusSub = _watch().listen((e) => add(MyReportsStatusChanged(e)));
  }

  final GetMyReportsUseCase _getMyReports;
  final WatchMyReportsUseCase _watch;
  final CancelReportUseCase _cancelReport;

  late final StreamSubscription<ReportStatusChangedEvent> _statusSub;

  Future<void> _onLoaded(
    MyReportsLoaded event,
    Emitter<MyReportsState> emit,
  ) async {
    emit(const MyReportsLoading());
    await _fetch(emit, page: event.page);
  }

  Future<void> _onRefreshed(
    MyReportsRefreshed event,
    Emitter<MyReportsState> emit,
  ) =>
      _fetch(emit, page: 1);

  Future<void> _fetch(Emitter<MyReportsState> emit, {required int page}) async {
    final result = await _getMyReports(GetMyReportsParams(page: page));
    result.fold(
      (f) => emit(MyReportsError(f.toString())),
      (data) {
        final hasMore = data.page * data.pageSize < data.total;
        emit(MyReportsData(items: data.items, hasMore: hasMore));
      },
    );
  }

  Future<void> _onCancelRequested(
    MyReportCancelRequested event,
    Emitter<MyReportsState> emit,
  ) async {
    if (state is! MyReportsData) return;
    final current = state as MyReportsData;

    // Optimistic: quitar de la lista antes de esperar la respuesta de red
    final optimistic =
        current.items.where((r) => r.reportId != event.reportId).toList();
    emit(MyReportsData(items: optimistic, hasMore: current.hasMore));

    final result = await _cancelReport(event.reportId);
    result.fold(
      (f) {
        // Rollback si falla
        emit(MyReportsData(items: current.items, hasMore: current.hasMore));
        emit(MyReportsCancelError(f.toString()));
      },
      (_) {/* optimistic ya aplicado */},
    );
  }

  void _onStatusChanged(
    MyReportsStatusChanged event,
    Emitter<MyReportsState> emit,
  ) {
    if (state is! MyReportsData) return;
    final current = state as MyReportsData;

    final updated = current.items.map((report) {
      final incident = report.incident;
      if (incident == null || incident.id != event.event.incidentId) {
        return report;
      }
      return report.copyWith(
        incident: incident.copyWith(
          status: event.event.status,
          feedback: event.event.feedback ?? incident.feedback,
          updatedAt: event.event.updatedAt,
        ),
      );
    }).toList();

    emit(MyReportsData(items: updated, hasMore: current.hasMore));
  }

  @override
  Future<void> close() {
    _statusSub.cancel();
    return super.close();
  }
}

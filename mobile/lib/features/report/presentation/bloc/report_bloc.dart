import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/features/report/domain/entities/incident_type.dart';
import 'package:alertaya/features/report/domain/entities/report_entity.dart';
import 'package:alertaya/features/report/domain/usecases/create_report_usecase.dart';

part 'report_event.dart';
part 'report_state.dart';

@lazySingleton
class ReportBloc extends Bloc<ReportEvent, ReportState> {
  ReportBloc(this._createReport) : super(const ReportInitial()) {
    on<ReportStarted>(_onStarted);
    on<ReportSubmitted>(_onSubmitted);
  }

  final CreateReportUseCase _createReport;

  void _onStarted(ReportStarted event, Emitter<ReportState> emit) {
    emit(const ReportInitial());
  }

  Future<void> _onSubmitted(
    ReportSubmitted event,
    Emitter<ReportState> emit,
  ) async {
    emit(const ReportSubmitting());

    final result = await _createReport(ReportEntity(
      type: event.type,
      lat: event.lat,
      lng: event.lng,
      formData: event.formData,
    ));

    result.fold(
      (failure) => emit(ReportFailure(failure.toString())),
      (_) => emit(const ReportSuccess()),
    );
  }
}

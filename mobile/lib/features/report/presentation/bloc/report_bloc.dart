import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/features/incidents/domain/entities/incident_entity.dart';
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
      mediaPaths: event.mediaPaths,
      notes: event.notes,
    ));

    result.fold(
      (failure) => emit(ReportFailure(_messageFor(failure))),
      (submitResult) => emit(ReportSuccess(
        isPublished: submitResult.isPublished,
        incident: submitResult.incident,
      )),
    );
  }

  String _messageFor(Failure failure) => failure.when(
        network: (msg) =>
            msg ?? 'Sin conexión. Verifica tu internet e intenta de nuevo.',
        server: (statusCode, msg) =>
            msg ?? 'Error del servidor ($statusCode). Intenta más tarde.',
        rateLimit: (msg) =>
            msg ?? 'Llegaste al límite de 3 reportes por hora.',
        unauthorized: () =>
            'Tu sesión expiró. Vuelve a iniciar sesión para reportar.',
        forbidden: () => 'No tenés permisos para realizar esta acción.',
        notFound: () => 'Recurso no encontrado.',
        validation: (msg) => msg,
        unknown: (msg) =>
            msg ?? 'Ocurrió un error inesperado. Intenta de nuevo.',
      );
}

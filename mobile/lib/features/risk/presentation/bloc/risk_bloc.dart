import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/features/risk/domain/entities/risk_info.dart';
import 'package:alertaya/features/risk/domain/entities/risk_prediction.dart';
import 'package:alertaya/features/risk/domain/repositories/risk_repository.dart';

part 'risk_event.dart';
part 'risk_state.dart';

@lazySingleton
class RiskBloc extends Bloc<RiskEvent, RiskState> {
  RiskBloc(this._riskRepository) : super(const RiskInitial()) {
    on<RiskRequested>(_onRequested);
  }

  final RiskRepository _riskRepository;

  Future<void> _onRequested(
      RiskRequested event, Emitter<RiskState> emit) async {
    emit(const RiskLoading());
    try {
      final info = await _riskRepository.getRisk(
        lat: event.lat,
        lng: event.lng,
        hour: event.hour,
      );
      emit(RiskLoaded(info));

      // Predicción ML complementaria para HOY y MAÑANA (el modelo distingue día
      // de semana; el motor determinístico no). Fail-open dentro del repo: si el
      // ML no responde, devuelve una predicción no disponible, nunca lanza.
      // Dart weekday: 1=lunes..7=domingo → contrato del modelo 0=lunes..6=domingo.
      final todayDow = (DateTime.now().weekday - 1) % 7;
      final tomorrowDow = (todayDow + 1) % 7;
      final results = await Future.wait<RiskPrediction>([
        _riskRepository.getPrediction(
            lat: event.lat, lng: event.lng, hour: event.hour, dayOfWeek: todayDow),
        _riskRepository.getPrediction(
            lat: event.lat, lng: event.lng, hour: event.hour, dayOfWeek: tomorrowDow),
      ]);

      // El usuario pudo haber lanzado otra búsqueda mientras tanto: solo emitir
      // si seguimos mostrando el mismo resultado.
      if (state is RiskLoaded && (state as RiskLoaded).info == info) {
        emit(RiskLoaded(info,
            todayPrediction: results[0], tomorrowPrediction: results[1]));
      }
    } catch (e) {
      emit(RiskFailure(e.toString()));
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/features/risk/domain/entities/risk_info.dart';
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
    } catch (e) {
      emit(RiskFailure(e.toString()));
    }
  }
}

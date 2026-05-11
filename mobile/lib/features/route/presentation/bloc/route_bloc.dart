import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

import 'package:alertaya/features/incidents/domain/entities/incident_entity.dart';
import 'package:alertaya/features/route/domain/entities/route_option_entity.dart';
import 'package:alertaya/features/route/domain/usecases/compare_routes_usecase.dart';

part 'route_event.dart';
part 'route_state.dart';

class RouteBloc extends Bloc<RouteEvent, RouteState> {
  RouteBloc(this._compareRoutes) : super(const RouteInitial()) {
    on<RouteRequested>(_onRequested);
    on<RouteOptionSelected>(_onSelected);
    on<RouteReset>(_onReset);
  }

  final CompareRoutesUseCase _compareRoutes;

  Future<void> _onRequested(
      RouteRequested event, Emitter<RouteState> emit) async {
    emit(const RouteLoading());
    try {
      final locations = await locationFromAddress(event.destinationQuery);
      if (locations.isEmpty) {
        emit(const RouteFailure('No se encontró la dirección ingresada.'));
        return;
      }
      final dest = LatLng(
        locations.first.latitude,
        locations.first.longitude,
      );
      final result = await _compareRoutes(CompareRoutesParams(
        origin: event.origin,
        destination: dest,
        incidents: event.incidents,
      ));
      result.fold(
        (f) => emit(RouteFailure(f.toString())),
        (options) {
          if (options.isEmpty) {
            emit(const RouteFailure('No se encontraron rutas disponibles.'));
            return;
          }
          // La más segura primero
          final sorted = [...options]
            ..sort((a, b) => a.riskScore.compareTo(b.riskScore));
          emit(RouteLoaded(
            options: sorted,
            selectedIndex: 0,
            destination: dest,
          ));
        },
      );
    } catch (e) {
      emit(RouteFailure(e.toString()));
    }
  }

  void _onSelected(RouteOptionSelected event, Emitter<RouteState> emit) {
    if (state is RouteLoaded) {
      emit((state as RouteLoaded).copyWith(selectedIndex: event.index));
    }
  }

  void _onReset(RouteReset event, Emitter<RouteState> emit) =>
      emit(const RouteInitial());
}

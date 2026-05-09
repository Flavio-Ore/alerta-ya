import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alertaya/features/map/domain/entities/incident_entity.dart';
import 'package:alertaya/features/map/domain/usecases/get_active_incidents_usecase.dart';
import 'package:alertaya/features/map/domain/usecases/confirm_incident_usecase.dart';

part 'map_event.dart';
part 'map_state.dart';

@injectable
class MapBloc extends Bloc<MapEvent, MapState> {
  MapBloc(this._getActiveIncidents, this._confirmIncident)
      : super(const MapInitial()) {
    on<MapLoadRequested>(_onLoadRequested);
    on<MapIncidentSelected>(_onIncidentSelected);
    on<MapIncidentDeselected>(_onIncidentDeselected);
    on<MapIncidentConfirmed>(_onIncidentConfirmed);
  }

  final GetActiveIncidentsUseCase _getActiveIncidents;
  final ConfirmIncidentUseCase _confirmIncident;

  Future<void> _onLoadRequested(
    MapLoadRequested event,
    Emitter<MapState> emit,
  ) async {
    emit(const MapLoading());
    try {
      final incidents = await _getActiveIncidents();
      // Severidad de zona = la más alta del conjunto visible
      final zoneSeverity = _computeZoneSeverity(incidents);
      emit(MapLoaded(incidents: incidents, zoneSeverity: zoneSeverity));
    } catch (_) {
      emit(const MapError('No se pudo cargar el mapa. Verificá tu conexión.'));
    }
  }

  void _onIncidentSelected(
    MapIncidentSelected event,
    Emitter<MapState> emit,
  ) {
    if (state case MapLoaded loaded) {
      emit(loaded.copyWith(selectedIncident: event.incident));
    }
  }

  void _onIncidentDeselected(
    MapIncidentDeselected event,
    Emitter<MapState> emit,
  ) {
    if (state case MapLoaded loaded) {
      emit(loaded.copyWith(clearSelected: true));
    }
  }

  Future<void> _onIncidentConfirmed(
    MapIncidentConfirmed event,
    Emitter<MapState> emit,
  ) async {
    if (state case MapLoaded loaded) {
      await _confirmIncident(
        incidentId: event.incidentId,
        stillHere: event.stillHere,
      );
      // Recargar incidentes tras confirmar
      final incidents = await _getActiveIncidents();
      emit(loaded.copyWith(
        incidents: incidents,
        clearSelected: true,
      ));
    }
  }

  Severity? _computeZoneSeverity(List<IncidentEntity> incidents) {
    if (incidents.isEmpty) return null;
    if (incidents.any((i) => i.severity == Severity.critical)) {
      return Severity.critical;
    }
    if (incidents.any((i) => i.severity == Severity.moderate)) {
      return Severity.moderate;
    }
    return Severity.low;
  }
}

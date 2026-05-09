part of 'map_bloc.dart';

sealed class MapState {
  const MapState();
}

class MapInitial extends MapState {
  const MapInitial();
}

class MapLoading extends MapState {
  const MapLoading();
}

class MapLoaded extends MapState {
  const MapLoaded({
    required this.incidents,
    this.selectedIncident,
    this.zoneSeverity,
  });
  final List<IncidentEntity> incidents;
  final IncidentEntity? selectedIncident;
  final Severity? zoneSeverity;

  MapLoaded copyWith({
    List<IncidentEntity>? incidents,
    IncidentEntity? selectedIncident,
    bool clearSelected = false,
    Severity? zoneSeverity,
  }) =>
      MapLoaded(
        incidents: incidents ?? this.incidents,
        selectedIncident:
            clearSelected ? null : selectedIncident ?? this.selectedIncident,
        zoneSeverity: zoneSeverity ?? this.zoneSeverity,
      );
}

class MapError extends MapState {
  const MapError(this.message);
  final String message;
}

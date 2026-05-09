part of 'map_bloc.dart';

sealed class MapEvent {
  const MapEvent();
}

class MapLoadRequested extends MapEvent {
  const MapLoadRequested();
}

class MapIncidentSelected extends MapEvent {
  const MapIncidentSelected(this.incident);
  final IncidentEntity incident;
}

class MapIncidentDeselected extends MapEvent {
  const MapIncidentDeselected();
}

class MapIncidentConfirmed extends MapEvent {
  const MapIncidentConfirmed({
    required this.incidentId,
    required this.stillHere,
  });
  final String incidentId;
  final bool stillHere;
}

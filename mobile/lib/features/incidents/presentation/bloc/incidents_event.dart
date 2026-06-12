part of 'incidents_bloc.dart';

abstract class IncidentsEvent {
  const IncidentsEvent();
}

class IncidentsStarted extends IncidentsEvent {
  const IncidentsStarted();
}

class IncidentNewReceived extends IncidentsEvent {
  const IncidentNewReceived(this.incident);
  final IncidentEntity incident;
}

class IncidentUpdatedReceived extends IncidentsEvent {
  const IncidentUpdatedReceived(this.incident);
  final IncidentEntity incident;
}

class IncidentDetailRequested extends IncidentsEvent {
  const IncidentDetailRequested(this.id);
  final String id;
}

class IncidentConfirmSubmitted extends IncidentsEvent {
  const IncidentConfirmSubmitted({required this.id, required this.stillHere});
  final String id;
  final bool stillHere;
}

class ZoneConfirmSubmitted extends IncidentsEvent {
  const ZoneConfirmSubmitted({required this.zoneKey, required this.response});
  final String zoneKey;
  final String response; // 'yes' | 'no'
}

class ConfirmRequestReceived extends IncidentsEvent {
  const ConfirmRequestReceived(this.event);
  final ConfirmRequestEvent event;
}

class ConfirmRequestDismissed extends IncidentsEvent {
  const ConfirmRequestDismissed();
}

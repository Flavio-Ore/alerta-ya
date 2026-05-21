part of 'route_bloc.dart';

abstract class RouteEvent {
  const RouteEvent();
}

class RouteRequested extends RouteEvent {
  const RouteRequested({
    required this.origin,
    required this.destinationQuery,
    required this.incidents,
  });

  final LatLng origin;
  final String destinationQuery;
  final List<IncidentEntity> incidents;
}

class RouteOptionSelected extends RouteEvent {
  const RouteOptionSelected(this.index);
  final int index;
}

class RouteReset extends RouteEvent {
  const RouteReset();
}

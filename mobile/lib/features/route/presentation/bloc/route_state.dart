part of 'route_bloc.dart';

abstract class RouteState {
  const RouteState();
}

class RouteInitial extends RouteState {
  const RouteInitial();
}

class RouteLoading extends RouteState {
  const RouteLoading();
}

class RouteLoaded extends RouteState {
  const RouteLoaded({
    required this.options,
    required this.selectedIndex,
    required this.destination,
  });

  final List<RouteOptionEntity> options;
  final int selectedIndex;
  final LatLng destination;

  RouteOptionEntity get selectedOption => options[selectedIndex];

  RouteLoaded copyWith({int? selectedIndex}) => RouteLoaded(
        options: options,
        selectedIndex: selectedIndex ?? this.selectedIndex,
        destination: destination,
      );
}

class RouteFailure extends RouteState {
  const RouteFailure(this.message);
  final String message;
}

part of 'risk_bloc.dart';

abstract class RiskEvent {
  const RiskEvent();
}

class RiskRequested extends RiskEvent {
  const RiskRequested({required this.lat, required this.lng, this.hour});

  final double lat;
  final double lng;
  final int? hour;
}

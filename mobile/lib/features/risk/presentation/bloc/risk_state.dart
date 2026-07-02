part of 'risk_bloc.dart';

abstract class RiskState {
  const RiskState();
}

class RiskInitial extends RiskState {
  const RiskInitial();
}

class RiskLoading extends RiskState {
  const RiskLoading();
}

class RiskLoaded extends RiskState {
  const RiskLoaded(this.info);
  final RiskInfo info;
}

class RiskFailure extends RiskState {
  const RiskFailure(this.message);
  final String message;
}

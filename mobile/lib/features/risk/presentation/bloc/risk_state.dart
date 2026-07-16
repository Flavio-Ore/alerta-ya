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
  const RiskLoaded(this.info, {this.todayPrediction, this.tomorrowPrediction});

  final RiskInfo info;

  /// Predicción ML para hoy y mañana. null mientras no se resolvieron; una
  /// predicción con available=false si el ML service no respondió.
  final RiskPrediction? todayPrediction;
  final RiskPrediction? tomorrowPrediction;

  RiskLoaded copyWith({
    RiskPrediction? todayPrediction,
    RiskPrediction? tomorrowPrediction,
  }) =>
      RiskLoaded(
        info,
        todayPrediction: todayPrediction ?? this.todayPrediction,
        tomorrowPrediction: tomorrowPrediction ?? this.tomorrowPrediction,
      );
}

class RiskFailure extends RiskState {
  const RiskFailure(this.message);
  final String message;
}

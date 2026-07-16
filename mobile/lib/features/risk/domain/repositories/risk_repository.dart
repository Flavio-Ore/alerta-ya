import 'package:alertaya/features/risk/domain/entities/risk_info.dart';
import 'package:alertaya/features/risk/domain/entities/risk_prediction.dart';

abstract class RiskRepository {
  Future<RiskInfo> getRisk({
    required double lat,
    required double lng,
    int? hour,
  });

  /// Predicción del modelo ML para una hora y día de semana concretos.
  /// [dayOfWeek]: 0=lunes ... 6=domingo. null → día actual del servidor.
  Future<RiskPrediction> getPrediction({
    required double lat,
    required double lng,
    int? hour,
    int? dayOfWeek,
  });
}

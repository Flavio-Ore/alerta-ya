/// Predicción del modelo ML (XGBoost Poisson) para una ubicación, hora y día.
///
/// Reflejo del contrato `GET /risk/predict` del API. A diferencia de [RiskInfo]
/// (motor determinístico), esta predicción distingue el día de semana.
///
/// Fail-open: cuando el ML service no responde o el modelo está degradado, el
/// API devuelve `available: false` y [available] es false — la UI muestra
/// "predicción no disponible" sin romper.
class RiskPrediction {
  const RiskPrediction({
    required this.available,
    required this.hour,
    required this.dayOfWeek,
    this.riskScore,
    this.expectedCount,
    this.confidence,
  });

  factory RiskPrediction.fromJson(Map<String, dynamic> json) => RiskPrediction(
        available: json['available'] as bool? ?? false,
        hour: json['hour'] as int? ?? 0,
        dayOfWeek: json['dayOfWeek'] as int? ?? 0,
        riskScore: (json['riskScore'] as num?)?.toInt(),
        expectedCount: (json['expectedCount'] as num?)?.toDouble(),
        confidence: (json['confidence'] as num?)?.toDouble(),
      );

  /// Predicción no disponible (ML caído/degradado). Usar para el estado vacío.
  factory RiskPrediction.unavailable({required int hour, required int dayOfWeek}) =>
      RiskPrediction(available: false, hour: hour, dayOfWeek: dayOfWeek);

  final bool available;
  final int hour;
  final int dayOfWeek; // 0=lunes ... 6=domingo
  final int? riskScore;
  final double? expectedCount;
  final double? confidence;
}
